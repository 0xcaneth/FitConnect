// Views/SignUpView.swift
import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    let onSignUpComplete: () -> Void
    let onBack: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Unified Background
            UnifiedBackground()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FitConnectColors.textPrimary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        Text("Create Account")
                            .font(FitConnectFonts.largeTitle())
                            .foregroundColor(FitConnectColors.textPrimary)
                            .padding(.top, 40)
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1.0 : 0.0)
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            EnhancedTextField("Full Name", text: $fullName)
                            EnhancedTextField("Email", text: $email, keyboardType: .emailAddress)
                                .autocapitalization(.none)
                            EnhancedTextField("Password", text: $password, isSecure: true)
                            EnhancedTextField("Confirm Password", text: $confirmPassword, isSecure: true)
                        }
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        
                        // Sign Up Button
                        UnifiedPrimaryButton("Sign Up") {
                            handleSignUp()
                        }
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1.0 : 0.0)
                        
                        Spacer().frame(height: 40)
                    }
                }
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
                title: Text("Sign Up Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handleSignUp() {
        guard !fullName.isEmpty else {
            alertMessage = "Enter your name"
            showingAlert = true
            return
        }
        guard email.contains("@") else {
            alertMessage = "Invalid email"
            showingAlert = true
            return
        }
        guard password.count >= 6 else {
            alertMessage = "Password must be at least 6 characters"
            showingAlert = true
            return
        }
        guard password == confirmPassword else {
            alertMessage = "Passwords don't match"
            showingAlert = true
            return
        }
        
        AuthService.signUp(email: email, password: password) { result in
            switch result {
            case .success:
                onSignUpComplete()
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}
