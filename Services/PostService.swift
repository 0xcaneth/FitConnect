import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine

/// Sosyal besleme (posts) ile ilgili Firestore işlemlerini kapsüller.
@MainActor
final class PostService: ObservableObject {
    
    static let shared = PostService()
    private var sessionStore: SessionStore?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialization remains private for singleton
    }

    func configure(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        // Clear previous state if any
        self.posts = []
        self.stopListening() // Stop any existing listener
        self.cancellables.removeAll() // Clear previous subscriptions

        sessionStore.$isLoggedIn
            .combineLatest(sessionStore.$currentUserId)
            .sink { [weak self] isLoggedIn, userId in
                guard let self = self else { return }
                if isLoggedIn && userId != nil && !userId!.isEmpty {
                    print("[PostService] User is authenticated (ID: \(userId!)). Starting feed listener.")
                    self.startListeningFeedInternal()
                } else {
                    print("[PostService] User is not authenticated or ID is empty. Stopping feed listener and clearing posts.")
                    self.stopListening()
                    self.posts = []
                }
            }
            .store(in: &cancellables)
        
        // If already logged in, start listening immediately
        if sessionStore.isLoggedIn && sessionStore.currentUserId != nil && !sessionStore.currentUserId!.isEmpty {
            startListeningFeedInternal()
        }
    }
    
    // MARK: - Firestore paths
    private let db = Firestore.firestore()
    private var postCollection: CollectionReference {
        db.collection("posts")
    }
    private var flagsCollection: CollectionReference {
        db.collection("flags")
    }
    private var reportsCollection: CollectionReference {
        db.collection("reports")
    }
    private var storageRef: StorageReference {
        Storage.storage().reference()
    }
    
    // MARK: - Publishers
    /// Global feed (tüm postlar) – real-time.
    @Published private(set) var posts: [Post] = []
    private var listener: ListenerRegistration?
    
    private func startListeningFeedInternal() {
        guard let sessionStore = sessionStore,
              sessionStore.isLoggedIn,
              let userId = sessionStore.currentUserId,
              !userId.isEmpty else {
            print("[PostService] startListeningFeedInternal called but user is not authenticated. Aborting.")
            return
        }
        
        if listener != nil {
            print("[PostService] Listener already active. Not starting a new one.")
            return
        }
        
        print("[PostService] Initializing Firestore listener for posts collection.")
        listener = postCollection
            .whereField("status", isEqualTo: "published") // Only show published posts
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                if let error = error {
                    print("[PostService] Feed listener error: \(error.localizedDescription)")
                    if let firestoreError = error as NSError?, firestoreError.code == FirestoreErrorCode.permissionDenied.rawValue {
                        print("[PostService] PERMISSION DENIED while listening to feed. Check Firestore rules and authentication state.")
                        self.posts = []
                    }
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("[PostService] Feed snapshot is nil or has no documents.")
                    self.posts = []
                    return
                }
                print("[PostService] Feed snapshot received with \(documents.count) documents.")
                let newPosts = documents.compactMap { doc in
                    do {
                        var post = try doc.data(as: Post.self)
                        post.id = doc.documentID // Manually set ID
                        return post
                    } catch {
                        print("[PostService] Error decoding post document \(doc.documentID): \(error)")
                        return nil
                    }
                }
                self.posts = newPosts
            }
    }
    
    func stopListening() {
        if listener != nil {
            print("[PostService] Removing Firestore listener.")
            listener?.remove()
            listener = nil
        } else {
            print("[PostService] stopListening called but no active listener to remove.")
        }
    }
    
    // MARK: - CRUD
    
    func uploadPostImage(imageData: Data, forUser userId: String) async throws -> String {
        let imageUUID = UUID().uuidString
        let imagePath = "post_images/\(userId)/\(imageUUID).jpg"
        let imageRef = storageRef.child(imagePath)

        print("[PostService] Uploading image to: \(imagePath)")
        return try await withCheckedThrowingContinuation { continuation in
            imageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print("[PostService] Image upload error: \(error.localizedDescription)")
                    continuation.resume(throwing: PostServiceError.imageUploadFailed(error.localizedDescription))
                    return
                }
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("[PostService] Get download URL error: \(error.localizedDescription)")
                        continuation.resume(throwing: PostServiceError.imageUploadFailed(error.localizedDescription))
                        return
                    }
                    guard let downloadURL = url else {
                        print("[PostService] Download URL is nil after successful upload.")
                        continuation.resume(throwing: PostServiceError.imageUploadFailed("Download URL was nil."))
                        return
                    }
                    print("[PostService] Image uploaded successfully. URL: \(downloadURL.absoluteString)")
                    continuation.resume(returning: downloadURL.absoluteString)
                }
            }
        }
    }

    func createPost(_ postInput: Post) async throws {
        guard let currentUid = sessionStore?.currentUserId, !currentUid.isEmpty, postInput.authorId == currentUid else {
            print("[PostService] CreatePost precondition failed: User not authenticated or authorId mismatch.")
            throw PostServiceError.permissionDenied
        }
        
        var postData: [String: Any] = [
            "authorId": postInput.authorId,
            "authorName": postInput.authorName,
            "createdAt": FieldValue.serverTimestamp(),
            "type": postInput.type.rawValue,
            "likesCount": 0,
            "commentsCount": 0,
            "status": PostStatus.published.rawValue, // Auto-publish for now
            "content": postInput.content ?? ""
        ]
        
        if let avatarURL = postInput.authorAvatarURL { postData["authorAvatarURL"] = avatarURL }
        if let category = postInput.category { postData["category"] = category }
        if let badgeName = postInput.badgeName { postData["badgeName"] = badgeName }
        if let achievementName = postInput.achievementName { postData["achievementName"] = achievementName }
        if let imageURL = postInput.imageURL { postData["imageURL"] = imageURL }

        print("[PostService] Creating post for author: \(postInput.authorId) with data: \(postData)")
        do {
            _ = try await postCollection.addDocument(data: postData)
        } catch {
            print("[PostService] Firestore error creating post: \(error.localizedDescription)")
            throw PostServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    func deletePost(_ post: Post) async throws {
        guard let postId = post.id else {
            throw PostServiceError.unknown
        }
        guard let currentUid = sessionStore?.currentUserId,
              let currentUserRole = sessionStore?.role else {
            throw ModerationError.permissionDenied("delete post (not authenticated)")
        }

        if !(post.authorId == currentUid || currentUserRole == "dietitian") {
             throw ModerationError.permissionDenied("delete this post")
        }

        print("[PostService] Deleting post \(postId)")
        do {
            try await postCollection.document(postId).delete()
        } catch {
            print("[PostService] Error deleting post \(postId): \(error.localizedDescription)")
            throw PostServiceError.firestoreError(error.localizedDescription)
        }
    }
    
    // MARK: - Likes
    
    func like(post: Post, by userId: String) async throws {
        guard let postId = post.id else { 
            print("[PostService] 🚫 Like failed: Post ID is nil")
            throw PostServiceError.unknown 
        }
        
        print("[PostService] 👍 Attempting to like post \(postId) by user \(userId)")
        
        let likeRef = postCollection.document(postId).collection("likes").document(userId)
        let batch = db.batch()
        
        let likeData: [String: Any] = [
            "likerId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        batch.setData(likeData, forDocument: likeRef, merge: true)
        batch.updateData(["likesCount": FieldValue.increment(Int64(1))], forDocument: postCollection.document(postId))
        
        do {
            try await batch.commit()
            print("[PostService] 📈 Like successful for post \(postId)")
        } catch {
            print("[PostService] 🚫 Like failed for post \(postId): \(error.localizedDescription)")
            throw error
        }
    }
    
    func unlike(post: Post, by userId: String) async throws {
        guard let postId = post.id else { 
            print("[PostService] 🚫 Unlike failed: Post ID is nil")
            throw PostServiceError.unknown 
        }
        
        print("[PostService] 👎 Attempting to unlike post \(postId) by user \(userId)")
        
        let likeRef = postCollection.document(postId).collection("likes").document(userId)
        let batch = db.batch()
        
        batch.deleteDocument(likeRef)
        batch.updateData(["likesCount": FieldValue.increment(Int64(-1))], forDocument: postCollection.document(postId))
        
        do {
            try await batch.commit()
            print("[PostService] 📉 Unlike successful for post \(postId)")
        } catch {
            print("[PostService] 🚫 Unlike failed for post \(postId): \(error.localizedDescription)")
            throw error
        }
    }
    
    func hasUserLiked(post: Post, userId: String) async throws -> Bool {
        guard let postId = post.id else { 
            print("[PostService] 🚫 hasUserLiked check failed: Post ID is nil")
            return false 
        }
        
        do {
            let doc = try await postCollection.document(postId).collection("likes").document(userId).getDocument()
            let liked = doc.exists
            print("[PostService] 🔍 User \(userId) like status for post \(postId): \(liked)")
            return liked
        } catch {
            print("[PostService] 🚫 Error checking like status: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Comments
    
    func addComment(to post: Post, comment: PostComment) async throws {
        guard let postId = post.id else { 
            print("[PostService] ❌ Add comment failed: Post ID is nil")
            throw PostServiceError.unknown 
        }
        guard let currentUid = sessionStore?.currentUserId, !currentUid.isEmpty, comment.commenterId == currentUid else {
            print("[PostService] ❌ Add comment failed: Authentication error")
            throw ModerationError.permissionDenied("add comment (ID mismatch or not authenticated)")
        }
        
        print("[PostService] 💬 Adding comment to post \(postId) by user \(currentUid)")
        
        let commentsRef = postCollection.document(postId).collection("comments")
        let newCommentRef = commentsRef.document()
        
        var commentData: [String: Any] = [
            "commenterId": comment.commenterId,
            "commenterName": comment.commenterName,
            "text": comment.text,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let avatarURL = comment.commenterAvatarURL { 
            commentData["commenterAvatarURL"] = avatarURL 
        }
        
        let batch = db.batch()
        batch.setData(commentData, forDocument: newCommentRef)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(1))], forDocument: postCollection.document(postId))
        
        do {
            try await batch.commit()
            print("[PostService] ✅ Comment added successfully to post \(postId)")
        } catch {
            print("[PostService] ❌ Add comment failed for post \(postId): \(error.localizedDescription)")
            throw error
        }
    }
    
    func listenComments(for postId: String, completion: @escaping ([PostComment]) -> Void) -> ListenerRegistration {
        print("[PostService] 👂 Starting to listen comments for post \(postId)")
        
        return postCollection.document(postId)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("[PostService] ❌ Comments listener error for post \(postId): \(error.localizedDescription)")
                    completion([])
                    return
                }
                guard let documents = snapshot?.documents else {
                    print("[PostService] 📭 No comments found for post \(postId)")
                    completion([])
                    return
                }
                
                print("[PostService] 📬 Found \(documents.count) comments for post \(postId)")
                
                let comments = documents.compactMap { doc -> PostComment? in
                    do {
                        var comment = try doc.data(as: PostComment.self)
                        comment.id = doc.documentID 
                        return comment
                    } catch {
                        print("[PostService] ❌ Error decoding comment \(doc.documentID): \(error)")
                        return nil
                    }
                }
                completion(comments)
            }
    }

    // MARK: - Moderation Functions

    /// **Flag User** (Dietitian action)
    func flagUser(flaggedUserId: String, reason: String? = nil) async throws {
        guard let flaggedByUserId = sessionStore?.currentUserId, sessionStore?.role == "dietitian" else {
            throw ModerationError.permissionDenied("flag user (not a dietitian or not authenticated)")
        }
        
        let flagData = Flag(flaggedUserId: flaggedUserId, flaggedByUserId: flaggedByUserId, reason: reason)
        
        do {
            _ = try await flagsCollection.addDocument(from: flagData)
            print("[PostService] User \(flaggedUserId) flagged by \(flaggedByUserId).")
        } catch {
            print("[PostService] Error flagging user \(flaggedUserId): \(error.localizedDescription)")
            throw ModerationError.firestoreError("flagging user: \(error.localizedDescription)")
        }
    }

    /// **Approve Post** (Dietitian or Author action)
    func approvePost(_ post: Post, newStatus: PostStatus = .published) async throws {
        guard let postId = post.id else { throw PostServiceError.unknown }
        guard let currentUid = sessionStore?.currentUserId,
              let currentUserRole = sessionStore?.role else {
            throw ModerationError.permissionDenied("approve post (not authenticated)")
        }

        if !(post.authorId == currentUid || currentUserRole == "dietitian") {
            throw ModerationError.permissionDenied("approve this post")
        }

        print("[PostService] Approving post \(postId) to status \(newStatus.rawValue)")
        do {
            try await postCollection.document(postId).updateData(["status": newStatus.rawValue])
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].status = newStatus
            }
        } catch {
            print("[PostService] Error approving post \(postId): \(error.localizedDescription)")
            throw ModerationError.firestoreError("approving post: \(error.localizedDescription)")
        }
    }

    /// **Report Post** (Authenticated user action)
    func reportPost(_ post: Post, reason: String) async throws {
        guard let postId = post.id, let reportedByUserId = sessionStore?.currentUserId else {
            throw ModerationError.permissionDenied("report post (not authenticated or post ID missing)")
        }
        
        let reportData = Report(postId: postId,
                                reportedContentCreatorId: post.authorId,
                                reportedByUserId: reportedByUserId,
                                reason: reason)
        do {
            _ = try await reportsCollection.addDocument(from: reportData)
            print("[PostService] Post \(postId) reported by \(reportedByUserId) for reason: \(reason)")
        } catch {
            print("[PostService] Error reporting post \(postId): \(error.localizedDescription)")
            throw ModerationError.firestoreError("reporting post: \(error.localizedDescription)")
        }
    }
    
    /// **Report Comment** (Authenticated user action)
    func reportComment(postId: String, comment: PostComment, reason: String) async throws {
        guard let commentId = comment.id, let reportedByUserId = sessionStore?.currentUserId else {
            throw ModerationError.permissionDenied("report comment (not authenticated or comment ID missing)")
        }

        let reportData = Report(postId: postId,
                                commentId: commentId,
                                reportedContentCreatorId: comment.commenterId,
                                reportedByUserId: reportedByUserId,
                                reason: reason)
        do {
            _ = try await reportsCollection.addDocument(from: reportData)
            print("[PostService] Comment \(commentId) in post \(postId) reported by \(reportedByUserId) for: \(reason)")
        } catch {
            print("[PostService] Error reporting comment \(commentId): \(error.localizedDescription)")
            throw ModerationError.firestoreError("reporting comment: \(error.localizedDescription)")
        }
    }

    /// **Delete Comment** (Dietitian or Author action)
    func deleteComment(postId: String, commentId: String) async throws {
        guard let currentUid = sessionStore?.currentUserId,
              let currentUserRole = sessionStore?.role else {
            throw ModerationError.permissionDenied("delete comment (not authenticated)")
        }

        print("[PostService] Deleting comment \(commentId) from post \(postId)")
        let commentRef = postCollection.document(postId).collection("comments").document(commentId)
        let postRef = postCollection.document(postId)
        
        let batch = db.batch()
        batch.deleteDocument(commentRef)
        batch.updateData(["commentsCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
        
        do {
            try await batch.commit()
        } catch {
            print("[PostService] Error deleting comment \(commentId): \(error.localizedDescription)")
            throw ModerationError.firestoreError("deleting comment: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Typing Indicator Functions
    func setTypingIndicator(forPostId postId: String, userId: String, userName: String, isTyping: Bool) async throws {
        let indicatorRef = postCollection.document(postId).collection("typingIndicators").document(userId)
        if isTyping {
            let indicatorData: [String: Any] = [
                "userId": userId,
                "userName": userName,
                "lastActive": FieldValue.serverTimestamp()
            ]
            try await indicatorRef.setData(indicatorData, merge: true)
        } else {
            try await indicatorRef.delete()
        }
    }

    func listenForTypingIndicators(inPostId postId: String, completion: @escaping ([String]) -> Void) -> ListenerRegistration {
        let indicatorsRef = postCollection.document(postId).collection("typingIndicators")
        
        return indicatorsRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("[PostService] Typing indicators listener error for post \(postId): \(error.localizedDescription)")
                completion([])
                return
            }
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let now = Timestamp(date: Date())
            let activeUserNames = documents.compactMap { doc -> String? in
                let data = doc.data()
                guard let userName = data["userName"] as? String,
                      let lastActive = data["lastActive"] as? Timestamp else { return nil }
                
                // Check if indicator is still active (within 10 seconds)
                if now.seconds - lastActive.seconds > 10 {
                    return nil
                }
                return userName
            }
            completion(activeUserNames)
        }
    }
}

enum ModerationError: Error, LocalizedError {
    case permissionDenied(String)
    case firestoreError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let action):
            return "You do not have permission to \(action)."
        case .firestoreError(let message):
            return "A server error occurred: \(message). Please try again."
        case .unknown(let message):
            return "An unknown error occurred: \(message). Please try again."
        }
    }
}

enum PostServiceError: Error, LocalizedError {
    case permissionDenied
    case firestoreError(String)
    case imageUploadFailed(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "You do not have permission to perform this action. Please check your login status."
        case .firestoreError(let message):
            return "Failed to save post. Please try again. (Error: \(message))"
        case .imageUploadFailed(let message):
            return "Failed to upload image. Please try again. (Error: \(message))"
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}