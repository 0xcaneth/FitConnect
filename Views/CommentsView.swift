import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CommentsView: View {
    let post: FeedPost
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var comments: [Comment] = []
    @State private var newCommentText: String = ""
    @State private var isLoading: Bool = true
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Post Summary
                    postSummaryView()
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Comments Section
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    } else if comments.isEmpty {
                        emptyCommentsView()
                    } else {
                        commentsScrollView()
                    }
                    
                    // Comment Input
                    commentInputView()
                }
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadComments()
        }
    }
    
    @ViewBuilder
    private func postSummaryView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.authorName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(formatTimestamp(post.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                }
                
                Spacer()
            }
            
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineLimit(3)
        }
        .padding()
        .background(Color(hex: "#1A1D24").opacity(0.5))
    }
    
    @ViewBuilder
    private func emptyCommentsView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 40))
                .foregroundColor(Color.gray)
            
            Text("No comments yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Be the first to comment!")
                .font(.system(size: 14))
                .foregroundColor(Color.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func commentsScrollView() -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(comments) { comment in
                    CommentRowView(comment: comment)
                        .environmentObject(session)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func commentInputView() -> some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack(spacing: 12) {
                userAvatarView()
                commentTextFieldView()
                submitButtonView()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(hex: "#0D0F14").opacity(0.95))
    }
    
    @ViewBuilder
    private func userAvatarView() -> some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 32, height: 32)
            .overlay(
                Text(String(session.currentUser?.fullName.first ?? session.currentUser?.email.first ?? "U").uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            )
    }
    
    @ViewBuilder
    private func commentTextFieldView() -> some View {
        ZStack(alignment: .topLeading) {
            // Background first
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1C1E25").opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // TextEditor with clear background
            TextEditor(text: $newCommentText)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.white)
                .background(Color.clear)
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .frame(minHeight: 36, maxHeight: 80)
                .onAppear {
                    UITextView.appearance().backgroundColor = UIColor.clear
                }
            
            // Placeholder
            if newCommentText.isEmpty {
                Text("Add a comment...")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(EdgeInsets(top: 8 + 3, leading: 12 + 5, bottom: 8, trailing: 12))
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: 36, maxHeight: 80)
    }
    
    @ViewBuilder
    private func submitButtonView() -> some View {
        Button(action: submitComment) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
        .frame(width: 32, height: 32)
        .background(submitButtonBackground())
    }
    
    @ViewBuilder
    private func submitButtonBackground() -> some View {
        if newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 32, height: 32)
        } else {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 32, height: 32)
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
    
    private func loadComments() {
        guard let postId = post.id else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("[CommentsView] Error loading comments: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.comments = []
                        return
                    }
                    
                    self.comments = documents.compactMap { document in
                        do {
                            return try document.data(as: Comment.self)
                        } catch {
                            print("[CommentsView] Error decoding comment: \(error)")
                            return nil
                        }
                    }
                }
            }
    }
    
    private func submitComment() {
        let commentText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commentText.isEmpty,
              let currentUserId = session.currentUserId, !currentUserId.isEmpty,
              let postId = post.id else { return }
        
        isSubmitting = true
        
        let comment = Comment(
            postId: postId,
            authorId: currentUserId,
            authorName: session.currentUser?.fullName ?? session.currentUser?.email ?? "Unknown User",
            text: commentText
        )
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("comments").addDocument(from: comment) { error in
                DispatchQueue.main.async {
                    self.isSubmitting = false
                    
                    if let error = error {
                        print("[CommentsView] Error submitting comment: \(error.localizedDescription)")
                    } else {
                        self.newCommentText = ""
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isSubmitting = false
                print("[CommentsView] Error encoding comment: \(error.localizedDescription)")
            }
        }
    }
}

struct CommentRowView: View {
    let comment: Comment
    @EnvironmentObject var session: SessionStore
    @State private var showingEditComment: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var editedCommentText: String = ""
    @State private var isUpdating: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.authorName.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(comment.authorName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("•")
                        .foregroundColor(Color.gray)
                    
                    Text(formatTimestamp(comment.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                    
                    if comment.authorId == session.currentUserId {
                        Menu {
                            Button {
                                editedCommentText = comment.text
                                showingEditComment = true
                            } label: {
                                Label("Edit Comment", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Comment", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.gray)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                    }
                }
                
                Text(comment.text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingEditComment) {
            editCommentSheet()
        }
        .alert("Delete Comment", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteComment()
            }
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }
    
    @ViewBuilder
    private func editCommentSheet() -> some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Edit Comment")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#1C1E25").opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#4A00E0"), lineWidth: 1.5)
                            )
                            .frame(minHeight: 80)

                        if editedCommentText.isEmpty {
                            Text("Enter your comment...")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#6A6A6A"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $editedCommentText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .background(Color.clear)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minHeight: 80)
                            .onAppear {
                                UITextView.appearance().backgroundColor = UIColor.clear
                            }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color(hex: "#0D0F14").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEditComment = false
                    }
                    .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateComment()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSaveComment() ? Color(hex: "#6E56E9") : Color(hex: "#B0B3BA"))
                    .disabled(!canSaveComment() || isUpdating)
                }
            }
        }
    }
    
    private func canSaveComment() -> Bool {
        let trimmed = editedCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != comment.text
    }
    
    private func updateComment() {
        guard let commentId = comment.id else { return }
        
        isUpdating = true
        let db = Firestore.firestore()
        
        db.collection("comments").document(commentId).updateData([
            "text": editedCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        ]) { error in
            DispatchQueue.main.async {
                self.isUpdating = false
                
                if error == nil {
                    self.showingEditComment = false
                } else {
                    print("[CommentsView] Error updating comment: \(error?.localizedDescription ?? "Unknown")")
                }
            }
        }
    }
    
    private func deleteComment() {
        guard let commentId = comment.id else { return }
        
        let db = Firestore.firestore()
        
        db.collection("comments").document(commentId).delete { error in
            if let error = error {
                print("[CommentsView] Error deleting comment: \(error.localizedDescription)")
            } else {
                print("[CommentsView] Comment deleted successfully")
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }
}

#if DEBUG
struct CommentsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockPost = FeedPost(
            authorId: "user1",
            authorName: "John Doe",
            authorPhotoURL: nil,
            type: .motivation,
            content: "Stay motivated and keep pushing!",
            imageURL: nil,
            timestamp: Timestamp(date: Date()),
            likes: []
        )
        
        CommentsView(post: mockPost)
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif
