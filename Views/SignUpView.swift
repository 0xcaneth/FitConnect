// Views/SignUpView.swift
import SwiftUI
import FirebaseCore        // FirebaseApp.configure() için
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanız



struct SignUpView: View {
  let onSignUpComplete: () -> Void
  let onBack:           () -> Void

  @State private var fullName        = ""
  @State private var email           = ""
  @State private var password        = ""
  @State private var confirmPassword = ""
  @State private var showingAlert    = false
  @State private var alertMessage    = ""

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            Text("Create Account")
              .font(.largeTitle).bold()
              .foregroundColor(.white)
              .padding(.top, 40)

            Group {
              TextField("Full Name", text: $fullName)
              TextField("Email",     text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

              SecureField("Password",        text: $password)
              SecureField("Confirm Password",text: $confirmPassword)
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(.white)
            .padding(.horizontal, 32)

            Button {
              handleSignUp()
            } label: {
              Text("Sign Up")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .foregroundColor(Color("PrimaryGradientStart"))
            }
            .padding(.horizontal, 32)
            .alert("Sign Up Error", isPresented: $showingAlert) {
              Button("OK", role: .cancel) { }
            } message: {
              Text(alertMessage)
            }

            Spacer()
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Back", action: onBack)
            .foregroundColor(.white)
        }
      }
    }
  }

  private func handleSignUp() {
    guard !fullName.isEmpty else {
      alertMessage = "Enter your name"; showingAlert = true; return
    }
    guard email.contains("@") else {
      alertMessage = "Invalid email"; showingAlert = true; return
    }
    guard password.count >= 6 else {
      alertMessage = "Password ≥ 6 chars"; showingAlert = true; return
    }
    guard password == confirmPassword else {
      alertMessage = "Passwords don’t match"; showingAlert = true; return
    }

    AuthService.signUp(email: email, password: password) { res in
      switch res {
      case .success:
        onSignUpComplete()
      case .failure(let e):
        alertMessage = e.localizedDescription
        showingAlert = true
      }
    }
  }
}
