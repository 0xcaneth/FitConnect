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
                // Main app with tab structure
                MainTabView()
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
                TermsConditionsView(
                    onContinue: {
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

@available(iOS 16.0, *)
struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            // Feed Tab
            NavigationView {
                VStack {
                    Text("Feed")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0D0F14"))
                .navigationTitle("Feed")
                .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                Text("Feed")
            }
            .tag(1)
            
            // Challenges Tab
            NavigationView {
                VStack {
                    Text("Challenges")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0D0F14"))
                .navigationTitle("Challenges")
                .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "trophy.fill" : "trophy")
                Text("Challenges")
            }
            .tag(2)
            
            // Profile Tab
            NavigationView {
                VStack {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Coming Soon")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#0D0F14"))
                .navigationTitle("Profile")
                .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(3)
        }
        .accentColor(Color(hex: "#7C4DFF"))
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0D0F14"))
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#CCCCCC"))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#CCCCCC"))
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#7C4DFF"))
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color(hex: "#7C4DFF"))
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
