import SwiftUI

@available(iOS 16.0, *)
struct DietitianHomeTabView: View {
    var body: some View {
        TabView {
            DietitianDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
            
            ClientsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Clients")
                }
            
            DietitianMessagesListView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Messages")
                }
            
            DietitianScheduleView()
                .tabItem {
                    Image(systemName: "calendar.circle.fill")
                    Text("Appointments")
                }
            
            DietitianProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
        .accentColor(.purple)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.darkBackground)
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.white.opacity(0.6))
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.white.opacity(0.6))
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.purple)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.purple)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianHomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianHomeTabView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif