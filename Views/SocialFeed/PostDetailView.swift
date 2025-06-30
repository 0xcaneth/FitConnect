import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct PostDetailView: View {
    @EnvironmentObject private var postService: PostService
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    let post: Post
    
    @State private var mainPostDidLike: Bool = false
    @State private var mainPostLikeLoading: Bool = false
    @State private var mainPostLikesCount: Int
    @State private var mainPostCommentsCount: Int
    @State private var likeScale: CGFloat = 1.0
    @State private var showingLikeErrorAlert = false
    @State private var likeErrorMessage = ""
    @State private var comments: [PostComment] = []
    @State private var commentText: String = ""
    @State private var isPostingComment = false    
    @State private var commentsListener: ListenerRegistration?
    @State private var showingModerationFeedback = false
    @State private var moderationFeedbackMessage = ""

    init(post: Post) {
        self.post = post
        _mainPostLikesCount = State(initialValue: post.likesCount)
        _mainPostCommentsCount = State(initialValue: post.commentsCount)
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.03, green: 0.04, blue: 0.06), location: 0.0),
                        .init(color: Color(red: 0.06, green: 0.07, blue: 0.10), location: 0.3),
                        .init(color: Color(red: 0.04, green: 0.05, blue: 0.08), location: 0.7),
                        .init(color: Color(red: 0.02, green: 0.03, blue: 0.05), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        postHeaderAndContent
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.08),
                                                Color.white.opacity(0.04)
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
                                                        Color.white.opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Comments")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("(\(comments.count))")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            commentsSection
                                .padding(.horizontal, 16)
                            
                            premiumCommentInput
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40)
                        }
                        .padding(.top, 32)
                    }
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.91))
                }
            }
            .onAppear {
                Task {
                    await loadMainPostLikeState()
                }
                startListeningComments()
            }
            .onDisappear {
                commentsListener?.remove()
                commentsListener = nil
            }
            .alert("Like Error", isPresented: $showingLikeErrorAlert) {
                Button("OK") { }
            } message: {
                Text(likeErrorMessage)
            }
            .alert("Action Complete", isPresented: $showingModerationFeedback) {
                Button("OK") { }
            } message: {
                Text(moderationFeedbackMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var postHeaderAndContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: post.authorAvatarURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(colorForPostType(post.type).opacity(0.3))
                            .frame(width: 56, height: 56)
                            .overlay(
                                ProgressView()
                                    .tint(colorForPostType(post.type))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(
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
                            )
                    case .failure(_):
                        Circle()
                            .fill(colorForPostType(post.type).opacity(0.3))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Text(String(post.authorName.prefix(1)).uppercased())
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.authorName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(fullDateFormatter.string(from: post.createdDate))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let category = post.category {
                            Text("•")
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text(category)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(colorForPostType(post.type))
                        }
                    }
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForPostType(post.type).opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: iconNameForPostType(post.type))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(colorForPostType(post.type))
                }
            }
            
            Group {
                switch post.type {
                case .badge:
                    badgeContentView
                case .achievement:
                    achievementContentView
                case .motivation:
                    motivationContentView
                }
            }
            
            if let urlString = post.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 250)
                            .overlay(
                                ProgressView()
                                    .tint(colorForPostType(post.type))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.red.opacity(0.1))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red.opacity(0.6))
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .padding(.vertical, 12)
            }
            
            HStack(spacing: 32) {
                Button(action: {
                    Task { await toggleMainPostLike() }
                }) {
                    HStack(spacing: 10) {
                        ZStack {
                            if mainPostDidLike {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.red, Color.pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .scaleEffect(likeScale)
                                    .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                            } else {
                                Image(systemName: "heart")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Text("\(mainPostLikesCount)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(mainPostDidLike ? .red : .white.opacity(0.7))
                            .contentTransition(.numericText())
                    }
                }
                .disabled(mainPostLikeLoading)
                .buttonStyle(.plain)
                
                HStack(spacing: 10) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(comments.count)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .contentTransition(.numericText())
                }
                
                Spacer()
            }
            .padding(.top, 16)
        }
    }
    
    @ViewBuilder
    private var badgeContentView: some View {
        HStack(spacing: 20) {
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
                            endRadius: 35
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 32, weight: .bold))
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
                    .shadow(color: colorForPostType(post.type).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Badge Unlocked!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorForPostType(post.type))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(post.badgeName ?? "Achievement Badge")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var achievementContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 20) {
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
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32, weight: .bold))
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
                        .shadow(color: colorForPostType(post.type).opacity(0.4), radius: 8, x: 0, y: 4)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Achievement Unlocked!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(colorForPostType(post.type))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    if let achievementName = post.achievementName {
                        Text(achievementName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
            }
            
            if let content = post.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(4)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var motivationContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colorForPostType(post.type).opacity(0.6))
                
                Text("Daily Motivation")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorForPostType(post.type))
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Text(post.content ?? "")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(.white)
                .lineSpacing(6)
                .padding(.horizontal, 8)
            
            HStack {
                Spacer()
                Text("— \(post.authorName)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorForPostType(post.type).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colorForPostType(post.type).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var commentsSection: some View {
        if comments.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("No comments yet")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Be the first to share your thoughts!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 40)
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(comments, id: \.id) { comment in
                    PremiumCommentCell(
                        comment: comment,
                        postId: post.id ?? "",
                        onModerationFeedback: { message in
                            moderationFeedbackMessage = message
                            showingModerationFeedback = true
                        }
                    )
                    .environmentObject(session)
                    .environmentObject(postService)
                }
            }
        }
    }
    
    @ViewBuilder
    private var premiumCommentInput: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: session.currentUser?.photoURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(session.currentUser?.fullName.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    case .failure(_):
                        Circle()
                            .fill(Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(session.currentUser?.fullName.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $commentText, axis: .vertical)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            commentText.isEmpty ? Color.white.opacity(0.1) : Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.4),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .lineLimit(1...4)
                    
                    Button(action: {
                        sendComment()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.43, green: 0.34, blue: 0.91),
                                            Color(red: 0.58, green: 0.20, blue: 0.92)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .shadow(
                                    color: Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3),
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                            
                            if isPostingComment {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                    .opacity(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    .scaleEffect(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.9 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: commentText.isEmpty)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    private func colorForPostType(_ type: PostType) -> Color {
        switch type {
        case .badge:
            return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .achievement:
            return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .motivation:
            return Color(red: 0.43, green: 0.34, blue: 0.91)
        }
    }
    
    private func iconNameForPostType(_ type: PostType) -> String {
        switch type {
        case .badge: return "star.fill"
        case .achievement: return "trophy.fill"
        case .motivation: return "quote.bubble.fill"
        }
    }
    
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }
    
    @MainActor
    private func loadMainPostLikeState() async {
        guard let uid = session.currentUserId else { 
            mainPostDidLike = false
            return
        }
        
        do {
            mainPostDidLike = try await postService.hasUserLiked(post: post, userId: uid)
        } catch {
            print("[PostDetailView] Error loading main post like state: \(error.localizedDescription)")
            mainPostDidLike = false
        }
    }

    @MainActor
    private func toggleMainPostLike() async {
        guard let uid = session.currentUserId else { return }
        
        let originalDidLike = mainPostDidLike
        let originalLikesCount = mainPostLikesCount
        
        mainPostLikeLoading = true
        mainPostDidLike.toggle()
        
        if mainPostDidLike {
            mainPostLikesCount += 1
        } else {
            mainPostLikesCount -= 1
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            likeScale = 1.3
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: mainPostDidLike ? .medium : .light)
        impactFeedback.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                likeScale = 1.0
            }
        }

        do {
            if mainPostDidLike {
                try await postService.like(post: post, by: uid)
            } else {
                try await postService.unlike(post: post, by: uid)
            }
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
        } catch {
            await MainActor.run {
                mainPostDidLike = originalDidLike
                mainPostLikesCount = originalLikesCount
                
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
                
                likeErrorMessage = "Could not update like: \(error.localizedDescription)"
                showingLikeErrorAlert = true
            }
            
            print("[PostDetailView] Error toggling like: \(error)")
        }
        
        mainPostLikeLoading = false
    }

    private func startListeningComments() {
        guard let postId = post.id else { return }
        commentsListener = postService.listenComments(for: postId) { newComments in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.comments = newComments
                }
            }
        }
    }
    
    private func sendComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty, let uid = session.currentUserId, let user = session.currentUser else { return }
        
        isPostingComment = true
        let newComment = PostComment(
            commenterId: uid,
            commenterName: user.fullName,
            commenterAvatarURL: user.photoURL,
            text: trimmedComment,
            createdAt: Timestamp(date: Date())
        )
        
        Task { @MainActor in
            do {
                try await postService.addComment(to: post, comment: newComment)
                
                commentText = ""
                isPostingComment = false
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
            } catch {
                print("Error sending comment: \(error.localizedDescription)")
                moderationFeedbackMessage = "Unable to send comment. Please try again."
                showingModerationFeedback = true
                isPostingComment = false
                
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
}

@available(iOS 16.0, *)
struct PremiumCommentCell: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var postService: PostService

    let comment: PostComment
    let postId: String
    var onModerationFeedback: (String) -> Void
    
    @State private var showingReportAlert = false
    @State private var reportReason: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: comment.commenterAvatarURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(comment.commenterName.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure(_):
                    Circle()
                        .fill(Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(String(comment.commenterName.prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                @unknown default:
                    EmptyView()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(comment.commenterName)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(comment.createdDate, style: .relative)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Spacer()
                        
                        if session.role == "dietitian" || comment.commenterId == session.currentUserId {
                            Menu {
                                if comment.commenterId == session.currentUserId || session.role == "dietitian" {
                                    Button(role: .destructive, action: {
                                        Task { await deleteCommentAction() }
                                    }) {
                                        Label("Delete Comment", systemImage: "trash")
                                    }
                                }
                                
                                if comment.commenterId != session.currentUserId {
                                    Button(action: {
                                        reportReason = ""
                                        showingReportAlert = true
                                    }) {
                                        Label("Report Comment", systemImage: "exclamationmark.bubble")
                                    }
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(8)
                            }
                        }
                    }
                    
                    Text(comment.text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
        .alert("Report Comment", isPresented: $showingReportAlert) {
            TextField("Reason for reporting", text: $reportReason)
            Button("Report", role: .destructive) {
                Task { await reportCommentAction(reason: reportReason) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please provide a reason for reporting this comment.")
        }
    }

    @MainActor
    private func deleteCommentAction() async {
        guard let commentId = comment.id else {
            onModerationFeedback("Error: Comment ID missing.")
            return
        }
        
        do {
            try await postService.deleteComment(postId: postId, commentId: commentId)
            onModerationFeedback("Comment deleted successfully.")
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            print("[PremiumCommentCell] Error deleting comment: \(error.localizedDescription)")
            onModerationFeedback("Error deleting comment: \(error.localizedDescription)")
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }

    @MainActor
    private func reportCommentAction(reason: String) async {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onModerationFeedback("A reason is required to report a comment.")
            return
        }
        
        do {
            try await postService.reportComment(postId: postId, comment: comment, reason: reason)
            onModerationFeedback("Comment reported successfully.")
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            print("[PremiumCommentCell] Error reporting comment: \(error.localizedDescription)")
            onModerationFeedback("Error reporting comment: \(error.localizedDescription)")
            
            let errorFeedback = UINotificationFeedbackGenerator()
            errorFeedback.notificationOccurred(.error)
        }
    }
}