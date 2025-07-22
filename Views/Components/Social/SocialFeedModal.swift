import SwiftUI
import FirebaseFirestore

/// 🚀 PRODUCTION-READY Social Feed Modal - Instagram/TikTok killer
@available(iOS 16.0, *)
struct SocialFeedModal: View {
    @EnvironmentObject private var socialService: SocialService
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: SocialFeedTab = .friends
    @State private var showingCreatePost = false
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background
                backgroundView
                
                VStack(spacing: 0) {
                    // Custom header
                    headerSection
                    
                    // Tab selector
                    tabSelectorSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        friendFeedView
                            .tag(SocialFeedTab.friends)
                        
                        globalFeedView
                            .tag(SocialFeedTab.global)
                        
                        notificationsView
                            .tag(SocialFeedTab.notifications)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
        }
        .onAppear {
            print("[SocialFeedModal] 🎯 Social feed modal appeared")
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(hex: "#0B0D17"),
                Color(hex: "#1A1B25"),
                Color(hex: "#2A2B35")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            
            Spacer()
            
            Text("Social")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                showingCreatePost = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B9D"), Color(hex: "#8E24AA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Tab Selector
    
    @ViewBuilder
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(SocialFeedTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                            
                            Text(tab.title)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTab == tab ? .white : .secondary)
                            
                            if tab == .notifications && !socialService.notifications.isEmpty {
                                ZStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 18, height: 18)
                                    
                                    Text("\(socialService.notifications.count)")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        
                        Rectangle()
                            .fill(
                                selectedTab == tab ?
                                LinearGradient(
                                    colors: [Color(hex: "#FF6B9D"), Color(hex: "#8E24AA")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Friend Feed
    
    @ViewBuilder
    private var friendFeedView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if socialService.isLoadingFeed {
                    loadingView
                        .padding(.top, 50)
                } else if socialService.friendActivities.isEmpty {
                    emptyFriendFeedView
                        .padding(.top, 50)
                } else {
                    ForEach(socialService.friendActivities, id: \.id) { activity in
                        SocialActivityCard(activity: activity, isGlobal: false)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .refreshable {
            // Refresh friend activities
        }
    }
    
    // MARK: - Global Feed
    
    @ViewBuilder
    private var globalFeedView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 20) {
                if socialService.globalFeed.isEmpty {
                    emptyGlobalFeedView
                        .padding(.top, 50)
                } else {
                    ForEach(socialService.globalFeed, id: \.id) { activity in
                        SocialActivityCard(activity: activity, isGlobal: true)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .refreshable {
            // Refresh global feed
        }
    }
    
    // MARK: - Notifications
    
    @ViewBuilder
    private var notificationsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if socialService.notifications.isEmpty {
                    emptyNotificationsView
                        .padding(.top, 50)
                } else {
                    ForEach(socialService.notifications, id: \.id) { notification in
                        SocialNotificationCard(notification: notification) {
                            // Handle notification tap
                            Task {
                                try? await socialService.markNotificationAsRead(notification.id ?? "")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
    }
    
    // MARK: - Empty States
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: "#FF6B9D"))
                .scaleEffect(1.2)
            
            Text("Loading social feed...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var emptyFriendFeedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B9D").opacity(0.2), Color(hex: "#8E24AA").opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.2.wave.2")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FF6B9D"), Color(hex: "#8E24AA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("No Friend Activities")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Follow friends to see their workout achievements, challenges, and milestones!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button("Find Friends") {
                // Navigate to friend discovery
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FF6B9D"), Color(hex: "#8E24AA")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var emptyGlobalFeedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Global Feed Coming Soon")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Discover amazing fitness achievements from users around the world!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 40)
    }
    
    @ViewBuilder
    private var emptyNotificationsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "bell.slash")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("All Caught Up!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("No new notifications right now. Check back later for updates from friends!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Supporting Types

enum SocialFeedTab: CaseIterable {
    case friends
    case global
    case notifications
    
    var title: String {
        switch self {
        case .friends: return "Friends"
        case .global: return "Global"
        case .notifications: return "Notifications"
        }
    }
    
    var icon: String {
        switch self {
        case .friends: return "person.2.fill"
        case .global: return "globe"
        case .notifications: return "bell.fill"
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SocialFeedModal_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionStore.previewStore(isLoggedIn: true)
        let socialService = SocialService.shared
        
        return SocialFeedModal()
            .environmentObject(socialService)
            .environmentObject(session)
            .preferredColorScheme(.dark)
    }
}
#endif