import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct LoginScreenView: View {
    let selectedRole: UserRole
    let onSignUpTap: () -> Void
    let onForgotPasswordTap: () -> Void
    let onBack: () -> Void
    
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var showContent = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        ZStack {
            ZStack {
                Color(hex: "#0A0B0F")
                    .ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        roleGradientColor.opacity(0.15),
                        roleGradientColor.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 80,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                premiumNavigationHeader()
                
                ScrollView {
                    VStack(spacing: 32) {
                        premiumHeaderSection()
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(PremiumTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(PremiumTextFieldStyle())
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: onForgotPasswordTap) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(roleGradientColor)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            Button(action: {
                                signInWithRole()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In as \(selectedRole.displayName)")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            roleGradientColor,
                                            roleGradientColor.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                                .shadow(
                                    color: roleGradientColor.opacity(0.3),
                                    radius: 12, x: 0, y: 4
                                )
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 20)
                            
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            GoogleSignInButton {
                                signInWithGoogleAndRole()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: onSignUpTap) {
                                Text("Sign Up")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(roleGradientColor)
                            }
                        }
                        .padding(.bottom, 40)
                        
                        #if DEBUG
                        NavigationLink(destination: DebugAuthView()) {
                            Text("🐛 Debug Auth Issues")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .padding(.bottom, 20)
                        #endif
                    }
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            
            if showingError, let errorMessage = errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: { showingError = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showingError)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    private var roleGradientColor: Color {
        selectedRole == .client ? Color(hex: "#4A7BFF") : Color(hex: "#4AFFA1")
    }
    
    @ViewBuilder
    private func premiumNavigationHeader() -> some View {
        HStack {
            Button(action: onBack) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(roleGradientColor)
                    .frame(width: 8, height: 8)
                
                Text(selectedRole.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.trailing, 20)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func premiumHeaderSection() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(roleGradientColor.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                roleGradientColor,
                                roleGradientColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: selectedRole == .client ? "figure.run.circle.fill" : "stethoscope.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            
            VStack(spacing: 8) {
                Text("Welcome Back!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Sign in to your \(selectedRole.displayName.lowercased()) account")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 40)
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private func signInWithRole() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password, expectedRole: selectedRole)
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // Use the safer handleAuthError method
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func signInWithGoogleAndRole() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await AuthService.shared.signInWithGoogle(presenting: rootViewController, expectedRole: selectedRole)
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        DispatchQueue.main.async {
            if let authError = error as? AuthError,
               case .roleMismatch(let correctRole) = authError {
                self.errorMessage = "You're trying to sign in with the wrong account type. You have a \(correctRole.displayName) account, so please go back and select '\(correctRole.displayName)' to access your account."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    self.showingError = false
                }
            } else {
                self.errorMessage = error.localizedDescription
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.showingError = false
                }
            }
            
            self.showingError = true
        }
    }
}

struct PremiumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .regular, design: .rounded))
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct LoginScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreenView(
            selectedRole: .client,
            onSignUpTap: {},
            onForgotPasswordTap: {},
            onBack: {}
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: false))
        .preferredColorScheme(.dark)
    }
}
#endif