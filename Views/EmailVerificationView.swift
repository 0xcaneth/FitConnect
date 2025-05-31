import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    let onVerified: () -> Void
    let onBack: () -> Void
    
    @State private var isVerifying = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showContent = false
    
    private var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    var body: some View {
        ZStack {
            // Unified Background
            LinearGradient(
                colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .modifier(ConditionalIgnoresSafeAreaEmailVerification())
            
            VStack(spacing: 32) {
                // Header with back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Email Icon
                Image(systemName: "envelope.circle.fill")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0.0)
                
                // Title
                Text("Verify Your Email")
                    .font(.largeTitle).bold()
                    .foregroundColor(.white)
                    .opacity(showContent ? 1.0 : 0.0)
                
                // Description
                VStack(alignment: .center) {
                    Text("We've sent a verification link to your email address. Please check your inbox (and spam folder!) and click the link to verify your account.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                
                // Verification Button
                Button {
                    checkVerificationStatus()
                } label: {
                    if isVerifying {
                        if #available(iOS 15.0, *) {
                            ProgressView().tint(.white)
                        } else if #available(iOS 14.0, *) {
                            ProgressView().accentColor(.white) 
                        } else {
                            Text("Verifying...") 
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("I've Verified My Email")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color("PrimaryGradientStart"))
                            .cornerRadius(10)
                    }
                }
                .disabled(isVerifying)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0.0)
                
                // Resend Button
                Button {
                    resendVerificationEmail()
                } label: {
                    Text("Resend Verification Email")
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                }
                .disabled(isVerifying)
                .padding(.horizontal, 24)
                .opacity(showContent ? 1.0 : 0.0)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        // iOS 13+ Compatible Alert
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Email Verification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func checkVerificationStatus() {
        guard let user = currentUser else {
            alertMessage = "Not logged in."
            showingAlert = true
            return
        }
        
        isVerifying = true
        user.reload { error in
            isVerifying = false
            if let error = error {
                alertMessage = "Error reloading user: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            if user.isEmailVerified {
                onVerified()
            } else {
                alertMessage = "Email not verified yet. Please check your email or try resending the verification link."
                showingAlert = true
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard let user = currentUser else {
            alertMessage = "Not logged in. Cannot resend verification email."
            showingAlert = true
            return
        }
        
        isVerifying = true
        user.sendEmailVerification { error in
            isVerifying = false
            if let error = error {
                alertMessage = "Failed to resend verification email: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Verification email sent successfully. Please check your inbox."
                showingAlert = true
            }
        }
    }
}

private struct ConditionalIgnoresSafeAreaEmailVerification: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.ignoresSafeArea()
        } else {
            content
        }
    }
}
