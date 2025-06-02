import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FeedView: View {
    @EnvironmentObject var session: SessionStore
    @State private var feedPosts: [FeedPost] = []
    @State private var isLoading: Bool = true
    @State private var showingCreatePost: Bool = false
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground() // Or .configureWithTransparentBackground() if you prefer
        appearance.backgroundColor = UIColor(Color(hex: "#0D0F14")) // Match the ZStack background
        
        // Large title text color
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        // Inline title text color (if needed)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance // For other modes
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#101218"), Color(hex: "#0B0D12")]),
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if feedPosts.isEmpty {
                    emptyFeedView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(feedPosts) { post in
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
                            .foregroundColor(Color(hex: "#6E56E9")) // Accent color
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView()
                    .environmentObject(session)
            }
            .onAppear {
                loadFeedPosts()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Keep this for consistent behavior
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
    
    private func loadFeedPosts() {
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("feed")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("[FeedView] Error loading feed posts: \(error.localizedDescription)")
                        self.feedPosts = []
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.feedPosts = []
                        return
                    }
                    
                    self.feedPosts = documents.compactMap { document in
                        do {
                            return try document.data(as: FeedPost.self)
                        } catch {
                            print("[FeedView] Error decoding feed post \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("[FeedView] Loaded \(self.feedPosts.count) feed posts")
                }
            }
    }
}

struct FeedPostCardView: View {
    let post: FeedPost
    @EnvironmentObject var session: SessionStore
    @State private var isLiked: Bool = false
    @State private var currentLikesCount: Int = 0
    @State private var showingComments: Bool = false
    @State private var showingPostActions: Bool = false
    @State private var showingEditPost: Bool = false
    @State private var showingDeleteConfirmation: Bool = false

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
                Circle()
                    .fill(Color.gray.opacity(0.3)) 
                    .frame(width: 44, height: 44) 
                    .overlay(
                        Circle().stroke(accentGradient, lineWidth: 2) 
                    )
                    .overlay(
                        Text(String(post.authorName.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded)) 
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 17, weight: .semibold, design: .rounded)) 
                        .foregroundColor(.white)
                    
                    Text(formatTimestamp(post.timestamp))
                        .font(.system(size: 13, weight: .medium, design: .rounded)) 
                        .foregroundColor(Color.gray) 
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(colorForPostType(post.type).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: post.type.iconName)
                        .font(.system(size: 18, weight: .medium)) 
                        .foregroundColor(colorForPostType(post.type))
                }
                
                if post.authorId == session.currentUserId {
                    Menu {
                        Button {
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            showingEditPost = true
                        } label: {
                            Label("Edit Post", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            let haptic = UIImpactFeedbackGenerator(style: .heavy)
                            haptic.impactOccurred()
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.gray)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
            }
            
            contentView(for: post)
                .padding(.top, 4) 

            HStack(spacing: 24) { 
                Button(action: toggleLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium)) 
                            .foregroundColor(isLiked ? .red : Color.gray)
                            .scaleEffect(isLiked ? 1.25 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isLiked)
                        
                        Text("\(currentLikesCount)")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle()) 

                Button(action: { 
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    showingComments = true 
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.top, 8) 
        }
        .padding(20) 
        .background(
            RoundedRectangle(cornerRadius: 20) 
                .fill(Color(hex: "#1A1D24").opacity(0.9)) 
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4) 
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient( 
                        gradient: Gradient(colors: [
                            colorForPostType(post.type).opacity(0.4),
                            Color.white.opacity(0.05), 
                            colorForPostType(post.type).opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            setupLikeState()
        }
        .sheet(isPresented: $showingComments) {
            CommentsView(post: post)
                .environmentObject(session)
        }
        .sheet(isPresented: $showingEditPost) {
            EditPostView(post: post)
                .environmentObject(session)
        }
        .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }

    @ViewBuilder
    private func contentView(for post: FeedPost) -> some View {
        let contentFont = Font.system(size: 16, weight: .regular, design: .rounded)
        
        switch post.type {
        case .badge:
            HStack(spacing: 10) {
                Image(systemName: "star.circle.fill") 
                    .font(.system(size: 28)) 
                    .foregroundStyle( 
                        LinearGradient(
                            colors: [Color(hex: "#22C55E"), Color(hex: "#A3E635")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("\(post.authorName) unlocked **\(post.content)**!")
                    .font(contentFont)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
        case .achievement:
            HStack(spacing: 10) {
                Image(systemName: "trophy.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#F59E0B"), Color(hex: "#FBBF24")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("\(post.authorName) achieved **\(post.content)**!")
                    .font(contentFont)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
        case .motivation_text:
            VStack(alignment: .leading, spacing: 10) {
                Text(post.content)
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

    private func colorForPostType(_ type: FeedPostType) -> Color {
        switch type {
        case .badge:
            return Color(hex: "#22C55E")
        case .achievement:
            return Color(hex: "#F59E0B")
        case .motivation_text:
            return Color(hex: "#6E56E9")
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
    
    private func setupLikeState() {
        currentLikesCount = post.likesCount
        if let likedBy = post.likedBy {
            isLiked = likedBy.contains(session.currentUserId)
        }
    }
    
    private func toggleLike() {
        guard !session.currentUserId.isEmpty, let postId = post.id else { return }
        
        let db = Firestore.firestore()
        let postRef = db.collection("feed").document(postId)
        
        if isLiked {
            postRef.updateData([
                "likesCount": FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([session.currentUserId])
            ]) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.isLiked = false
                        self.currentLikesCount = max(0, self.currentLikesCount - 1)
                    }
                }
            }
        } else {
            postRef.updateData([
                "likesCount": FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([session.currentUserId])
            ]) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.isLiked = true
                        self.currentLikesCount += 1
                    }
                }
            }
        }
    }
    
    private func deletePost() {
        guard let postId = post.id else { return }
        
        let db = Firestore.firestore()
        
        db.collection("feed").document(postId).delete { error in
            if let error = error {
                print("[FeedPostCardView] Error deleting post: \(error.localizedDescription)")
            } else {
                print("[FeedPostCardView] Post deleted successfully")
                
                db.collection("comments")
                    .whereField("postId", isEqualTo: postId)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            let batch = db.batch()
                            for document in documents {
                                batch.deleteDocument(document.reference)
                            }
                            batch.commit { error in
                                if let error = error {
                                    print("[FeedPostCardView] Error deleting comments: \(error.localizedDescription)")
                                } else {
                                    print("[FeedPostCardView] Associated comments deleted")
                                }
                            }
                        }
                    }
            }
        }
    }
}

#if DEBUG
struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif
