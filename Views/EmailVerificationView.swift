import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    let onVerified: () -> Void
    let onBack: () -> Void
    
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    private var userEmail: String {
        currentUser?.email ?? "your email"
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                        .frame(height: 64)
                    
                    // Holographic glass panel (240pt height, 90% width)
                    VStack(spacing: 20) {
                        // Back arrow (top-left inside panel) - signs out and returns to login
                        HStack {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                try? Auth.auth().signOut()
                                onBack()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .stroke(Color(red: 0.43, green: 0.31, blue: 1.0), lineWidth: 1.5) // #6E4EFF
                                    )
                            }
                            .padding(.leading, 16)
                            .padding(.top, 16)
                            
                            Spacer()
                        }
                        
                        // Title & Subtitle
                        VStack(spacing: 8) {
                            Text("Verify Your Email")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                            
                            VStack(spacing: 4) {
                                Text("A verification link has been sent to")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                                
                                Text(userEmail)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                                
                                Text("Click it in your inbox to continue.")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                                
                                Text("Check your spam/junk folder if you don't see it.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6)) // #999999
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 16)
                        .multilineTextAlignment(.center)
                        
                        // "Resend Verification Email" Button
                        Button(action: resendVerificationEmail) {
                            Text("Resend Verification Email")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.0, green: 0.9, blue: 1.0)) // #00E5FF
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.17, green: 0.17, blue: 0.20)) // #2B2B33
                        )
                        .padding(.horizontal, 16)
                        
                        // "Continue" Button - disabled until email verified
                        Button(action: checkVerificationStatus) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            Group {
                                if !isLoading {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                            Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.4), // #6E4EFF @40%
                                            Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.4)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                        )
                        .cornerRadius(12)
                        .disabled(isLoading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .frame(width: geometry.size.width * 0.9)
                    .frame(height: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.85)) // #1E1E26 @85%
                            .background(.ultraThinMaterial.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.5), // #00E5FF
                                                Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.5)  // #6E4EFF
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .opacity(showContent ? 1.0 : 0.0)
                    .scaleEffect(showContent ? 1.0 : 0.95)
                    
                    Spacer()
                }
                
                // Toast message
                if showToast {
                    VStack {
                        Spacer()
                        
                        Text(toastMessage)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.17, green: 0.17, blue: 0.20).opacity(0.9)) // #2B2B33 @90%
                            )
                            .padding(.horizontal, 32)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        Spacer()
                            .frame(height: max(80, geometry.safeAreaInsets.bottom + 60))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
            
            // Auto-send verification email on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                sendInitialVerificationEmail()
            }
        }
    }
    
    private func sendInitialVerificationEmail() {
        guard let user = currentUser else { return }
        
        user.sendEmailVerification { error in
            // Silent send on appear
        }
    }
    
    private func resendVerificationEmail() {
        guard let user = currentUser else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("DEBUG: Resending verification email to: \(user.email ?? "unknown")")
        
        user.sendEmailVerification { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("DEBUG: Resend email error: \(error.localizedDescription)")
                    let nsError = error as NSError
                    
                    if nsError.code == 17010 { // Too many requests
                        toastMessage = "Please wait a moment before requesting another email"
                    } else if nsError.code == 17020 { // Network error
                        toastMessage = "Network error. Check your connection and try again"
                    } else {
                        toastMessage = "Failed to resend email. Try again later"
                    }
                } else {
                    print("DEBUG: Verification email resent successfully")
                    toastMessage = "Verification email sent! Check your inbox and spam folder"
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showToast = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showToast = false
                    }
                }
            }
        }
    }
    
    private func checkVerificationStatus() {
        guard let user = currentUser else { return }
        
        isLoading = true
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        user.reload { error in
            isLoading = false
            
            if user.isEmailVerified {
                onVerified()
            } else {
                toastMessage = "Email not verified yet. Please check your email."
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showToast = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showToast = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(onVerified: {}, onBack: {})
            .preferredColorScheme(.dark)
    }
}
#endif
