import SwiftUI

@available(iOS 16.0, *)
struct SocialFeedView: View {
    @EnvironmentObject private var postService: PostService
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var healthKitManager: HealthKitManager
    @State private var showingCreatePostView = false
    @State private var isRefreshing = false
    @State private var scrollOffset: CGFloat = 0

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#0D0F14"))
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#101218"), Color(hex: "#0B0D12")]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                if postService.posts.isEmpty && !isRefreshing {
                    emptyFeedView()
                } else if session.currentUserId == nil {
                    VStack {
                        Text("Please log in to see the feed.")
                            .foregroundColor(.white)
                    }
                } else if postService.posts.isEmpty && isRefreshing {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading posts...")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(postService.posts.enumerated()), id: \.element.id) { index, post in
                                    NavigationLink(value: post) {
                                        PostCellView(post: post)
                                            .transition(.asymmetric(
                                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)).combined(with: .move(edge: .top)),
                                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .center)).combined(with: .move(edge: .bottom))
                                            ))
                                            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: postService.posts)
                                            .id("post-\(index)")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geometry.frame(in: .named("scroll")).minY
                                    )
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            withAnimation(.easeOut(duration: 0.3)) {
                                scrollOffset = value
                            }
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                    }
                }
            }
            .navigationTitle("Community Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePostView = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#6E56E9"))
                            .scaleEffect(scrollOffset > 0 ? 1.1 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrollOffset)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingCreatePostView) {
            CreatePostView()
                .environmentObject(session)
                .environmentObject(postService)
                .environmentObject(healthKitManager)
        }
        .onAppear {
            print("[SocialFeedView] onAppear - configuring PostService")
            postService.configure(sessionStore: session)
            
            if healthKitManager.authorizationStatus == .notDetermined {
                Task {
                    await healthKitManager.requestAuthorization()
                }
            }
        }
    }
    
    @ViewBuilder
    private func emptyFeedView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "#6E56E9"))
            Text("No Posts Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("Be the first to share your progress!")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
                .multilineTextAlignment(.center)
            Button("Create First Post") {
                showingCreatePostView = true
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
        }
    }
    
    @MainActor
    private func refreshFeed() async {
        print("[SocialFeedView] Pull-to-refresh triggered")
        isRefreshing = true
        
        postService.stopListening()
        try? await Task.sleep(nanoseconds: 500_000_000)
        postService.configure(sessionStore: session)
        
        if healthKitManager.authorizationStatus == .sharingAuthorized {
            // No need to call fetchAllTodayData - it's called automatically in HealthKitManager
        }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SocialFeedView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Create a mock SessionStore
        let mockSession = SessionStore.previewStore(isLoggedIn: true, unreadNotifications: 3)
        
        // 2. Configure the shared PostService instance
        let postService = PostService.shared 
        postService.configure(sessionStore: mockSession) 
        
        // 3. Create HealthKitManager with the mock SessionStore
        let healthKitManager = HealthKitManager(sessionStore: mockSession)
        
        // Set some mock data for preview purposes
        healthKitManager.activeEnergyBurned = 350
        healthKitManager.stepCount = 5280
        healthKitManager.waterIntake = 1.2
        // healthKitManager.isAuthorized = true
        // healthKitManager.permissionStatusDetermined = true

        return SocialFeedView()
            .environmentObject(postService)
            .environmentObject(mockSession)
            .environmentObject(healthKitManager)
            .preferredColorScheme(.dark)
    }
}
#endif