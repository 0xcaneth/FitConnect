import SwiftUI

@available(iOS 16.0, *)
struct DietitianTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            VStack {
                Text("Dashboard")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundDark)
            .tabItem {
                Image(systemName: "house")
                Text("Dashboard")
            }
            .tag(0)
            
            // Clients Tab - TEMP: Using placeholder until DietitianClientsView is resolved
            VStack {
                Text("Clients")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundDark)
            .tabItem {
                Image(systemName: "person.2")
                Text("Clients")
            }
            .tag(1)
            
            // Messages Tab
            DietitianMessagesListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
                }
                .tag(2)
            
            // Appointments Tab
            AppointmentListView()
                .environmentObject(session)
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Appointments")
                }
                .tag(3)
            
            // Feed Tab - moved to tag 4
            VStack {
                Text("Feed")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundDark)
            .tabItem {
                Image(systemName: "heart.text.square")
                Text("Feed")
            }
            .tag(4)
            
            // Challenges Tab - moved to tag 5
            VStack {
                Text("Challenges")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.backgroundDark)
            .tabItem {
                Image(systemName: "trophy")
                Text("Challenges")
            }
            .tag(5)
            
            // Profile Tab - moved to tag 6
            DietitianProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(6)
        }
        .accentColor(Color(hex: "#6E56E9"))
        .background(Color.backgroundDark)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.backgroundDark)
            
            // Unselected tab items
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor.white
            ]
            
            // Selected tab items - using the correct purple highlight color
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
@available(iOS 16.0, *)
struct DietitianTabView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianTabView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif