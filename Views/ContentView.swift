// Views/ContentView.swift
import SwiftUI
import FirebaseAuth

/// Uygulamanın tüm akış adımlarını yöneten ana view
struct ContentView: View {
  @EnvironmentObject var session: SessionStore
  @State private var step: OnboardingStep = .splash
  @State private var selectedTab: Tab = .home

  var body: some View {
    Group {
      switch step {
      case .splash:
        SplashView {
          step = .features
        }

      case .features:
        FeaturesView {
          step = .terms
        }

      case .terms:
        TermsView(
          onAccept: { step = .auth },
          onBack:   { step = .features }
        )

      case .auth:
        AuthFlowView(
          onLoginComplete: {
            guard let u = Auth.auth().currentUser else { return }
            u.reload { _ in
              step = u.isEmailVerified ? .home : .verify
            }
          },
          onSignUpComplete: {
            step = .verify
          }
        )

      case .verify:
        EmailVerificationView(
          onVerified: { step = .home },
          onBack:     { step = .auth }
        )

      case .home:
        HomeView(
          selectedTab: $selectedTab,
          userName:    session.currentUser?.displayName
                       ?? session.currentUser?.email
                       ?? "User",
          onLogout: {
            try? Auth.auth().signOut()
            step = .auth
          }
        )
      }
    }
    .animation(.easeInOut, value: step)
  }
}

// MARK: — Flow & Tab Enums

enum OnboardingStep {
  case splash, features, terms, auth, verify, home
}

enum Tab {
  case home, stats, messages, profile
}
