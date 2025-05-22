// Views/EmailVerificationView.swift
import SwiftUI
import FirebaseCore        // FirebaseApp.configure() için
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanız

struct EmailVerificationView: View {
  let onVerified: () -> Void
  let onBack:     () -> Void

  @State private var isVerifying   = false
  @State private var showingAlert  = false
  @State private var alertMessage  = ""

  var body: some View {
    NavigationStack {
      ZStack {
        LinearGradient(
          colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 24) {
          Spacer()

          Text("Verify Your Email")
            .font(.largeTitle).bold()
            .foregroundColor(.white)

          Text("Please check your inbox and click the verification link.")
            .multilineTextAlignment(.center)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 32)

          Button {
            verifyNow()
          } label: {
            if isVerifying {
              ProgressView().tint(.white)
            } else {
              Text("Check Verification")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(Color("PrimaryGradientStart"))
                .cornerRadius(10)
            }
          }
          .disabled(isVerifying)
          .padding(.horizontal, 32)

          Spacer()
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Back", action: onBack).foregroundColor(.white)
        }
      }
      .alert("Error", isPresented: $showingAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(alertMessage)
      }
    }
  }

  private func verifyNow() {
    isVerifying = true
    AuthService.verifyEmail { result in
      isVerifying = false
      switch result {
      case .success:
        onVerified()
      case .failure(let err):
        alertMessage = err.localizedDescription
        showingAlert = true
      }
    }
  }
}
