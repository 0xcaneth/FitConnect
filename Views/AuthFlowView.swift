// Views/AuthFlowView.swift
import SwiftUI

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
