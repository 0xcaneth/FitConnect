import SwiftUI

@available(iOS 16.0, *)
struct EmailVerificationView: View {
    let email: String
    let onBack: () -> Void
    let onVerified: () -> Void
    
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    @State private var resendCooldown = 0
    @State private var timer: Timer?
    
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
                            
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
                        
                        Text("Check Your Email")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                        
                        VStack(spacing: 8) {
                            Text("We've sent a verification email to:")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                            
                            Text(email)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#7E57FF") ?? .purple)
                                .multilineTextAlignment(.center)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                        
                        Text("Click the link in the email to verify your account, then return here to continue.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        // Check Verification Button
                        Button(action: {
                            checkVerification()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("I've Verified My Email")
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
                        .disabled(isLoading)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                        
                        // Resend Email Button
                        Button(action: {
                            resendVerificationEmail()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 16, weight: .medium))
                                
                                if resendCooldown > 0 {
                                    Text("Resend in \(resendCooldown)s")
                                        .font(.system(size: 16, weight: .medium))
                                } else {
                                    Text("Resend Verification Email")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundColor(resendCooldown > 0 ? .white.opacity(0.5) : Color(hex: "#7E57FF") ?? .purple)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        resendCooldown > 0 ? Color.white.opacity(0.2) : Color(hex: "#7E57FF") ?? .purple,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .disabled(resendCooldown > 0 || isLoading)
                        .opacity(showContent ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(0.6), value: showContent)
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
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func checkVerification() {
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                let isVerified = try await AuthService.shared.checkEmailVerification()
                await MainActor.run {
                    isLoading = false
                    if isVerified {
                        successMessage = "Email verified successfully!"
                        showSuccess = true
                        
                        // Navigate to main app after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onVerified()
                        }
                    } else {
                        errorMessage = "Email not yet verified. Please check your inbox and click the verification link."
                        showError = true
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
    
    private func resendVerificationEmail() {
        guard resendCooldown == 0 else { return }
        
        Task {
            do {
                try await AuthService.shared.sendEmailVerification()
                await MainActor.run {
                    successMessage = "Verification email sent! Check your inbox."
                    showSuccess = true
                    
                    // Start cooldown timer
                    resendCooldown = 60
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        if resendCooldown > 0 {
                            resendCooldown -= 1
                        } else {
                            timer?.invalidate()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(
            email: "test@example.com",
            onBack: {},
            onVerified: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif