// Views/SignUpView.swift
import SwiftUI

struct SignUpView: View {
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            // Aynı gradyan arka plan
            LinearGradient(
                gradient: Gradient(colors: [ Color("PrimaryGradientStart"), Color("PrimaryGradientEnd") ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Create Account")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                        .padding(.top, 40)

                    // Input alanları
                    Group {
                        TextField("Full Name", text: $fullName)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                        // Password
                        HStack {
                            Group {
                                if isPasswordVisible {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white)
                            }
                        }

                        // Confirm Password
                        HStack {
                            Group {
                                if isConfirmPasswordVisible {
                                    TextField("Confirm Password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(.white)

                            Button {
                                isConfirmPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // Sign Up butonu
                    Button(action: handleSignUp) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color("PrimaryGradientStart"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 32)
                    .alert(isPresented: $showingAlert) {
                        Alert(title: Text("Sign Up Error"),
                              message: Text(alertMessage),
                              dismissButton: .default(Text("OK")))
                    }

                    Spacer()
                }
            }
        }
    }

    private func handleSignUp() {
        // Basit validasyon
        guard !fullName.isEmpty else {
            alertMessage = "Please enter your full name."
            showingAlert = true
            return
        }
        guard !email.isEmpty, email.contains("@") else {
            alertMessage = "Please enter a valid email."
            showingAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters."
            showingAlert = true
            return
        }
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showingAlert = true
            return
        }
        // TODO: AuthService.signUp(name:email:password:)
        
        AuthService.signUp(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("Signed up:", user.uid)
                // navigate to app…
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
