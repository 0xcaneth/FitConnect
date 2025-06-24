import SwiftUI

@available(iOS 16.0, *)
struct SignUpScreenView: View {
    let onLoginTap: () -> Void
    let onBack: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "client"
    @State private var agreedToTerms = false
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
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.4), value: showContent)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title Section
                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                            
                            Text("Join FitConnect and start your fitness journey")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
                        }
                        .padding(.top, 40)
                        
                        // Form Container
                        VStack(spacing: 20) {
                            // Full Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                TextField("Enter your full name", text: $fullName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                            
                            // Email Address
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                TextField("Enter your email address", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.6), value: showContent)
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.7), value: showContent)
                            
                            // Account Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account Type")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                AuthSegmentedControl(
                                    options: ["client", "dietitian"],
                                    selectedOption: $selectedRole
                                )
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.8), value: showContent)
                            
                            // Terms Agreement
                            CheckboxRow(
                                text: "I agree to the Terms & Conditions",
                                isChecked: $agreedToTerms
                            )
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.9), value: showContent)
                        }
                        .padding(.horizontal, 20)
                        
                        // Create Account Button
                        VStack(spacing: 20) {
                            Button(action: {
                                signUp()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create Account")
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
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(1.0), value: showContent)
                            
                            // Login Link
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Button("Log In") {
                                    onLoginTap()
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#7E57FF") ?? .purple)
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(1.1), value: showContent)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
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
        !fullName.isEmpty && 
        !email.isEmpty && 
        email.contains("@") &&
        password.count >= 8 && 
        password == confirmPassword && 
        agreedToTerms
    }
    
    private func signUp() {
        guard isFormValid else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                print("[SignUpView] Starting signup process for role: \(selectedRole)")
                
                // CRITICAL: Await the complete signup process (including Firestore write)
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    role: selectedRole
                )
                
                print("[SignUpView] Signup completed successfully")
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "Account created! Please check your email to verify your account before signing in."
                    showSuccess = true
                    
                    // Clear form
                    fullName = ""
                    email = ""
                    password = ""
                    confirmPassword = ""
                    agreedToTerms = false
                    
                    // Auto-dismiss success message and navigate back after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showSuccess = false
                        
                        // Navigate back to login screen
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onLoginTap()
                        }
                    }
                }
            } catch {
                print("[SignUpView] Signup failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    
                    // Auto-dismiss error after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        showError = false
                    }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SignUpScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreenView(
            onLoginTap: {},
            onBack: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif