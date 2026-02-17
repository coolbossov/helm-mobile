import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authState: AuthState
    @AppStorage("preferredNavApp") private var preferredNavApp = "apple"

    var body: some View {
        NavigationStack {
            Form {
                Section("Navigation") {
                    Picker("Default nav app", selection: $preferredNavApp) {
                        Label("Apple Maps", systemImage: "map").tag("apple")
                        Label("Google Maps", systemImage: "globe").tag("google")
                        Label("Waze", systemImage: "car.fill").tag("waze")
                    }
                }

                Section("Account") {
                    Button(role: .destructive) {
                        Task { await authState.signOut() }
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    LabeledContent("Backend", value: AppConfig.helmAPIBaseURL)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
