import SwiftUI

@main
struct GlassChatApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies.store)
                .environment(dependencies.appState)
                .tint(dependencies.store.settings.accent.color)
                .preferredColorScheme(dependencies.store.settings.appearance.colorScheme)
        }
    }
}
