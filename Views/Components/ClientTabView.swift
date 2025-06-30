import SwiftUI

@available(iOS 16.0, *)
struct ClientTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var postService = PostService.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ClientHomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 20))
                    Text("Home")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tag(0)
            
            ClientChatView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "message.fill" : "message")
                        .font(.system(size: 20))
                    Text("Messages")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tag(1)
            
            // Feed Tab - CHANGE: Use new premium FeedView
            FeedView()
                .environmentObject(postService) 
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "text.bubble.fill" : "text.bubble")
                        .font(.system(size: 20))
                    Text("Feed")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tag(2)
            
            // Challenges Tab
            ChallengesView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "rosette" : "rosette")
                        .font(.system(size: 20))
                    Text("Challenges")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                        .font(.system(size: 20))
                    Text("Profile")
                        .font(.system(size: 12, weight: .semibold))
                }
                .tag(4)
        }
        .accentColor(Color(hex: "#8E24AA"))
        .preferredColorScheme(.dark)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.071, green: 0.071, blue: 0.078, alpha: 1.0) // #121212
            
            // Selected state
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(red: 0.557, green: 0.141, blue: 0.667, alpha: 1.0) // #8E24AA
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.557, green: 0.141, blue: 0.667, alpha: 1.0)
            ]
            
            // Normal state
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(red: 0.467, green: 0.467, blue: 0.467, alpha: 1.0) // #777777
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(red: 0.467, green: 0.467, blue: 0.467, alpha: 1.0)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            postService.configure(sessionStore: session)
        }
    }
}