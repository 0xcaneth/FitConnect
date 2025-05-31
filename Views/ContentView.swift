import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @State private var step: OnboardingStep = .splash
    @State private var selectedTab: AppTab = .home

    @ViewBuilder
    private var currentView: some View {
        switch step {
        case .splash:
            AnyView(SplashView {
                step = .features
            })
        case .features:
            AnyView(FeaturesView {
                step = .privacy
            })
        case .privacy:
            AnyView(PrivacyAnalyticsView(
                onContinue: { step = .terms },
                onSkip: { step = .terms }
            ))
        case .terms:
            AnyView(TermsView(
                onAccept: { step = .auth },
                onBack: { step = .privacy }
            ))
        case .auth:
            AnyView(AuthFlowView(
                onLoginComplete: {
                    guard let u = Auth.auth().currentUser else { return }
                    u.reload { _ in
                        step = u.isEmailVerified ? .home : .verify
                    }
                },
                onSignUpComplete: {
                    step = .verify
                }
            ))
        case .verify:
            AnyView(EmailVerificationView(
                onVerified: { step = .home },
                onBack: { step = .auth }
            ))
        case .home:
            AnyView(HomeDashboardView(
                selectedTab: $selectedTab,
                onLogout: {
                    do {
                        try session.signOut()
                        step = .auth
                    } catch {
                        print("Sign out error: \(error)")
                        step = .auth
                    }
                }
            ))
        }
    }

    var body: some View {
        currentView
            .animation(.easeInOut(duration: 0.3), value: step)
    }
}
