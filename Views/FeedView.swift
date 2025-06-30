import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct FeedView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postService: PostService
    @State private var showingCreatePost: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var selectedPostIndex: Int? = nil
    @State private var cardAnimationTrigger = false
    @State private var hasAppearedOnce = false
    
    // Advanced visual effects
    @State private var backgroundParticleOffset: CGFloat = 0
    @State private var gradientAnimation: Double = 0
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium Dynamic Background
                premiumBackgroundView
                
                if postService.posts.isEmpty && !isRefreshing {
                    premiumEmptyFeedView
                } else if session.currentUserId == nil {
                    premiumLoginPromptView
                } else if postService.posts.isEmpty && isRefreshing {
                    premiumLoadingView
                } else {
                    premiumFeedContentView
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    premiumCreatePostButton
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(session)
                    .environmentObject(postService)
            }
            .onAppear {
                if !hasAppearedOnce {
                    hasAppearedOnce = true
                    startBackgroundAnimations()
                    triggerInitialCardAnimations()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Premium Background System
    @ViewBuilder
    private var premiumBackgroundView: some View {
        ZStack {
            // Base gradient with smooth animation
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.03, green: 0.04, blue: 0.06), location: 0.0),
                    .init(color: Color(red: 0.06, green: 0.07, blue: 0.10), location: 0.3),
                    .init(color: Color(red: 0.04, green: 0.05, blue: 0.08), location: 0.7),
                    .init(color: Color(red: 0.02, green: 0.03, blue: 0.05), location: 1.0)
                ]),
                startPoint: UnitPoint(x: 0.0, y: 0.0 + gradientAnimation * 0.1),
                endPoint: UnitPoint(x: 1.0, y: 1.0 + gradientAnimation * 0.1)
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: gradientAnimation)
            
            // Floating particles system
            ForEach(0..<15, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.1),
                                Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...80), height: CGFloat.random(in: 20...80))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height) + backgroundParticleOffset
                    )
                    .blur(radius: CGFloat.random(in: 15...35))
                    .animation(
                        .linear(duration: Double.random(in: 20...40))
                        .repeatForever(autoreverses: false),
                        value: backgroundParticleOffset
                    )
            }
            
            // Ambient glow effects
            RadialGradient(
                colors: [
                    Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.03),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.02),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Premium Create Post Button
    @ViewBuilder
    private var premiumCreatePostButton: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showingCreatePost = true
            }
        }) {
            ZStack {
                // Main button background with sophisticated gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91),
                                Color(red: 0.58, green: 0.20, blue: 0.92),
                                Color(red: 0.43, green: 0.34, blue: 0.91)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 32)
                
                // Animated border glow
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.8),
                                Color.white.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 52, height: 32)
                    .blur(radius: 1)
                
                // Premium icon with subtle shadow
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                // Subtle inner highlight
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: 52, height: 32)
                    .allowsHitTesting(false)
            }
            .shadow(
                color: Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(scrollOffset > 0 ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrollOffset)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Premium Feed Content
    @ViewBuilder
    private var premiumFeedContentView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Dynamic header with user stats
                    if !isRefreshing {
                        premiumFeedHeaderView
                            .padding(.top, 10)
                    }
                    
                    // Post cards with advanced animations
                    ForEach(Array(postService.posts.enumerated()), id: \.element.id) { index, post in
                        PremiumFeedPostCard(
                            post: post,
                            index: index,
                            isVisible: selectedPostIndex == nil || selectedPostIndex == index,
                            animationTrigger: cardAnimationTrigger
                        )
                        .environmentObject(session)
                        .environmentObject(postService)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom))
                        ))
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: cardAnimationTrigger
                        )
                        .id(post.id ?? "fallback-\(index)")
                        .onTapGesture {
                            selectedPostIndex = selectedPostIndex == index ? nil : index
                        }
                    }
                    
                    // Bottom spacing for tab bar
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await performPremiumRefresh()
            }
        }
    }
    
    // MARK: - Premium Feed Header
    @ViewBuilder
    private var premiumFeedHeaderView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Community stats
                VStack(spacing: 4) {
                    Text("\(postService.posts.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.34, blue: 0.91),
                                    Color(red: 0.00, green: 0.83, blue: 1.00)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Community Posts")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 40)
                
                // Active users indicator
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(cardAnimationTrigger ? 1.2 : 0.8)
                            .animation(.easeInOut(duration: 1).repeatForever(), value: cardAnimationTrigger)
                        
                        Text("Live")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    
                    Text("Community Active")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Premium Empty Feed View
    @ViewBuilder
    private var premiumEmptyFeedView: some View {
        VStack(spacing: 30) {
            // Animated icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.2),
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(hasAppearedOnce ? 1.0 : 0.8)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: hasAppearedOnce)
                
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91),
                                Color(red: 0.00, green: 0.83, blue: 1.00)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(hasAppearedOnce ? 1.0 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: hasAppearedOnce)
            }
            
            VStack(spacing: 16) {
                Text("Start Your Journey")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(hasAppearedOnce ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: hasAppearedOnce)
                
                Text("Be the first to share your fitness achievements,\nmotivate others, and build our community!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(hasAppearedOnce ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: hasAppearedOnce)
            }
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingCreatePost = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Create First Post")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.34, blue: 0.91),
                                    Color(red: 0.00, green: 0.83, blue: 1.00)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.4),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                )
                .scaleEffect(hasAppearedOnce ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: hasAppearedOnce)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Premium Loading View
    @ViewBuilder
    private var premiumLoadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.8 - Double(index) * 0.2),
                                    Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.8 - Double(index) * 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                        .rotationEffect(.degrees(gradientAnimation * (1 + Double(index))))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: gradientAnimation)
                }
            }
            
            VStack(spacing: 8) {
                Text("Loading Community...")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Fetching the latest posts and activities")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    // MARK: - Premium Login Prompt
    @ViewBuilder
    private var premiumLoginPromptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.34, blue: 0.91),
                            Color(red: 0.00, green: 0.83, blue: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("Join Our Community")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Sign in to connect with fellow fitness enthusiasts,\nshare your progress, and get motivated!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Animation Functions
    private func startBackgroundAnimations() {
        withAnimation(.linear(duration: 0.1)) {
            backgroundParticleOffset = -UIScreen.main.bounds.height * 2
            gradientAnimation = 1.0
        }
    }
    
    private func triggerInitialCardAnimations() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                cardAnimationTrigger = true
            }
        }
    }
    
    @MainActor
    private func performPremiumRefresh() async {
        print("[FeedView] Premium pull-to-refresh triggered")
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isRefreshing = true
        
        // Advanced refresh animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            cardAnimationTrigger.toggle()
        }
        
        // Simulate network refresh
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        // Refresh posts
        postService.stopListening()
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Success feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        isRefreshing = false
    }
}

