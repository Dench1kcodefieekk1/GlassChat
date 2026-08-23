import SwiftUI
import FirebaseCore

final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FirebaseApp.isConfigurationAvailable {
            FirebaseApp.configure()
        } else {
            print("Firebase: GoogleService-Info.plist is missing or invalid — skipping configuration.")
        }
        return true
    }
}

@main
struct Typ0kApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) private var appDelegate
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    RootView()
                } else {
                    AuthFlowView()
                }
            }
            .environment(dependencies.store)
            .environment(dependencies.appState)
            .tint(dependencies.store.settings.accent.color)
            .preferredColorScheme(dependencies.store.settings.appearance.colorScheme)
        }
    }
}
