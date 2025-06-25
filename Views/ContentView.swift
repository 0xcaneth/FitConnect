import SwiftUI
import Firebase
import FirebaseAuth

@available(iOS 16.0, *)
struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postService: PostService
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showingSplash = true
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        ZStack {
            if showingSplash {
                SplashView(onContinue: {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showingSplash = false
                    }
                })
                .transition(.opacity.combined(with: .scale))
            } else if !hasSeenOnboarding {
                ContentOnboardingFlowView {
                    hasSeenOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !session.isLoggedIn {
                AuthFlowView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                // Main app routing is now handled by RootView
                RootView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showingSplash)
        .animation(.easeInOut(duration: 0.6), value: hasSeenOnboarding)
        .animation(.easeInOut(duration: 0.6), value: session.isLoggedIn)
        .onReceive(session.$isLoggedIn) { isLoggedIn in
            print("[ContentView] User login state changed: \(isLoggedIn)")
        }
    }
}

@available(iOS 16.0, *)
struct ContentOnboardingFlowView: View {
    let onComplete: () -> Void
    @State private var currentStep: OnboardingStep = .privacy
    
    var body: some View {
        ZStack {
            switch currentStep {
            case .privacy:
                PrivacyAnalyticsView(
                    onContinue: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentStep = .terms
                        }
                    },
                    onSkip: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentStep = .terms
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                
            case .terms:
                SimpleTermsView(
                    onAccept: {
                        onComplete()
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentStep = .privacy
                        }
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                
            default:
                // For any other cases, just complete
                Color.clear
                    .onAppear {
                        onComplete()
                    }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: false))
            .environmentObject(HealthKitManager(sessionStore: SessionStore.previewStore()))
            .environmentObject(PostService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
