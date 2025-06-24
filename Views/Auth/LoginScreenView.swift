import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct LoginScreenView: View {
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
            Color(hex: "#0D0F14")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Circle()
                            .fill(Color(hex: "#7E57FF") ?? .purple)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue your fitness journey")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button(action: onForgotPasswordTap) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "#7E57FF") ?? .purple)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Login Button
                        VStack(spacing: 16) {
                            Button(action: {
                                signIn()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#7E57FF") ?? .purple,
                                            Color(hex: "#5A3FD6") ?? .purple
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                                .shadow(
                                    color: Color(hex: "#7E57FF").opacity(0.3),
                                    radius: 12, x: 0, y: 4
                                )
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 20)
                            
                            // OR Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 16)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Google Sign In Button
                            GoogleSignInButton {
                                signInWithGoogle()
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button(action: onSignUpTap) {
                                Text("Sign Up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#7E57FF") ?? .purple)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 20)
            
            // Error Alert
            if showingError, let errorMessage = errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
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
                    .background(Color.red.opacity(0.8))
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
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await AuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await AuthService.shared.signInWithGoogle(presenting: rootViewController)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .regular))
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct LoginScreenView_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreenView(
            onSignUpTap: {},
            onForgotPasswordTap: {},
            onBack: {}
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: false))
        .preferredColorScheme(.dark)
    }
}
#endif
