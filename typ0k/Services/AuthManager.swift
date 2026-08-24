import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

enum AuthManagerError: LocalizedError {
    case firebaseNotConfigured

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured on this device."
        }
    }
}

/// Result of the phone-OTP Firebase handshake.
enum AuthOutcome {
    /// `users/{uid}` already carries a profile — go straight into the app.
    case existingUser
    /// Signed in but the profile document is missing a display name —
    /// route the user through `ProfileSetupView` first.
    case needsProfile
}

/// Live Firebase Authentication + Firestore profile binding.
///
/// Registration (`createUser`) and login (`signIn`) talk directly to
/// `FirebaseAuth`; on successful signup a profile document is written to
/// `users/{uid}` (allowed by the `isOwner` rule in `firestore.rules`).
/// All entry points fail soft when Firebase is not configured so the local
/// prototype flow keeps working offline.
@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()

    private let db = Firestore.firestore()

    private init() {}

    private var isFirebaseReady: Bool {
        FirebaseApp.app() != nil
    }

    /// SwiftUI-tracked mirror of the signed-in UID. Updated by the Firebase
    /// auth state listener (`startObservingAuthState`) so every view reading
    /// `currentUID` re-renders the moment an account switch lands.
    private(set) var observedUID: String?

    private var authListener: AuthStateDidChangeListenerHandle?

    var currentUID: String? {
        observedUID ?? Auth.auth().currentUser?.uid
    }

    /// Registers the Firebase auth state listener exactly once. From this
    /// point on `observedUID` (and therefore `currentUID`) tracks session
    /// changes live — message ownership, chat bindings and presence all
    /// recompute against the newly authenticated user.
    func startObservingAuthState() {
        guard isFirebaseReady, authListener == nil else { return }
        observedUID = Auth.auth().currentUser?.uid
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.observedUID = user?.uid
            }
        }
    }

    // MARK: - Registration & login

    @discardableResult
    func createUser(email: String, password: String, displayName: String?, phone: String?) async throws -> String {
        guard isFirebaseReady else { throw AuthManagerError.firebaseNotConfigured }
        print("[Auth Debug] Registration attempt: \(email)")

        // A previously active session on this device must never leak into a
        // new account's registration — sign out explicitly first.
        try? Auth.auth().signOut()

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            var profile: [String: Any] = [
                "uid": uid,
                "email": email,
                "createdAt": FieldValue.serverTimestamp(),
            ]
            if let displayName, !displayName.isEmpty { profile["displayName"] = displayName }
            if let phone, !phone.isEmpty { profile["phone"] = phone }

            // Profile document syncs immediately so users/{uid} exists before
            // the UI advances (allowed by the isOwner rule).
            try await db.collection("users").document(uid).setData(profile, merge: true)
            print("[Auth Debug] Registration success: uid=\(uid)")
            return uid
        } catch {
            print("[Auth Debug] Registration error: \(error.localizedDescription)")
            throw error
        }
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> String {
        guard isFirebaseReady else { throw AuthManagerError.firebaseNotConfigured }
        print("[Auth Debug] Sign-in attempt: \(email)")
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("[Auth Debug] Sign-in success: uid=\(result.user.uid)")
            return result.user.uid
        } catch {
            print("[Auth Debug] Sign-in error: \(error.localizedDescription)")
            throw error
        }
    }

    /// Bridges the phone-OTP prototype flow to Firebase Auth: the verified
    /// phone number is mapped to a deterministic credential, created on first
    /// run and signed in afterwards. Returns whether the account already has
    /// a completed profile (`users/{uid}.displayName`) so the caller can
    /// either enter the app instantly or route through profile setup.
    /// Throws when Firebase rejects the registration so the calling UI can
    /// surface an alert; a missing Firebase config keeps local mode.
    @discardableResult
    func authenticateVerifiedPhone(_ phoneNumber: String) async throws -> AuthOutcome {
        guard isFirebaseReady else {
            print("[Auth Debug] Firebase not configured — continuing in local mode.")
            return .existingUser
        }
        let normalized = phoneNumber.filter(\.isNumber)
        let email = "\(normalized)@typ0k.app"
        let password = "typ0k-otp-\(normalized)"
        do {
            try await signIn(email: email, password: password)
            return await profileIsComplete() ? .existingUser : .needsProfile
        } catch {
            // No account yet (or a legacy credential mismatch) — register.
            // Any rejection here propagates to the UI.
            try await createUser(email: email, password: password, displayName: nil, phone: phoneNumber)
            return .needsProfile
        }
    }

    /// True when `users/{uid}` exists and carries a non-empty `displayName`.
    private func profileIsComplete() async -> Bool {
        guard let uid = currentUID else { return false }
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            let displayName = document.data()?["displayName"] as? String ?? ""
            return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            print("[Auth Debug] Profile lookup failed: \(error.localizedDescription)")
            return false
        }
    }

    /// Cleanly swaps the Firebase Auth session to the account behind
    /// `phoneNumber` (multi-account switcher). The deterministic credential
    /// is signed in if it exists, otherwise registered on the fly.
    func switchSession(toPhone phoneNumber: String) async throws {
        guard isFirebaseReady else { return }
        let normalized = phoneNumber.filter(\.isNumber)
        guard !normalized.isEmpty else { return }
        try? Auth.auth().signOut()
        let email = "\(normalized)@typ0k.app"
        let password = "typ0k-otp-\(normalized)"
        do {
            try await signIn(email: email, password: password)
        } catch {
            try await createUser(email: email, password: password, displayName: nil, phone: phoneNumber)
        }
    }

    /// Persists the profile-setup answers onto `users/{uid}`: a required
    /// display name plus an optional username (Telegram-style — blank is
    /// allowed). Best-effort: failures only log.
    func completeProfile(displayName: String, username: String?) async {
        guard isFirebaseReady, currentUID != nil else { return }
        var fields: [String: Any] = ["displayName": displayName]
        if let username = username?.trimmingCharacters(in: .whitespacesAndNewlines),
           !username.isEmpty {
            fields["username"] = username
            fields["usernameLower"] = username.lowercased()
        }
        do {
            try await updateProfile(fields: fields)
            print("[Auth] Profile completed for users/\(currentUID ?? "?")")
        } catch {
            print("[Auth] Profile completion failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Profile sync

    /// Merges profile fields into the caller's own `users/{uid}` document.
    func updateProfile(fields: [String: Any]) async throws {
        guard isFirebaseReady else { throw AuthManagerError.firebaseNotConfigured }
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("users").document(uid).setData(fields, merge: true)
    }

    /// Publishes the searchable username (`username` + lowercase
    /// `usernameLower`) onto the caller's profile document so the global
    /// @username search can find this user. Best-effort: failures only log.
    func syncSearchProfile(username: String, displayName: String?) async {
        guard isFirebaseReady, currentUID != nil else { return }
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var fields: [String: Any] = [
            "username": trimmed,
            "usernameLower": trimmed.lowercased(),
        ]
        if let displayName, !displayName.isEmpty {
            fields["displayName"] = displayName
        }
        do {
            try await updateProfile(fields: fields)
            print("[Auth] Synced searchable username @\(trimmed)")
        } catch {
            print("[Auth] Username sync failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign out

    func signOut() {
        try? Auth.auth().signOut()
    }
}
