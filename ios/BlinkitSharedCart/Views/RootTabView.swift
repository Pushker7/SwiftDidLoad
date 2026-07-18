import SwiftUI

struct RootTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.user == nil {
                OnboardingView()
            } else {
                mainTabs
            }
        }
    }

    private var mainTabs: some View {
        ZStack(alignment: .top) {
            TabView {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }

                NavigationStack {
                    CartTabView()
                }
                .tabItem { Label("Cart", systemImage: "cart.fill") }
                .badge(appState.cartBadgeCount)

                NavigationStack {
                    ProfileView()
                }
                .tabItem { Label("Profile", systemImage: "person.fill") }
            }
            .tint(Theme.primary)

            ToastOverlay(toasts: appState.toasts)
        }
    }
}
