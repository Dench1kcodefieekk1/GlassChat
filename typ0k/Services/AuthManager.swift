import Foundation
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

/// Live Firebase Authentication + Firestore profile binding.
///
/// Registration (`createUser`) and login (`signIn`) talk directly to
/// `FirebaseAuth`; on successful signup a profile document is written to
/// `users/{uid}` (allowed by the `isOwner` rule in `firestore.rules`).
/// All entry points fail soft when Firebase is not configured so the local
/// prototype flow keeps working offline.
@MainActor
final class AuthManager {
    static let shared = AuthManager()

    private let db = Firestore.firestore()

    private init() {}

    private var isFirebaseReady: Bool {
        FirebaseApp.app() != nil
    }

    var currentUID: String? {
        Auth.auth().currentUser?.uid
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
    /// run and signed in afterwards. Throws when Firebase rejects the
    /// registration so the calling UI can surface an alert and block
    /// navigation; a missing Firebase config simply keeps local mode.
    func authenticateVerifiedPhone(_ phoneNumber: String) async throws {
        guard isFirebaseReady else {
            print("[Auth Debug] Firebase not configured — continuing in local mode.")
            return
        }
        let normalized = phoneNumber.filter(\.isNumber)
        let email = "\(normalized)@typ0k.app"
        let password = "typ0k-otp-\(normalized)"
        do {
            try await signIn(email: email, password: password)
        } catch {
            // No account yet (or a legacy credential mismatch) — register.
            // Any rejection here propagates to the UI.
            try await createUser(email: email, password: password, displayName: nil, phone: phoneNumber)
        }
    }

    // MARK: - Profile sync

    /// Merges profile fields into the caller's own `users/{uid}` document.
    func updateProfile(fields: [String: Any]) async throws {
        guard isFirebaseReady else { throw AuthManagerError.firebaseNotConfigured }
        guard let uid = currentUID else { throw FirestoreSyncError.notAuthenticated }
        try await db.collection("users").document(uid).setData(fields, merge: true)
    }

    // MARK: - Sign out

    func signOut() {
        try? Auth.auth().signOut()
    }
}
