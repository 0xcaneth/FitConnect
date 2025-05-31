// Views/LoginView.swift
import SwiftUI
import FirebaseAuth        // Auth işlemleri için

struct LoginView: View {
  let onLoginComplete: () -> Void
  let onSignUpTap:     () -> Void

  @State private var email             = ""
  @State private var password          = ""
  @State private var isPasswordVisible = false
    
  @State private var showingAlert      = false
  @State private var alertMessage      = ""
  @State private var showContent       = false

  var body: some View {
    ZStack {
      // Unified Background
      UnifiedBackground()

      VStack(spacing: 32) {
        Spacer()

        // Welcome Back Title
        Text("Welcome Back")
          .font(FitConnectFonts.largeTitle())
          .foregroundColor(FitConnectColors.textPrimary)
          .scaleEffect(showContent ? 1.0 : 0.9)
          .opacity(showContent ? 1.0 : 0.0)

        // Input Fields
        VStack(spacing: 16) {
          // Email Field
          EnhancedTextField("Email", text: $email, keyboardType: .emailAddress)
            .autocapitalization(.none)
          
          // Password Field with Eye Toggle
          HStack {
            Group {
              if isPasswordVisible {
                TextField("Password", text: $password)
              } else {
                SecureField("Password", text: $password)
              }
            }
            .font(FitConnectFonts.body)
            .foregroundColor(FitConnectColors.textPrimary)
            
            Button(action: {
              isPasswordVisible.toggle()
            }) {
              Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(FitConnectColors.accentColor)
                .font(.system(size: 16))
            }
          }
          .padding(16)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(FitConnectColors.inputBackground)
              .overlay(
                RoundedRectangle(cornerRadius: 12)
                  .stroke(FitConnectColors.accentColor.opacity(0.3), lineWidth: 1)
              )
          )
        }
        .padding(.horizontal, 32)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 20)
        
        // Forgot Password Link
        Button("Forgot Password?") {
          // şimdilik boş
        }
        .font(FitConnectFonts.body)
        .foregroundColor(FitConnectColors.textTertiary)
        .opacity(showContent ? 1.0 : 0.0)

        // Giriş butonu
        UnifiedPrimaryButton("Log In") {
          handleLogin()
        }
        .padding(.horizontal, 32)
        .opacity(showContent ? 1.0 : 0.0)

        Spacer()

        // Kayıt ol bağlantısı
        HStack {
          Text("Don't have an account?")
            .font(FitConnectFonts.body)
            .foregroundColor(FitConnectColors.textSecondary)
          
          Button(action: onSignUpTap) {
            Text("Sign Up")
              .font(FitConnectFonts.body)
              .fontWeight(.semibold)
              .foregroundColor(FitConnectColors.textPrimary)
          }
        }
        .opacity(showContent ? 1.0 : 0.0)
        .padding(.bottom, 40)
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
        title: Text("Login Error"),
        message: Text(alertMessage),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  private func handleLogin() {
    guard !email.isEmpty, !password.isEmpty else {
      alertMessage = "Please fill both fields."
      showingAlert = true
      return
    }
    AuthService.login(email: email, password: password) { result in
      switch result {
      case .success: onLoginComplete()
      case .failure(let error):
        alertMessage = error.localizedDescription
        showingAlert = true
      }
    }
  }
}
