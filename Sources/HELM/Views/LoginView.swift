import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authState: AuthState
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "map.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue)
                Text("HELM")
                    .font(.largeTitle.bold())
                Text("Field Sales Route Planner")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let error = authState.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await authState.signIn(email: email, password: password) }
                } label: {
                    Group {
                        if authState.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(email.isEmpty || password.isEmpty || authState.isLoading)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}
