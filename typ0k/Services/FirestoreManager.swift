import Foundation
import FirebaseAuth
import FirebaseFirestore

enum FirestoreSyncError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to sync with the server."
        }
    }
}

/// Gateway to the production Firestore backend.
///
/// Every write carries the authenticated UID in exactly the shape that
/// `firestore.rules` validates server-side:
/// - messages set `senderId == Auth.auth().currentUser?.uid`
///   (rules: only the sender may create, only the author may edit/delete)
/// - cosmetic inventory updates target `users/{uid}` where `uid` is the
///   caller's own auth ID (rules: `isOwner(userId)`)
@MainActor
final class FirestoreManager {
    static let shared = FirestoreManager()

    private let db = Firestore.firestore()

    private init() {}

    private var currentUID: String? {
        Auth.auth().currentUser?.uid
    }

    // MARK: - Messages

    /// Sends a chat message. The payload's `senderId` is always derived from
    /// the Firebase Auth session so the rules' create check passes.
    @discardableResult
    func sendMessage(text: String, chatID: String) async throws -> String {
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }

        let payload: [String: Any] = [
            "senderId": uid,
            "text": text,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        let reference = try await db.collection("chats")
            .document(chatID)
            .collection("messages")
            .addDocument(data: payload)
        return reference.documentID
    }

    /// Edits a message previously authored by the current user
    /// (rules: `resource.data.senderId == request.auth.uid`).
    func editMessage(id: String, chatID: String, newText: String) async throws {
        guard currentUID != nil else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("chats")
            .document(chatID)
            .collection("messages")
            .document(id)
            .updateData(["text": newText])
    }

    /// Deletes a message previously authored by the current user.
    func deleteMessage(id: String, chatID: String) async throws {
        guard currentUID != nil else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("chats")
            .document(chatID)
            .collection("messages")
            .document(id)
            .delete()
    }

    // MARK: - Cosmetic inventory

    /// Persists the equipped avatar frame on the caller's own profile
    /// document (`users/{uid}` — passes the `isOwner` rule).
    func updateSelectedFrame(frameID: String?) async throws {
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("users")
            .document(uid)
            .setData(["selectedFrameId": frameID ?? NSNull()], merge: true)
    }

    /// Persists the active nickname style on the caller's own profile.
    func updateNicknameStyle(styleID: String) async throws {
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("users")
            .document(uid)
            .setData(["nicknameStyleId": styleID], merge: true)
    }
}
