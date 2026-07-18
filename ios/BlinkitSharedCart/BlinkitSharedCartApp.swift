import SwiftUI

@main
struct BlinkitSharedCartApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appState)
                .preferredColorScheme(.light)
                .task { await appState.bootstrap() }
        }
    }
}