// MARK: - Premium Feed Post Card
@available(iOS 16.0, *)
struct PremiumFeedPostCard: View {
    let post: Post
    let index: Int
    let isVisible: Bool
    let animationTrigger: Bool
    
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postService: PostService
    
    @State private var isLiked: Bool = false
    @State private var localLikesCount: Int
    @State private var localCommentsCount: Int
    @State private var showingComments: Bool = false
    @State private var likeAnimationScale: CGFloat = 1.0
    @State private var cardHoverScale: CGFloat = 1.0
    @State private var likeParticles: [LikeParticle] = []
    @State private var showingFullContent = false
    
    init(post: Post, index: Int, isVisible: Bool, animationTrigger: Bool) {
        self.post = post
        self.index = index
        self.isVisible = isVisible
        self.animationTrigger = animationTrigger
        self._localLikesCount = State(initialValue: post.likesCount)
        self._localCommentsCount = State(initialValue: post.commentsCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Premium header
            premiumPostHeader
                .padding(.horizontal, 20)
                .padding(.top, 20)
            
            // Content area
            premiumPostContent
                .padding(.horizontal, 20)
                .padding(.top, 16)
            
            // Action bar
            premiumActionBar
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        }
        .background(premiumCardBackground)
        .scaleEffect(cardHoverScale)
        .opacity(isVisible ? 1.0 : 0.7)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showingFullContent.toggle()
            }
        }
        .onAppear {
            setupLikeState()
            localLikesCount = post.likesCount
            localCommentsCount = post.commentsCount
        }
        .onChange(of: post.likesCount) { newValue in
            localLikesCount = newValue
        }
        .onChange(of: post.commentsCount) { newValue in
            localCommentsCount = newValue
        }
        .overlay(alignment: .topTrailing) {
            // Like particles overlay
            ForEach(likeParticles, id: \.id) { particle in
                Image(systemName: "heart.fill")
                    .font(.system(size: particle.size))
                    .foregroundColor(.red.opacity(particle.opacity))
                    .position(particle.position)
                    .scaleEffect(particle.scale)
            }
        }
        .sheet(isPresented: $showingComments) {
            PostDetailView(post: post)
                .environmentObject(session)
                .environmentObject(postService)
        }
    }
    
    // MARK: - Premium Card Background
    @ViewBuilder
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.08), location: 0.0),
                        .init(color: Color.white.opacity(0.04), location: 0.5),
                        .init(color: Color.white.opacity(0.02), location: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorForPostType(post.type).opacity(0.3),
                                Color.white.opacity(0.1),
                                colorForPostType(post.type).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: colorForPostType(post.type).opacity(0.1),
                radius: 20,
                x: 0,
                y: 10
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 10,
                x: 0,
                y: 5
            )
    }
    
    // MARK: - Premium Post Header
    @ViewBuilder
    private var premiumPostHeader: some View {
        HStack(spacing: 12) {
            // Enhanced avatar with status ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                colorForPostType(post.type),
                                colorForPostType(post.type).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: colorForPostType(post.type).opacity(0.3), radius: 8, x: 0, y: 4)
                
                AsyncImage(url: URL(string: post.authorAvatarURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(colorForPostType(post.type).opacity(0.2))
                            .frame(width: 46, height: 46)
                            .overlay(
                                ProgressView()
                                    .tint(colorForPostType(post.type))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(colorForPostType(post.type).opacity(0.3))
                            .frame(width: 46, height: 46)
                            .overlay(
                                Text(String(post.authorName.prefix(1)).uppercased())
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.authorName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(formatTimestamp(post.createdAt))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let category = post.category {
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(category)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(colorForPostType(post.type))
                    }
                }
            }
            
            Spacer()
            
            // Premium post type indicator
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorForPostType(post.type).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconNameForPostType(post.type))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(colorForPostType(post.type))
                    .shadow(color: colorForPostType(post.type).opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Premium Post Content
    @ViewBuilder
    private var premiumPostContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch post.type {
            case .badge:
                premiumBadgeContent
            case .achievement:
                premiumAchievementContent
            case .motivation:
                premiumMotivationContent
            }
            
            // Image content if available
            if let urlString = post.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 200)
                            .overlay(
                                ProgressView()
                                    .tint(colorForPostType(post.type))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 250)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red.opacity(0.6))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Content Type Views
    @ViewBuilder
    private var premiumBadgeContent: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                colorForPostType(post.type).opacity(0.3),
                                colorForPostType(post.type).opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                colorForPostType(post.type),
                                colorForPostType(post.type).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: colorForPostType(post.type).opacity(0.4), radius: 6, x: 0, y: 3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Badge Unlocked!")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(colorForPostType(post.type))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(post.badgeName ?? "Achievement Badge")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(showingFullContent ? nil : 2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var premiumAchievementContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    colorForPostType(post.type).opacity(0.3),
                                    colorForPostType(post.type).opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    colorForPostType(post.type),
                                    colorForPostType(post.type).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: colorForPostType(post.type).opacity(0.4), radius: 6, x: 0, y: 3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(colorForPostType(post.type))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    if let achievementName = post.achievementName {
                        Text(achievementName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(showingFullContent ? nil : 1)
                    }
                }
                
                Spacer()
            }
            
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(showingFullContent ? nil : 3)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var premiumMotivationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(colorForPostType(post.type).opacity(0.6))
                
                Text("Daily Motivation")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(colorForPostType(post.type))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Text(post.content ?? "")
                .font(.system(size: 18, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.white)
                .lineLimit(showingFullContent ? nil : 4)
                .lineSpacing(4)
                .padding(.horizontal, 4)
            
            HStack {
                Spacer()
                Text("— \(post.authorName)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorForPostType(post.type).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorForPostType(post.type).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Premium Action Bar
    @ViewBuilder
    private var premiumActionBar: some View {
        HStack(spacing: 24) {
            // Enhanced like button
            Button(action: {
                performLikeAction()
            }) {
                HStack(spacing: 8) {
                    ZStack {
                        if isLiked {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.red, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .scaleEffect(likeAnimationScale)
                                .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                        } else {
                            Image(systemName: "heart")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text("\(localLikesCount)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(isLiked ? .red : .white.opacity(0.7))
                        .contentTransition(.numericText())
                }
            }
            .buttonStyle(.plain)
            
            // Enhanced comment button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showingComments = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(localCommentsCount)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .contentTransition(.numericText())
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Premium interaction indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(colorForPostType(post.type))
                    .frame(width: 6, height: 6)
                    .opacity(0.7)
                
                Text("\(localLikesCount + localCommentsCount) interactions")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
    
    // MARK: - Helper Functions
    private func performLikeAction() {
        guard let currentUserId = session.currentUserId, let postId = post.id else { 
            print("[PremiumFeedPostCard] ❌ Like action failed: Missing user ID or post ID")
            return 
        }
        
        print("[PremiumFeedPostCard] 🎯 Like action started for post \(postId) by user \(currentUserId)")
        print("[PremiumFeedPostCard] Current like state: \(isLiked), likes count: \(localLikesCount)")
        
        // Immediate UI feedback
        let wasLiked = isLiked
        let originalLikesCount = localLikesCount
        
        isLiked.toggle()
        
        if isLiked {
            localLikesCount += 1
            createLikeParticles()
        } else {
            localLikesCount -= 1
        }
        
        print("[PremiumFeedPostCard] Optimistic update: isLiked=\(isLiked), localLikesCount=\(localLikesCount)")
        
        // Animation feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            likeAnimationScale = 1.3
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: isLiked ? .medium : .light)
        impactFeedback.impactOccurred()
        
        // Reset scale
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                likeAnimationScale = 1.0
            }
        }
        
        // Backend update
        Task {
            do {
                if isLiked {
                    print("[PremiumFeedPostCard] 👍 Calling postService.like")
                    try await postService.like(post: post, by: currentUserId)
                } else {
                    print("[PremiumFeedPostCard] 👎 Calling postService.unlike")
                    try await postService.unlike(post: post, by: currentUserId)
                }
                
                print("[PremiumFeedPostCard] ✅ Backend update successful")
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
                
            } catch {
                print("[PremiumFeedPostCard] ❌ Backend update failed: \(error.localizedDescription)")
                
                // Revert on error
                await MainActor.run {
                    print("[PremiumFeedPostCard] 🔄 Reverting optimistic update")
                    isLiked = wasLiked
                    localLikesCount = originalLikesCount
                    
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func createLikeParticles() {
        for i in 0..<6 {
            let particle = LikeParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 50...300),
                    y: CGFloat.random(in: 50...150)
                ),
                size: CGFloat.random(in: 12...20),
                opacity: Double.random(in: 0.6...1.0),
                scale: 1.0
            )
            
            likeParticles.append(particle)
            
            // Animate particle
            withAnimation(.easeOut(duration: 1.5).delay(Double(i) * 0.1)) {
                if let index = likeParticles.firstIndex(where: { $0.id == particle.id }) {
                    likeParticles[index].position.y -= 100
                    likeParticles[index].opacity = 0
                    likeParticles[index].scale = 0.3
                }
            }
            
            // Remove particle
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                likeParticles.removeAll { $0.id == particle.id }
            }
        }
    }
    
    private func setupLikeState() {
        guard let currentUserId = session.currentUserId else {
            isLiked = false
            return
        }
        
        Task {
            do {
                isLiked = try await postService.hasUserLiked(post: post, userId: currentUserId)
            } catch {
                isLiked = false
                print("[PremiumFeedPostCard] Error loading like state: \(error)")
            }
        }
    }
    
    private func colorForPostType(_ type: PostType) -> Color {
        switch type {
        case .badge:
            return Color(red: 0.13, green: 0.77, blue: 0.37) // Green
        case .achievement:
            return Color(red: 0.96, green: 0.62, blue: 0.04) // Orange
        case .motivation:
            return Color(red: 0.43, green: 0.34, blue: 0.91) // Purple
        }
    }
    
    private func iconNameForPostType(_ type: PostType) -> String {
        switch type {
        case .badge: return "star.fill"
        case .achievement: return "trophy.fill"
        case .motivation: return "quote.bubble.fill"
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else {
            return "just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
}

// MARK: - Supporting Models
struct LikeParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
}

#if DEBUG
@available(iOS 16.0, *)
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionStore.previewStore(isLoggedIn: true)
        let postService = PostService.shared
        postService.configure(sessionStore: session)
        
        return FeedView()
            .environmentObject(session)
            .environmentObject(postService)
            .preferredColorScheme(.dark)
    }
}
#endif