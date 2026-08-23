import SwiftUI
import FirebaseCore

final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plistDict = NSDictionary(contentsOfFile: filePath),
           let appID = plistDict["GOOGLE_APP_ID"] as? String, !appID.isEmpty {
            FirebaseApp.configure()
            print("[Firebase] Successfully initialized with App ID: \(appID)")
        } else {
            print("[Firebase] ERROR: GoogleService-Info.plist is missing or invalid in Bundle.main. Operating in offline/fallback mode.")
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
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    AuthFlowView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isLoggedIn)
            .environment(dependencies.store)
            .environment(dependencies.appState)
            .tint(dependencies.store.settings.accent.color)
            .preferredColorScheme(dependencies.store.settings.appearance.colorScheme)
        }
    }
}
