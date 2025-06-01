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
    @FocusState private var emailFocused: Bool
    
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
                                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                    .padding(.bottom, 40)
                    
                    // Main content - centered
                    VStack(spacing: 32) {
                        // Title
                        Text("Reset Your Password")
                            .font(.system(size: 28, weight: .semibold)) // SF Pro Semibold 28pt
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        // Subtitle
                        Text("Enter your email to receive a reset link")
                            .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                            .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) // #AAAAAA
                            .multilineTextAlignment(.center)
                        
                        // Email TextField
                        TextField("Email Address", text: $email)
                            .autocapitalization(.none) // Turn off automatic capitalization
                            .disableAutocorrection(true) // Turn off autocorrection
                            .textContentType(.emailAddress)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white) // White text
                            .padding(12)
                            .background(Color(red: 0.12, green: 0.12, blue: 0.15)) // #1E1E26
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        emailFocused ? Color(red: 0.0, green: 0.9, blue: 1.0) : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .focused($emailFocused)
                        
                        // Send Reset Link Button
                        Button(action: sendResetEmail) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            isValidEmail ?
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                    Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray, Color.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16) // Corner radius 16
                        .disabled(!isValidEmail || isLoading)
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6), value: showContent)
                    
                    Spacer()
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
        email.contains("@") && !email.isEmpty
    }
    
    private func sendResetEmail() {
        emailFocused = false
        isLoading = true
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            isLoading = false
            
            if let error = error {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
            } else {
                alertTitle = "Reset Link Sent"
                alertMessage = "Reset link sent. Please check your email."
            }
            
            showAlert = true
        }
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
