import SwiftUI

/// Login / Sign-Up akışını yöneten ara katman
struct AuthFlowView: View {
  let onLoginComplete:   () -> Void
  let onSignUpComplete:  () -> Void
  let onBack: (() -> Void)?

  @State private var showingLogin = true

  init(onLoginComplete: @escaping () -> Void, onSignUpComplete: @escaping () -> Void, onBack: (() -> Void)? = nil) {
    self.onLoginComplete = onLoginComplete
    self.onSignUpComplete = onSignUpComplete
    self.onBack = onBack
  }

  var body: some View {
    NavigationView {
      ZStack {
        EnhancedGradientBackground()
        
        if showingLogin {
          LoginView(
            onLoginComplete: onLoginComplete,
            onSignUpTap: {
              withAnimation(.easeInOut(duration: 0.3)) {
                showingLogin = false
              }
            },
            onBack: onBack
          )
        } else {
          SignUpView(
            onSignUpComplete: onSignUpComplete,
            onLoginTap: {
              withAnimation(.easeInOut(duration: 0.3)) {
                showingLogin = true
              }
            }
          )
        }
      }
      .navigationBarHidden(true)
    }
    .navigationViewStyle(.stack)
  }
}
