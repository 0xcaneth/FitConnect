// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
  let onLoginComplete: () -> Void
  let onSignUpTap:     () -> Void

  @State private var email            = ""
  @State private var password         = ""
  @State private var isPasswordVisible = false

  @State private var showingAlert     = false
  @State private var alertMessage     = ""

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer()
        Text("Welcome Back")
          .font(.largeTitle).bold()
          .foregroundColor(.white)

        VStack(spacing: 16) {
          TextField("Email", text: $email)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)

          HStack {
            Group {
              if isPasswordVisible {
                TextField("Password", text: $password)
              } else {
                SecureField("Password", text: $password)
              }
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)

            Button {
              isPasswordVisible.toggle()
            } label: {
              Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(.white)
            }
          }
        }
        .padding(.horizontal, 32)

        Button("Forgot Password?") {
          // wysiwy… şimdilik boş
        }
        .foregroundColor(.white.opacity(0.8))

        Button {
          handleLogin()
        } label: {
          Text("Log In")
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .foregroundColor(Color("PrimaryGradientStart"))
        }
        .padding(.horizontal, 32)
        .alert("Login Error", isPresented: $showingAlert) {
          Button("OK", role: .cancel) { }
        } message: {
          Text(alertMessage)
        }

        Spacer()

        HStack {
          Text("Don't have an account?")
            .foregroundColor(.white.opacity(0.8))
          Button("Sign Up", action: onSignUpTap)
            .foregroundColor(.white).bold()
        }
        .padding(.bottom, 40)
      }
    }
  }

  private func handleLogin() {
    guard !email.isEmpty, !password.isEmpty else {
      alertMessage = "Please fill both fields."
      showingAlert = true
      return
    }
    AuthService.login(email: email, password: password) { res in
      switch res {
      case .success: onLoginComplete()
      case .failure(let e):
        alertMessage = e.localizedDescription
        showingAlert = true
      }
    }
  }
}
