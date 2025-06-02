import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var selectedTab: Int = 0

    private enum Tab: Int {
        case home = 0
        case feed = 1
        case challenges = 2
        case profile = 3
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ClientHomeView()
                .environmentObject(session)
                .environmentObject(healthKitManager)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(Tab.home.rawValue)
                .opacity(selectedTab == Tab.home.rawValue ? 1 : 0.8) // Fade slightly when not selected
                .animation(.easeInOut(duration: 0.3), value: selectedTab)


            // Community Feed Tab
            FeedView()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "quote.bubble.fill")
                    Text("Feed")
                }
                .tag(Tab.feed.rawValue)
                .opacity(selectedTab == Tab.feed.rawValue ? 1 : 0.8)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)

            // Challenges Tab
            ChallengesView()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "trophy.fill")
                    Text("Challenges")
                }
                .tag(Tab.challenges.rawValue)
                .opacity(selectedTab == Tab.challenges.rawValue ? 1 : 0.8)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // Profile Tab
            ProfileView()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(Tab.profile.rawValue)
                .opacity(selectedTab == Tab.profile.rawValue ? 1 : 0.8)
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
        }
        .accentColor(Color(hex: "#6E56E9"))
        .onAppear {
            // Configure tab bar appearance (existing code remains)
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color(hex: "#1E1F25"))
            
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color(hex: "#8A8F9B"))
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "#8A8F9B"))
            ]
            
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color(hex: "#6E56E9"))
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Color(hex: "#6E56E9"))
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(SessionStore.previewStore())
            .environmentObject(HealthKitManager())
            .preferredColorScheme(.dark)
    }
}
#endif
