// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            // Arka plan: aynı gradyan
            LinearGradient(
                gradient: Gradient(colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Welcome Back")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)

                VStack(spacing: 16) {
                    // Email alanı
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)

                    // Password alanı
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.white)

                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 32)

                // Login butonu
                Button(action: handleLogin) {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color("PrimaryGradientStart"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 32)
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }

                Spacer()

                // Sign up yönlendirme
                // LoginView.swift içindeki HStack:
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.white.opacity(0.8))
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Sign Up")
                            .foregroundColor(.white)
                            .bold()
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func handleLogin() {
        // Basit validation örneği
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please enter both email and password."
            showingAlert = true
            return
        }
        // TODO: AuthService.login(email:password:)
        AuthService.login(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("Logged in:", user.uid)
                // navigate to main app…
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
