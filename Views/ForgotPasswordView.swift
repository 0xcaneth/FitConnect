import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var emailValidationError = ""
    @State private var shakeEmail = false
    @State private var showSuccessCheckmark = false
    @State private var showToast = false
    @FocusState private var emailFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen dark background
                Color(hex: "#0D0F14")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back arrow at top-left
                    HStack {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.0), value: showContent)
                    
                    Spacer()
                    
                    // Main content - centered
                    VStack(spacing: 32) {
                        // Title and Subtitle
                        VStack(spacing: 8) {
                            Text("Reset Your Password")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.0), value: showContent)
                            
                            Text("Enter your email to receive a reset link")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                        }
                        
                        // Email TextField with validation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                            
                            PremiumTextField(
                                placeholder: "Email Address",
                                text: $email,
                                keyboardType: .emailAddress,
                                isFocused: emailFocused
                            )
                            .focused($emailFocused)
                            .offset(x: shakeEmail ? -5 : 0)
                            .animation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true), value: shakeEmail)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                            
                            if !emailValidationError.isEmpty {
                                Text(emailValidationError)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(hex: "#FF5959") ?? .red)
                                    .padding(.leading, 20)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        
                        // Send Reset Link Button
                        Button(action: sendResetEmail) {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else if showSuccessCheckmark {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            ZStack {
                                LinearGradient(
                                    colors: isValidEmail ? [
                                        Color(hex: "#3A8AFF"),
                                        Color(hex: "#8C2FFF")
                                    ] : [
                                        Color(hex: "#4A4A4A").opacity(0.4),
                                        Color(hex: "#4A4A4A").opacity(0.4)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(26)
                                
                                // Success checkmark glow overlay
                                if showSuccessCheckmark {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .blur(radius: 10)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        )
                        .disabled(!isValidEmail || isLoading)
                        .opacity((isValidEmail && !isLoading) || showSuccessCheckmark ? 1.0 : 0.6)
                        .scaleEffect(isLoading ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                
                // Toast notification
                if showToast {
                    VStack {
                        ToastView(message: "Check your inbox for a reset link")
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.25), value: showToast)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var isValidEmail: Bool {
        email.contains("@") && !email.isEmpty && email.contains(".")
    }
    
    private func validateEmail() {
        emailValidationError = ""
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            emailValidationError = "Email is required"
        } else if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            emailValidationError = "Invalid email format"
        }
        
        if !emailValidationError.isEmpty {
            withAnimation(.default) {
                shakeEmail = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                shakeEmail = false
            }
        }
    }
    
    private func sendResetEmail() {
        // Validate email first
        validateEmail()
        
        // If validation fails, don't proceed
        if !emailValidationError.isEmpty {
            // Haptic feedback for validation error
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        emailFocused = false
        isLoading = true
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Auth.auth().sendPasswordReset(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines)) { error in
            isLoading = false
            
            if let error = error {
                // Haptic feedback for error
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                
                // Show error inline
                emailValidationError = error.localizedDescription
                withAnimation(.default) {
                    shakeEmail = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    shakeEmail = false
                }
            } else {
                // Haptic feedback for success
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
                // Show success checkmark
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showSuccessCheckmark = true
                }
                
                // Show toast after brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showToast = true
                    }
                    
                    // Hide toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showToast = false
                        }
                        
                        // Hide checkmark and dismiss view
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSuccessCheckmark = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Premium Text Field Component for Reset Password
struct PremiumTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .keyboardType(keyboardType)
            .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
            .font(.system(size: 16, weight: .regular)) // SF Pro Text 16pt
            .foregroundColor(.white)
            .accentColor(Color(hex: "#6E56E9") ?? .purple)
            .frame(height: 56) // 56pt tall
            .padding(.horizontal, 16)
            .background(Color(hex: "#212329") ?? Color.black.opacity(0.3)) // Field background
            .cornerRadius(14) // Corner radius 14pt
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        Color(hex: "#6E56E9") ?? .purple,
                        lineWidth: isFocused ? 2 : 1 // 2pt when focused, 1pt when not
                    )
                    .opacity(isFocused ? 1.0 : 0.5) // 100% opacity when focused, 50% when not
                    .animation(.easeInOut(duration: 0.15), value: isFocused) // Animate border changes
                    .shadow(
                        color: isFocused ? (Color(hex: "#6E56E9") ?? .purple).opacity(0.3) : Color.clear,
                        radius: isFocused ? 8 : 0,
                        x: 0, y: 0
                    )
            )
    }
}

// MARK: - Toast View Component
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#212329") ?? Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#7E57FF").opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.top, 60)
            .padding(.horizontal, 16)
    }
}

#if DEBUG
struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
            .preferredColorScheme(.dark)
    }
}
#endif
