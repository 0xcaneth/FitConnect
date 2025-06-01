import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @State private var step: OnboardingStep = .splash

    @ViewBuilder
    private var currentView: some View {
        switch step {
        case .splash:
            AnyView(SplashView {
                if session.isLoggedIn && session.currentUser?.isEmailVerified == true {
                    step = .home
                } else if session.currentUser != nil && session.currentUser!.isEmailVerified == false {
                    step = .verify
                } else {
                    step = .privacy
                }
            })
        case .features:
            AnyView(PrivacyAnalyticsView(
                onContinue: { step = .terms },
                onSkip: { step = .terms }
            ))
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
                    if session.currentUser?.isEmailVerified == true {
                        step = .home
                    } else {
                        step = .verify
                    }
                },
                onSignUpComplete: {
                    step = .verify
                },
                onBack: { step = .terms }
            ))
        case .verify:
            AnyView(EmailVerificationView(
                onVerified: { step = .home },
                onBack: {
                    try? session.signOut()
                    step = .auth
                }
            ))
        case .home:
            if session.role == "dietitian" {
                NavigationView {
                    DietitianDashboardView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.opacity)
            } else {
                NavigationView {
                    ClientHomeView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.opacity)
            }
        }
    }

    var body: some View {
        currentView
            .transition(.asymmetric(insertion: .opacity, removal: .opacity))
            .animation(.easeInOut(duration: 0.3), value: step)
            .onReceive(session.$isLoggedIn) { isLoggedIn in
                if !isLoggedIn && (step == .home || step == .verify) {
                    step = .auth
                } else if isLoggedIn && session.currentUser?.isEmailVerified == true && (step == .auth || step == .verify) {
                    step = .home
                } else if isLoggedIn && session.currentUser?.isEmailVerified == false && step == .auth {
                    step = .verify
                }
            }
    }
}
