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
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid

        var profile: [String: Any] = [
            "uid": uid,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let displayName, !displayName.isEmpty { profile["displayName"] = displayName }
        if let phone, !phone.isEmpty { profile["phone"] = phone }

        try await db.collection("users").document(uid).setData(profile, merge: true)
        return uid
    }

    @discardableResult
    func signIn(email: String, password: String) async throws -> String {
        guard isFirebaseReady else { throw AuthManagerError.firebaseNotConfigured }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user.uid
    }

    /// Bridges the phone-OTP prototype flow to Firebase Auth: the verified
    /// phone number is mapped to a deterministic credential, created on first
    /// run and signed in afterwards. Never blocks the local login — failures
    /// are logged and swallowed.
    func authenticateVerifiedPhone(_ phoneNumber: String) async {
        guard isFirebaseReady else {
            print("[Auth] Firebase not configured — staying in local mode.")
            return
        }
        let normalized = phoneNumber.filter(\.isNumber)
        let email = "\(normalized)@typ0k.app"
        let password = "typ0k-otp-\(normalized)"
        do {
            let uid = try await signIn(email: email, password: password)
            print("[Auth] Signed in existing user \(uid)")
        } catch {
            do {
                let uid = try await createUser(email: email, password: password, displayName: nil, phone: phoneNumber)
                print("[Auth] Created user document users/\(uid)")
            } catch {
                print("[Auth] Firebase auth unavailable: \(error.localizedDescription)")
            }
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
