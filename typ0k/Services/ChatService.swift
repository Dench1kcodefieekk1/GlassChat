import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

struct RemoteChat: Identifiable, Hashable {
    let id: String
    let participants: [String]
    let lastMessage: String
    let lastMessageTimestamp: Date?
    let unreadCount: [String: Int]

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let participants = data["participants"] as? [String] else { return nil }
        id = document.documentID
        self.participants = participants
        lastMessage = (data["lastMessage"] as? String) ?? ""
        lastMessageTimestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue()
        unreadCount = (data["unreadCount"] as? [String: Int]) ?? [:]
    }
}

struct RemoteMessage: Identifiable, Hashable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date?
    let status: String

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let senderId = data["senderId"] as? String else { return nil }
        id = document.documentID
        self.senderId = senderId
        text = (data["text"] as? String) ?? ""
        timestamp = (data["timestamp"] as? Timestamp)?.dateValue()
        status = (data["status"] as? String) ?? "sent"
    }
}

/// Real-time 1-on-1 messaging engine on Firestore.
///
/// Schema (validated by `firestore.rules`):
/// - `chats/{chatId}` — `participants: [String]`, `lastMessage`,
///   `lastMessageTimestamp`, `unreadCount: [String: Int]`
/// - `chats/{chatId}/messages/{messageId}` — `senderId`, `text`,
///   `timestamp`, `status` (`sent` | `delivered` | `read`)
///
/// Direct chats use a deterministic document ID (`min(uid1,uid2)_max(uid1,uid2)`)
/// so both participants resolve the same chat without a lookup. Sends are
/// committed in a single batch that writes the message and updates the parent
/// chat document atomically. Snapshot listeners keep the chat list and the
/// active conversation live; all listener callbacks are marshalled onto the
/// main actor asynchronously so Firestore callbacks never block the UI.
@MainActor
@Observable
final class ChatService {
    static let shared = ChatService()

    private let db = Firestore.firestore()
    private var chatListListener: ListenerRegistration?
    private var messageListener: ListenerRegistration?
    private var listeningUID: String?

    private(set) var remoteChats: [RemoteChat] = []
    private(set) var remoteMessages: [RemoteMessage] = []
    private(set) var activeChatID: String?

    private init() {}

    private var currentUID: String? { Auth.auth().currentUser?.uid }

    var isFirebaseReady: Bool { FirebaseApp.app() != nil }

    // MARK: - Deterministic direct chat ID

    /// `min(uid1, uid2)_max(uid1, uid2)` — both sides compute the same ID.
    static func directChatID(between uid1: String, and uid2: String) -> String {
        let ordered = [uid1, uid2].sorted()
        return "\(ordered[0])_\(ordered[1])"
    }

    // MARK: - Chat list listener

    /// Subscribes to every chat the signed-in user participates in.
    func startChatListListener() {
        guard isFirebaseReady, let uid = currentUID else { return }
        guard listeningUID != uid else { return }
        stopChatListListener()
        listeningUID = uid
        chatListListener = db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[ChatService] Chat list listener error: \(error.localizedDescription)")
                    return
                }
                let chats = (snapshot?.documents ?? []).compactMap(RemoteChat.init(document:))
                    .sorted {
                        ($0.lastMessageTimestamp ?? .distantPast) > ($1.lastMessageTimestamp ?? .distantPast)
                    }
                Task { @MainActor [weak self] in
                    self?.remoteChats = chats
                }
            }
    }

    func stopChatListListener() {
        chatListListener?.remove()
        chatListListener = nil
        listeningUID = nil
    }

    // MARK: - Active chat listener

    /// Subscribes to the message subcollection of the open chat.
    func observeMessages(in chatID: String) {
        guard isFirebaseReady else { return }
        guard activeChatID != chatID else { return }
        stopMessageListener()
        activeChatID = chatID
        remoteMessages = []
        messageListener = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[ChatService] Message listener error: \(error.localizedDescription)")
                    return
                }
                let messages = (snapshot?.documents ?? []).compactMap(RemoteMessage.init(document:))
                Task { @MainActor [weak self] in
                    self?.remoteMessages = messages
                }
            }
    }

    func stopMessageListener() {
        messageListener?.remove()
        messageListener = nil
        activeChatID = nil
        remoteMessages = []
    }

    // MARK: - Sending

    /// Atomically writes the message document and refreshes the parent chat
    /// document (participants, last message preview, per-recipient unread
    /// counters) in a single batch commit.
    func sendMessage(text: String, chatID: String, participants: [String]) async throws {
        guard isFirebaseReady else { throw FirestoreSyncError.notAuthenticated }
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }

        let batch = db.batch()

        let messageRef = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .document()
        batch.setData([
            "senderId": uid,
            "text": text,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "sent",
        ], forDocument: messageRef)

        var chatUpdate: [String: Any] = [
            "participants": FieldValue.arrayUnion(participants),
            "lastMessage": text,
            "lastMessageTimestamp": FieldValue.serverTimestamp(),
        ]
        for participant in participants where participant != uid {
            chatUpdate["unreadCount.\(participant)"] = FieldValue.increment(Int64(1))
        }
        batch.setData(chatUpdate, forDocument: db.collection("chats").document(chatID), merge: true)

        try await batch.commit()
    }

    /// Best-effort mirror of a locally sent message into Firestore. Only
    /// deterministic `uid1_uid2` chats are synced; local demo chats stay local.
    func mirrorLocalSend(text: String, chatID: String) async {
        guard isFirebaseReady, currentUID != nil, chatID.contains("_") else { return }
        let participants = chatID.components(separatedBy: "_")
        guard participants.count == 2 else { return }
        do {
            try await sendMessage(text: text, chatID: chatID, participants: participants)
        } catch {
            print("[ChatService] Mirror send failed: \(error.localizedDescription)")
        }
    }

    /// Clears the signed-in user's unread counter on a chat.
    func markRead(chatID: String) async {
        guard isFirebaseReady, let uid = currentUID, chatID.contains("_") else { return }
        try? await db.collection("chats")
            .document(chatID)
            .setData(["unreadCount.\(uid)": 0], merge: true)
    }
}
