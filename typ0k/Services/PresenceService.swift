import SwiftUI
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Who can see the user's online status and last-seen timestamp.
/// Mirrored onto `users/{uid}.lastSeenPrivacy` in Firestore.
enum LastSeenPrivacy: String, Codable, CaseIterable, Identifiable {
    case everyone
    case myContacts
    case nobody

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyone: return "Everyone"
        case .myContacts: return "My Contacts"
        case .nobody: return "Nobody"
        }
    }
}

/// Live presence fields read from a counterpart's `users/{uid}` document.
struct RemotePresence: Equatable {
    var isOnline = false
    var lastSeen: Date? = nil
    var lastSeenPrivacy: LastSeenPrivacy = .everyone
}

/// Real-time Firestore presence engine.
///
/// Publishes onto the signed-in user's `users/{uid}` document:
/// - `isOnline: true` on `.active` scene phase, `false` on `.background`
/// - `lastSeen: serverTimestamp` on every state flip and on a 60-second
///   heartbeat while foregrounded
/// - account switches mark the outgoing session offline immediately
///
/// The service also subscribes to the open chat's counterpart document
/// (`observePresence(of:)`) so the chat header binds to live status.
/// All Firestore callbacks are marshalled onto the main actor.
@MainActor
@Observable
final class PresenceService {
    static let shared = PresenceService()

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?
    private var heartbeatTask: Task<Void, Never>?
    private var presenceListener: ListenerRegistration?
    private var presenceListenerUID: String?
    private var ownUID: String?
    private(set) var isForeground = true

    /// Live presence snapshot of the counterpart observed by the open chat.
    private(set) var observedPresence: RemotePresence?

    private init() {}

    private var isFirebaseReady: Bool { FirebaseApp.app() != nil }

    private var currentUID: String? {
        ownUID ?? Auth.auth().currentUser?.uid
    }

    // MARK: - Lifecycle

    func start() {
        guard isFirebaseReady else { return }
        bindAuth()
        if let uid = Auth.auth().currentUser?.uid {
            ownUID = uid
            writePresence(online: isForeground, uid: uid)
            startHeartbeat(uid: uid)
        }
    }

    /// Rebinds presence tracking after an account switch so the newly
    /// signed-in UID publishes its state right away.
    func refreshForAccountSwitch() {
        guard isFirebaseReady else { return }
        bindAuth()
        if let uid = Auth.auth().currentUser?.uid {
            handleAuthChange(uid: uid)
        }
    }

    /// Scene-phase entry point: online while `.active`, offline once the app
    /// reaches `.background`. `.inactive` is transient (control center,
    /// incoming calls) and keeps the session online.
    func setScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isForeground = true
            guard isFirebaseReady, let uid = currentUID else { return }
            ownUID = uid
            writePresence(online: true, uid: uid)
            startHeartbeat(uid: uid)
        case .background:
            isForeground = false
            stopHeartbeat()
            guard isFirebaseReady, let uid = currentUID else { return }
            writePresence(online: false, uid: uid)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Auth binding

    private func bindAuth() {
        guard isFirebaseReady, authListener == nil else { return }
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthChange(uid: user?.uid)
            }
        }
    }

    private func handleAuthChange(uid: String?) {
        if let previous = ownUID, previous != uid {
            // The outgoing account flips offline immediately — peers watching
            // users/{previous} receive the update in real time.
            writePresence(online: false, uid: previous)
        }
        ownUID = uid
        guard let uid else {
            stopHeartbeat()
            return
        }
        writePresence(online: isForeground, uid: uid)
        startHeartbeat(uid: uid)
    }

    // MARK: - Publishing

    private func writePresence(online: Bool, uid: String) {
        guard isFirebaseReady else { return }
        db.collection("users").document(uid).setData([
            "isOnline": online,
            "lastSeen": FieldValue.serverTimestamp(),
        ], merge: true) { error in
            if let error {
                print("[Presence] Write failed: \(error.localizedDescription)")
            }
        }
    }

    /// Publishes the user's last-seen privacy choice onto `users/{uid}` so
    /// counterparts can enforce it while rendering status labels.
    func publishPrivacy(_ privacy: LastSeenPrivacy) {
        guard isFirebaseReady, let uid = currentUID else { return }
        db.collection("users").document(uid).setData(
            ["lastSeenPrivacy": privacy.rawValue],
            merge: true
        )
    }

    private func startHeartbeat(uid: String) {
        stopHeartbeat()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                guard !Task.isCancelled, let self, self.isForeground else { break }
                self.writePresence(online: true, uid: uid)
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    // MARK: - Counterpart observation

    /// Subscribes to `users/{uid}` for the open chat's counterpart. Pass
    /// `nil` to detach when leaving the chat.
    func observePresence(of uid: String?) {
        guard uid != presenceListenerUID else { return }
        presenceListener?.remove()
        presenceListener = nil
        presenceListenerUID = uid
        observedPresence = nil
        guard isFirebaseReady, let uid else { return }
        presenceListener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error {
                    print("[Presence] Observer error: \(error.localizedDescription)")
                    return
                }
                guard let data = snapshot?.data() else { return }
                let presence = RemotePresence(
                    isOnline: (data["isOnline"] as? Bool) ?? false,
                    lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue(),
                    lastSeenPrivacy: LastSeenPrivacy(
                        rawValue: (data["lastSeenPrivacy"] as? String) ?? ""
                    ) ?? .everyone
                )
                Task { @MainActor in
                    self?.observedPresence = presence
                }
            }
    }
}
