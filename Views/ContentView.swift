// Views/ContentView.swift
import SwiftUI
import FirebaseCore        // FirebaseApp.configure() için
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanız

// 1️⃣ Uygulama genelinde kullanılacak enum’lar
enum Tab {
  case home, stats, messages, profile
}
enum OnboardingStep {
  case splash, features, terms, auth, verify, home
}

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
            // yeni kullanıcı kaydı sonrası zorunlu e-posta doğrulama
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
          onLogout:    {
            // çıkış yapıp tekrar auth akışına dön
            step = .auth
          }
        )
      }
    }
    .animation(.easeInOut, value: step)
  }
}
