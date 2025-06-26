import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct FeedView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postService: PostService
    @State private var showingCreatePost: Bool = false
    
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
                
                if postService.posts.isEmpty && session.currentUserId != nil {
                    emptyFeedView()
                } else if session.currentUserId == nil {
                    VStack {
                        Text("Please log in to see the feed.")
                            .foregroundColor(.white)
                    }
                } else if postService.posts.isEmpty && session.currentUserId != nil {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(postService.posts) { post in
                                FeedPostCardView(post: post)
                                    .environmentObject(session)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Community Feed")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreatePost = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#6E56E9"))
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(session)
                    .environmentObject(postService)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
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
                showingCreatePost = true
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
}

@available(iOS 16.0, *)
struct FeedPostCardView: View {
    let post: Post
    @EnvironmentObject var session: SessionStore
    @State private var isLiked: Bool = false
    @State private var localLikesCount: Int
    @State private var localCommentsCount: Int
    @State private var showingComments: Bool = false
    @State private var showingEditPost: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingFeatureComingSoon: Bool = false

    init(post: Post) {
        self.post = post
        self._localLikesCount = State(initialValue: post.likesCount)
        self._localCommentsCount = State(initialValue: post.commentsCount)
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.authorAvatarURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle().fill(Color.gray.opacity(0.3)).frame(width: 44, height: 44)
                            .overlay(Circle().stroke(accentGradient, lineWidth: 2)).overlay(ProgressView())
                    case .success(let image):
                        image.resizable().scaledToFill().frame(width: 44, height: 44)
                            .clipShape(Circle()).overlay(Circle().stroke(accentGradient, lineWidth: 2))
                    default:
                        Circle().fill(Color.gray.opacity(0.3)).frame(width: 44, height: 44)
                            .overlay(Circle().stroke(accentGradient, lineWidth: 2))
                            .overlay(Text(String(post.authorName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white))
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(.white)
                    Text(formatTimestamp(post.createdAt))
                        .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(Color.gray)
                }
                Spacer()
                ZStack {
                    Circle().fill(colorForPostType(post.type).opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: iconNameForPostType(post.type))
                        .font(.system(size: 18, weight: .medium)).foregroundColor(colorForPostType(post.type))
                }
                if post.authorId == session.currentUserId {
                    Menu {
                        Button { showingEditPost = true } label: { Label("Edit Post", systemImage: "pencil") }
                        Button(role: .destructive) { showingDeleteConfirmation = true } label: { Label("Delete Post", systemImage: "trash") }
                    } label: {
                        Image(systemName: "ellipsis").font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.gray).frame(width: 32, height: 32).contentShape(Rectangle())
                    }
                }
            }
            
            contentView(for: post).padding(.top, 4)

            HStack(spacing: 24) {
                Button(action: toggleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium)).foregroundColor(isLiked ? .red : Color.gray)
                            .scaleEffect(isLiked ? 1.25 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
                        Text("\(localLikesCount)")
                            .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(Color.gray)
                    }
                }.buttonStyle(PlainButtonStyle())
                Button(action: { showingComments = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left").font(.system(size: 20, weight: .medium)).foregroundColor(Color.gray)
                        Text("\(localCommentsCount)")
                            .font(.system(size: 15, weight: .medium, design: .rounded)).foregroundColor(Color.gray)
                    }
                }.buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(hex: "#1A1D24").opacity(0.9))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(
            LinearGradient(gradient: Gradient(colors: [colorForPostType(post.type).opacity(0.4), Color.white.opacity(0.05), colorForPostType(post.type).opacity(0.2)]),
                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
        .onTapGesture { /* showingFeatureComingSoon = true */ }
        .onAppear(perform: setupLikeState)
        .sheet(isPresented: $showingComments) { PostDetailView(post: post).environmentObject(session).environmentObject(PostService.shared) }
        .sheet(isPresented: $showingEditPost) { /* EditPostView(post: post) - Implement later */ }
        .alert("Delete Post", isPresented: $showingDeleteConfirmation, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { /* deletePost() - Implement later */ }
        }, message: { Text("Are you sure you want to delete this post?") })
    }

    @ViewBuilder
    private func contentView(for post: Post) -> some View {
        let contentFont = Font.system(size: 16, weight: .regular, design: .rounded)
        
        switch post.type {
        case .badge:
            HStack(spacing: 10) {
                Image(systemName: uiTypeFor(badgeName: post.badgeName ?? "").iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient(colors: [uiTypeFor(badgeName: post.badgeName ?? "").color, uiTypeFor(badgeName: post.badgeName ?? "").color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("\(post.authorName) unlocked **\(post.badgeName ?? "a badge")**!")
                    .font(contentFont).foregroundColor(.white.opacity(0.9)).lineLimit(2)
            }
        case .achievement:
            HStack(spacing: 10) {
                Image(systemName: uiTypeFor(achievementName: post.achievementName ?? "").iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(LinearGradient(colors: [uiTypeFor(achievementName: post.achievementName ?? "").color, uiTypeFor(achievementName: post.achievementName ?? "").color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("\(post.authorName) achieved **\(post.achievementName ?? "an achievement")**!")
                    .font(contentFont).foregroundColor(.white.opacity(0.9)).lineLimit(2)
            }
        case .motivation:
            VStack(alignment: .leading, spacing: 10) {
                Text(post.content ?? "")
                    .font(.system(size: 18, weight: .medium, design: .serif)) 
                    .italic()
                    .foregroundColor(.white)
                    .lineLimit(nil) 
                    .padding(.horizontal, 4)
                
                HStack {
                    Spacer()
                    Text("— \(post.authorName)") 
                        .font(.system(size: 14, weight: .light, design: .rounded))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.vertical, 8)
            .background(
                ZStack { 
                    HStack {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(colorForPostType(post.type).opacity(0.1))
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "quote.closing")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(colorForPostType(post.type).opacity(0.1))
                    }
                }
                .padding(.horizontal, -8) 
            )
        }
    }

    private func uiTypeFor(badgeName: String) -> UITypeForPost {
        return UITypeForPost(rawValue: badgeName) ?? .goalsMotivatorBadge
    }
    private func uiTypeFor(achievementName: String) -> UITypeForPost {
        return UITypeForPost(rawValue: achievementName) ?? .goalsChallengeComplete
    }

    private func iconNameForPostType(_ type: PostType) -> String {
        switch type {
        case .badge: return "star.fill"
        case .achievement: return "trophy.fill"
        case .motivation: return "quote.bubble.fill"
        }
    }
    
    private func colorForPostType(_ type: PostType) -> Color {
        switch type {
        case .badge: return Color(hex: "#22C55E")
        case .achievement: return Color(hex: "#F59E0B")
        case .motivation: return Color(hex: "#6E56E9")
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
    
    private func setupLikeState() {
        guard let currentUserId = session.currentUserId, let postId = post.id else {
            isLiked = false
            return
        }
        Task {
            isLiked = (try? await PostService.shared.hasUserLiked(post: post, userId: currentUserId)) ?? false
        }
    }
    
    private func toggleLike() {
        guard let currentUserId = session.currentUserId, let postId = post.id else { return }
        
        Task {
            do {
                if isLiked {
                    try await PostService.shared.unlike(post: post, by: currentUserId)
                    localLikesCount -= 1
                } else {
                    try await PostService.shared.like(post: post, by: currentUserId)
                    localLikesCount += 1
                    if post.authorId != currentUserId {
                        createLikeNotification(for: post, likerId: currentUserId, likerName: session.currentUser?.fullName ?? "Someone")
                    }
                }
                isLiked.toggle()
            } catch {
                print("[FeedPostCardView] Error toggling like: \(error.localizedDescription)")
            }
        }
    }
    
    private func createLikeNotification(for post: Post, likerId: String, likerName: String) {
        guard let postId = post.id else { return }
        let db = Firestore.firestore()
        let notificationRef = db.collection("notifications").document()
        
        var contentPreview = ""
        switch post.type {
        case .badge:
            contentPreview = post.badgeName ?? "a badge"
        case .achievement:
            contentPreview = post.achievementName ?? "an achievement"
        case .motivation:
            contentPreview = post.content ?? ""
        }
        let finalPreview = String(contentPreview.prefix(50)) + (contentPreview.count > 50 ? "..." : "")

        let newNotification = AppNotification(
            userId: post.authorId,
            type: .newLike,
            fromUserId: likerId,
            fromUserName: likerName,
            postId: postId,
            postContentPreview: finalPreview,
            timestamp: Timestamp(date: Date()),
            isRead: false
        )
        do {
            try notificationRef.setData(from: newNotification)
        } catch {
            print("[FeedPostCardView] Error encoding like notification: \(error.localizedDescription)")
        }
    }
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