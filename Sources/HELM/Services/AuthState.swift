import Foundation
import Supabase

@MainActor
final class AuthState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let auth = SupabaseService.shared.client.auth

    func checkSession() async {
        do {
            _ = try await auth.session
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        try? await auth.signOut()
        isAuthenticated = false
    }
}
