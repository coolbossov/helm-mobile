import SwiftUI

@main
struct HELMApp: App {
    @StateObject private var authState = AuthState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authState: AuthState

    var body: some View {
        Group {
            if authState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await authState.checkSession()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            RouteListView()
                .tabItem {
                    Label("Routes", systemImage: "map")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
