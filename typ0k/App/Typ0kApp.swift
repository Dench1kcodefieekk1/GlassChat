import SwiftUI

@main
struct Typ0kApp: App {
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
