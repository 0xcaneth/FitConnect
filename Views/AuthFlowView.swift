import SwiftUI
import Firebase           // Use the unified Firebase module
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanız

/// Login / Sign-Up akışını yöneten ara katman
struct AuthFlowView: View {
  let onLoginComplete:   () -> Void
  let onSignUpComplete:  () -> Void

  @State private var showingLogin = true

  var body: some View {
    NavigationStack {
      if showingLogin {
        LoginView(
          onLoginComplete: {    
            onLoginComplete()
          },
          onSignUpTap: {
            showingLogin = false
          }
        )
        .navigationBarHidden(true)
      } else {
        SignUpView(
          onSignUpComplete: {
            onSignUpComplete()
          },
          onBack: {
            showingLogin = true
          }
        )
        .navigationBarHidden(true)
      }
    }
  }
}
