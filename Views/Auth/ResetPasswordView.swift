import SwiftUI

@available(iOS 16.0, *)
struct ResetPasswordView: View {
    let onBack: () -> Void
    
    @State private var email = ""
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4), value: showContent)
                
                Spacer()
                
                // Content
                VStack(spacing: 40) {
                    // Title Section
                    VStack(spacing: 16) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#7E57FF") ?? .purple,
                                            Color(hex: "#5A3FD6") ?? .purple
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                        
                        Text("Reset Your Password")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                        
                        Text("Enter your email address and we'll send you a link to reset your password")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                    }
                    
                    // Email Input
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                            
                            TextField("Enter your email address", text: $email)
                                .textFieldStyle(PremiumTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                        
                        Button(action: {
                            sendPasswordReset()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Send Reset Link")
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
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            
            // Error Banner
            if showError {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showError = false
                        }) {
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
                .animation(.easeInOut(duration: 0.3), value: showError)
            }
            
            // Success Banner
            if showSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showSuccess = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showSuccess)
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
        !email.isEmpty && email.contains("@")
    }
    
    private func sendPasswordReset() {
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                try await AuthService.shared.sendPasswordReset(email: email)
                await MainActor.run {
                    isLoading = false
                    successMessage = "Password reset email sent! Check your inbox and follow the instructions to reset your password."
                    showSuccess = true
                    
                    // Auto-dismiss success message after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ResetPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ResetPasswordView(onBack: {})
            .preferredColorScheme(.dark)
    }
}
#endif
