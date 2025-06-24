import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct PostCellView: View {
    @EnvironmentObject private var postService: PostService
    @EnvironmentObject private var session: SessionStore
    
    let post: Post
    
    @State private var didLike: Bool = false
    @State private var likeLoading = false
    @State private var likeScale: CGFloat = 1.0
    @State private var showingLikeError = false
    @State private var likeErrorMessage = ""
    
    @State private var localLikesCount: Int
    
    init(post: Post) {
        self.post = post
        self._localLikesCount = State(initialValue: post.likesCount)
    }
    
    private func colorForCategory(categoryName: String?) -> Color {
        guard let categoryName = categoryName else { return .gray }
        switch categoryName {
        case "Fitness & Activity": return Color(hex: "#37C978")
        case "Nutrition & Health": return Color(hex: "#00E5FF")
        case "Wellness & Mindfulness": return Color(hex: "#C964FF")
        case "Achievements & Goals": return Color(hex: "#FFA500")
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            authorHeader
            if let categoryName = post.category, !categoryName.isEmpty {
                Text(categoryName)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForCategory(categoryName: categoryName).opacity(0.2))
                    .foregroundColor(colorForCategory(categoryName: categoryName))
                    .clipShape(Capsule())
            }
            postBody
            actionBar
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#1E2029"),
                            Color(hex: "#2A2B35")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
        .onAppear {
            Task { await loadLikeState() }
            localLikesCount = post.likesCount
        }
        .onChange(of: post.likesCount) { newValue in
            localLikesCount = newValue
        }
        .alert("Like Error", isPresented: $showingLikeError) {
            Button("OK") { }
        } message: {
            Text(likeErrorMessage)
        }
    }
    
    private var authorHeader: some View {
        HStack(spacing: 10) {
            Group {
                if let avatarURL = post.authorAvatarURL, !avatarURL.isEmpty, let url = URL(string: avatarURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Circle()
                                .fill(colorForCategory(categoryName: post.category).opacity(0.3))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(String(post.authorName.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 38, height: 38)
                                .clipShape(Circle())
                        case .failure(_):
                            Circle()
                                .fill(colorForCategory(categoryName: post.category).opacity(0.3))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(String(post.authorName.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 38, height: 38)
                        }
                    }
                } else {
                    Circle()
                        .fill(colorForCategory(categoryName: post.category).opacity(0.3))
                        .frame(width: 38, height: 38)
                        .overlay(
                            Text(String(post.authorName.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorName)
                    .font(.custom("SFProRounded-Semibold", size: 15))
                    .foregroundColor(.white)
                Text(post.createdDate, format: .relative(presentation: .named))
                    .font(.custom("SFProText-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            if session.role == "dietitian" {
                Button(action: { /* Open menu */ }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    @ViewBuilder
    private var postBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            if post.type == .badge, let badgeName = post.badgeName {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(colorForCategory(categoryName: post.category))
                    Text(badgeName)
                        .font(.custom("SFProRounded-Semibold", size: 17))
                        .foregroundColor(.white)
                }
            } else if post.type == .achievement {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundColor(colorForCategory(categoryName: post.category))
                    VStack(alignment: .leading, spacing: 4) {
                        if let achievementName = post.achievementName, !achievementName.isEmpty {
                            Text(achievementName)
                                .font(.custom("SFProRounded-Semibold", size: 17))
                                .foregroundColor(.white)
                        }
                        if !post.content.isEmpty {
                            Text(post.content)
                                .font(.custom("SFProText-Regular", size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(3)
                        }
                    }
                }
            } else if post.type == .motivation {
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.title2)
                        .foregroundColor(colorForCategory(categoryName: post.category))
                    Text(post.content)
                        .font(.custom("SFProText-Regular", size: 16))
                        .foregroundColor(.white)
                        .italic()
                }
            }

            if let urlString = post.imageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(10)
                    default:
                        Color.gray.opacity(0.3)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var actionBar: some View {
        HStack(spacing: 18) {
            Button {
                Task { await toggleLike() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: didLike ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(didLike ? .red : Color.gray)
                        .scaleEffect(likeScale)
                    Text("\(localLikesCount)")
                        .font(.custom("SFProText-Regular", size: 15))
                        .foregroundColor(Color.gray)
                }
            }
            .disabled(likeLoading)
            
            Button(action: { /* Navigate to comments - handled by NavigationLink in parent */ }) {
                 Label("\(post.commentsCount)", systemImage: "bubble.right")
                    .foregroundColor(.gray)
            }
           
            Spacer()
        }
        .font(.custom("SFProText-Regular", size: 15))
    }
    
    @MainActor
    private func loadLikeState() async {
        guard let uid = session.currentUserId else { 
            print("[PostCellView] User not logged in, cannot load like state.")
            didLike = false 
            return
        }
        do {
            didLike = try await postService.hasUserLiked(post: post, userId: uid)
            print("[PostCellView] Loaded like state for post \(post.id ?? "N/A"): \(didLike)")
        } catch {
            print("[PostCellView] Error loading like state for post \(post.id ?? "N/A"): \(error.localizedDescription)")
            didLike = false 
        }
    }
    
    @MainActor
    private func toggleLike() async {
        guard let uid = session.currentUserId, let postId = post.id else {
            likeErrorMessage = "You must be logged in to like posts."
            showingLikeError = true
            print("[PostCellView] Precondition for like failed: UserID: \(session.currentUserId ?? "nil"), PostID: \(post.id ?? "nil")")
            return
        }
        
        print("[PostCellView] Toggling like for post \(postId). Current state: \(didLike), Current localLikes: \(localLikesCount)")
        
        likeLoading = true
        let originalDidLike = didLike
        let originalLikesCount = localLikesCount

        didLike.toggle()
        if didLike {
            localLikesCount += 1
        } else {
            localLikesCount -= 1
        }
        print("[PostCellView] Optimistic update: didLike=\(didLike), localLikesCount=\(localLikesCount)")
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            likeScale = 1.2
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                likeScale = 1.0
            }
        }

        do {
            if didLike { 
                print("[PostCellView] Calling postService.like for post \(postId)")
                try await postService.like(post: post, by: uid)
            } else { 
                print("[PostCellView] Calling postService.unlike for post \(postId)")
                try await postService.unlike(post: post, by: uid)
            }
            print("[PostCellView] Successfully updated like on Firestore for post \(postId)")
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
        } catch {
            print("[PostCellView] Error during like/unlike for post \(postId): \(error.localizedDescription)")
            
            didLike = originalDidLike
            localLikesCount = originalLikesCount
            print("[PostCellView] Reverted optimistic update due to error: didLike=\(didLike), localLikesCount=\(localLikesCount)")
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
            
            likeErrorMessage = "Could not update like: \(error.localizedDescription)" 
            showingLikeError = true
        }
        likeLoading = false
    }
}
