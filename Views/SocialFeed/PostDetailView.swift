import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct PostDetailView: View {
    @EnvironmentObject private var postService: PostService
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    let post: Post // Passed in
    
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
    @State private var typingUserNames: [String] = []
    @State private var typingListener: ListenerRegistration?
    @State private var localUserIsTypingDebounceTimer: Timer?

    init(post: Post) {
        self.post = post
        _mainPostLikesCount = State(initialValue: post.likesCount)
        _mainPostCommentsCount = State(initialValue: post.commentsCount)
    }

    var body: some View {
        Text("PostDetailView Placeholder Body")
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

    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }
    
    @ViewBuilder
    private var postHeaderAndContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.authorAvatarURL ?? "")) { phase in
                    switch phase {
                    case .empty: ProgressView().frame(width: 50, height: 50)
                    case .success(let img): img.resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle())
                    default: Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 50, height: 50).foregroundColor(.gray)
                    }
                }
                VStack(alignment: .leading) {
                    Text(post.authorName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Posted on \(post.createdDate, formatter: fullDateFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            if let categoryName = post.category, !categoryName.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Text(categoryName)
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(colorForCategory(categoryName: categoryName).opacity(0.25))
                        .foregroundColor(colorForCategory(categoryName: categoryName))
                        .clipShape(Capsule())
                    
                    let title: String? = {
                        switch post.type {
                        case .badge: return post.badgeName
                        case .achievement: return post.achievementName
                        case .motivation: return nil
                        }
                    }()
                    
                    if let postTitle = title, !postTitle.isEmpty {
                        Text(postTitle)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                    }
                }
            } else if post.type == .badge, let badgeName = post.badgeName, !badgeName.isEmpty {
                 Text(badgeName)
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }


            if post.status == .pending {
                Text("Pending Review")
                    .font(.caption.italic())
                    .foregroundColor(.yellow)
                    .padding(.vertical, 2)
            } else if post.status == .rejected {
                 Text("Post Rejected")
                    .font(.caption.italic())
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            }

            if !post.content.isEmpty {
                Text(post.content)
                    .font(post.type == .motivation ? .title3 : .body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let urlString = post.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    case .success(let img):
                        img.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                    default:
                        Color.gray.opacity(0.3)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    }
                }
                .padding(.vertical, 8)
            }
            HStack(spacing: 18) {
                Button(action: {
                    print("Like button tapped - SYNC TEST")
                }) {
                    Label("\(mainPostLikesCount)", systemImage: mainPostDidLike ? "heart.fill" : "heart")
                        .foregroundColor(mainPostDidLike ? .red : .gray)
                }
                .disabled(mainPostLikeLoading)
                .scaleEffect(likeScale)

                Label("\(mainPostCommentsCount)", systemImage: "bubble.right")
                    .foregroundColor(.gray)
                Spacer()
            }
            .font(.custom("SFProText-Regular", size: 15))
            .padding(.top, 8)
        }
    }

    private var typingIndicatorText: String {
        let activeTypers = typingUserNames.filter { $0 != session.currentUser?.fullName }
        if activeTypers.isEmpty { return "" }
        if activeTypers.count == 1 {
            return "\(activeTypers[0]) is typing..."
        } else if activeTypers.count == 2 {
            return "\(activeTypers[0]) and \(activeTypers[1]) are typing..."
        } else {
            return "\(activeTypers.count) people are typing..."
        }
    }

    @ViewBuilder
    private var commentsSection: some View {
        if comments.isEmpty {
            Text("Be the first to comment!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 20)
        } else {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(comments) { comment in
                    CommentCell(
                        comment: comment,
                        postId: post.id ?? "", // Pass postId
                        onModerationFeedback: { message in
                            showModerationFeedback(message: message)
                        }
                    )
                    .id(comment.id) // Ensure each cell is uniquely identifiable
                }
            }
            .animation(.easeInOut(duration: 0.3), value: comments) // For insert/delete animations
        }
    }

    private func updateTypingStatus(isTyping: Bool) {
        localUserIsTypingDebounceTimer?.invalidate()
        guard let userId = session.currentUserId, let postId = post.id else { return }
        
        if isTyping {
            Task {
                try? await postService.setTypingIndicator(forPostId: postId, userId: userId, userName: session.currentUser?.fullName ?? "Someone", isTyping: true)
            }
            localUserIsTypingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task {
                    try? await postService.setTypingIndicator(forPostId: postId, userId: userId, userName: session.currentUser?.fullName ?? "Someone", isTyping: false)
                }
            }
        } else {
            Task {
                try? await postService.setTypingIndicator(forPostId: postId, userId: userId, userName: session.currentUser?.fullName ?? "Someone", isTyping: false)
            }
        }
    }

    private func startListeningForTypingIndicators() {
        guard let postId = post.id else { return }
        typingListener = postService.listenForTypingIndicators(inPostId: postId) { userNames in
            DispatchQueue.main.async {
                withAnimation {
                    self.typingUserNames = userNames
                }
            }
        }
    }
    
    @MainActor
    private func loadMainPostLikeState() async {
        guard let uid = session.currentUserId else { return }
        mainPostLikeLoading = false 
        do {
            mainPostDidLike = try await postService.hasUserLiked(post: post, userId: uid)
        } catch {
            print("[PostDetailView] Error loading main post like state: \(error.localizedDescription)")
            mainPostDidLike = false
        }
    }

    @MainActor
    private func toggleMainPostLike() { 
        guard let uid = session.currentUserId else { return }
        mainPostLikeLoading = true
        let originalDidLike = mainPostDidLike
        
        mainPostDidLike.toggle()
        if mainPostDidLike { mainPostLikesCount += 1 } else { mainPostLikesCount -= 1 }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { likeScale = 1.2 }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { likeScale = 1.0 }
        }

        print("[PostDetailView] toggleMainPostLike (SYNC TEST) called. Original didLike: \(originalDidLike)")
        // Simulate async completion for loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mainPostLikeLoading = false
        }
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
                if let postId = post.id {
                    try? await postService.setTypingIndicator(forPostId: postId, userId: uid, userName: user.fullName, isTyping: false)
                }
            } catch {
                print("Error sending comment: \(error.localizedDescription)")
                showModerationFeedback(message: "Unable to send comment. Please try again.")
                isPostingComment = false
            }
        }
    }

    @MainActor
    private func flagUserAction(_ userIdToFlag: String) async {
        do {
            try await postService.flagUser(flaggedUserId: userIdToFlag, reason: "Flagged from post detail view")
            showModerationFeedback(message: "User \(post.authorName) flagged.")
        } catch {
            showModerationFeedback(message: "Failed to flag user: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func approvePostAction() async {
        do {
            try await postService.approvePost(post)
            showModerationFeedback(message: "Post approved.")
        } catch {
            showModerationFeedback(message: "Failed to approve post: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func reportPostAction(reason: String) async {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showModerationFeedback(message: "A reason is required to report a post.")
            return
        }
        do {
            try await postService.reportPost(post, reason: reason)
            showModerationFeedback(message: "Post reported.")
        } catch {
            showModerationFeedback(message: "Failed to report post: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func showModerationFeedback(message: String) {
        moderationFeedbackMessage = message
        withAnimation {
            showingModerationFeedback = true
        }
    }

    private func deletePostAction() async {
        guard let postId = post.id else {
            showModerationFeedback(message: "Error: Post ID is missing.")
            return
        }
        print("Attempting to delete post: \(postId)")
        do {
            try await postService.deletePost(post)
            showModerationFeedback(message: "Post deleted successfully.")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss()
            }
        } catch {
            print("Error deleting post: \(error.localizedDescription)")
            showModerationFeedback(message: "Error deleting post: \(error.localizedDescription)")
        }
    }
}

@available(iOS 16.0, *)
private struct CommentCell: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var postService: PostService

    let comment: PostComment
    let postId: String
    var onModerationFeedback: (String) -> Void
    
    @State private var showingReportAlert = false
    @State private var reportReason: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AsyncImage(url: URL(string: comment.commenterAvatarURL ?? "")) { phase in
                switch phase {
                case .empty: ProgressView().frame(width: 36, height: 36)
                case .success(let img): img.resizable().scaledToFill().frame(width: 36, height: 36).clipShape(Circle())
                default: Image(systemName: "person.crop.circle.fill").resizable().scaledToFit().frame(width: 36, height: 36).foregroundColor(.gray)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.commenterName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(comment.createdDate, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                            if session.role == "dietitian" { // Dietitian-specific actions
                                if comment.commenterId != session.currentUserId { 
                                    Button(action: {
                                        print("Flag commenter \(comment.commenterName) action from cell menu needs implementation.")
                                        onModerationFeedback("Flag Commenter action from cell menu needs implementation.")
                                    }) {
                                        Label("Flag Commenter", systemImage: "flag")
                                    }
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
                                .foregroundColor(.gray)
                                .padding(5) 
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
                }
                Text(comment.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1C1D26").opacity(0.5)) 
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    @MainActor
    private func deleteCommentAction() async {
        print("[CommentCell] Attempting to delete comment \(comment.id ?? "nil") from post \(postId)")
        guard let commentId = comment.id else {
            onModerationFeedback("Error: Comment ID missing.")
            return
        }
        do {
            try await postService.deleteComment(postId: postId, commentId: commentId)
            onModerationFeedback("Comment deleted successfully.")
        } catch {
            print("[CommentCell] Error deleting comment: \(error.localizedDescription)")
            onModerationFeedback("Error deleting comment: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func reportCommentAction(reason: String) async {
       print("[CommentCell] Attempting to report comment \(comment.id ?? "nil") from post \(postId) for reason: \(reason)")
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onModerationFeedback("A reason is required to report a comment.")
            return
        }
        guard let commentId = comment.id else {
            onModerationFeedback("Error: Comment ID for reporting is missing.")
            return
        }
        do {
            try await postService.reportComment(postId: postId, comment: comment, reason: reason)
            onModerationFeedback("Comment reported successfully.")
        } catch {
            print("[CommentCell] Error reporting comment: \(error.localizedDescription)")
            onModerationFeedback("Error reporting comment: \(error.localizedDescription)")
        }
    }
}
