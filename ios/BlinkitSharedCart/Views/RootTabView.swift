import SwiftUI

enum RootTab: Hashable {
    case home, cart, profile
}

private struct GoHomeActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct GoToProfileActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    /// Clears the Cart tab's navigation stack and switches to Home. Used after checkout
    /// so leaving the success screen never lands back on the (now stale) address screen.
    var goHome: () -> Void {
        get { self[GoHomeActionKey.self] }
        set { self[GoHomeActionKey.self] = newValue }
    }

    /// Switches to the Profile tab — used by the avatar shortcut in the Home header.
    var goToProfile: () -> Void {
        get { self[GoToProfileActionKey.self] }
        set { self[GoToProfileActionKey.self] = newValue }
    }
}

struct RootTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: RootTab = .home
    @State private var cartPath = NavigationPath()

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
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(RootTab.home)

                NavigationStack(path: $cartPath) {
                    CartTabView()
                }
                .tabItem { Label("Cart", systemImage: "cart.fill") }
                .badge(appState.cartBadgeCount)
                .tag(RootTab.cart)

                NavigationStack {
                    ProfileView()
                }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(RootTab.profile)
            }
            .tint(Theme.primary)
            .environment(\.goHome) {
                cartPath = NavigationPath()
                selectedTab = .home
            }
            .environment(\.goToProfile) {
                selectedTab = .profile
            }

            ToastOverlay(toasts: appState.toasts)
        }
    }
}
