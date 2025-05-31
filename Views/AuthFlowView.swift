import SwiftUI
import Firebase           // Use the unified Firebase module
import FirebaseAuth        // Auth işlemleri için

/// Login / Sign-Up akışını yöneten ara katman
struct AuthFlowView: View {
  let onLoginComplete:   () -> Void
  let onSignUpComplete:  () -> Void

  @State private var showingLogin = true

  var body: some View {
    Group {
      if #available(iOS 16.0, *) {
        NavigationStack {
          content
        }
      } else {
        NavigationView {
          content
        }
        .navigationViewStyle(.stack) // Use stack style for consistency
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    ZStack {
      // Unified Background
      UnifiedBackground()
      
      if showingLogin {
        LoginView(
          onLoginComplete: onLoginComplete,
          onSignUpTap: {
            withAnimation(.easeInOut(duration: 0.3)) {
              showingLogin = false
            }
          }
        )
      } else {
        SignUpView(
          onSignUpComplete: onSignUpComplete,
          onBack: {
            withAnimation(.easeInOut(duration: 0.3)) {
              showingLogin = true
            }
          }
        )
      }
    }
    .navigationBarHidden(true)
  }
}
