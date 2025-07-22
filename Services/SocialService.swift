import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// 🚀 PRODUCTION-READY Social Service for 10M+ users
/// Instagram + TikTok killer social features
@MainActor
final class SocialService: ObservableObject {
    
    static let shared = SocialService()
    
    // MARK: - Firebase References
    private let db = Firestore.firestore()
    private var sessionStore: SessionStore?
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - Published Properties (Real-time Updates)
    @Published var friendActivities: [SocialActivity] = []
    @Published var globalFeed: [SocialActivity] = []
    @Published var friendSuggestions: [FitConnectUser] = []
    @Published var trendingChallenges: [Challenge] = []
    @Published var socialStats: SocialStats = SocialStats()
    @Published var notifications: [SocialNotification] = []
    
    // MARK: - Loading States
    @Published var isLoadingFeed = false
    @Published var isLoadingFriends = false
    @Published var isLoadingChallenges = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Initialization & Configuration
    
    func configure(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        
        // Clear previous state
        stopAllListeners()
        clearData()
        cancellables.removeAll()
        
        // React to authentication state
        sessionStore.$isLoggedIn
            .combineLatest(sessionStore.$currentUserId)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] isLoggedIn, userId in
                guard let self = self else { return }
                
                if isLoggedIn, let userId = userId, !userId.isEmpty {
                    print("[SocialService] 🚀 User authenticated (ID: \(userId)). Starting social features...")
                    Task {
                        await self.startSocialServices(userId: userId)
                    }
                } else {
                    print("[SocialService] 🔒 User not authenticated. Stopping social services...")
                    self.stopAllListeners()
                    self.clearData()
                }
            }
            .store(in: &cancellables)
        
        // If already logged in, start immediately
        if sessionStore.isLoggedIn, let userId = sessionStore.currentUserId, !userId.isEmpty {
            Task {
                await startSocialServices(userId: userId)
            }
        }
    }
    
    private func startSocialServices(userId: String) async {
        print("[SocialService] 🎯 Starting all social services for user: \(userId)")
        
        // Start all social features simultaneously
        async let friendActivitiesTask = startFriendActivityFeed(userId: userId)
        async let globalFeedTask = startGlobalFeed()
        async let friendSuggestionsTask = loadFriendSuggestions(userId: userId)
        async let trendingChallengesTask = loadTrendingChallenges()
        async let socialStatsTask = loadSocialStats(userId: userId)
        async let notificationsTask = startNotificationListener(userId: userId)
        
        // Await all tasks
        do {
            let _ = try await (
                friendActivitiesTask,
                globalFeedTask,
                friendSuggestionsTask,
                trendingChallengesTask,
                socialStatsTask,
                notificationsTask
            )
            
            print("[SocialService] ✅ All social services started successfully")
        } catch {
            print("[SocialService] ❌ Error starting social services: \(error)")
            self.errorMessage = "Failed to load social features: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Friend Activity Feed (Instagram-style)
    
    private func startFriendActivityFeed(userId: String) async throws {
        print("[SocialService] 👥 Starting friend activity feed...")
        isLoadingFeed = true
        
        // Get user's following list first
        let followingIds = try await getUserFollowing(userId: userId)
        
        if followingIds.isEmpty {
            print("[SocialService] 📭 No friends to show activities for")
            self.friendActivities = []
            self.isLoadingFeed = false
            return
        }
        
        // Listen to friend activities in real-time
        let activitiesRef = db.collection("socialActivities")
            .whereField("userId", in: followingIds)
            .whereField("isPublic", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
        
        let listener = activitiesRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("[SocialService] ❌ Friend activity listener error: \(error)")
                    self.errorMessage = error.localizedDescription
                    self.isLoadingFeed = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("[SocialService] 📭 No friend activities found")
                    self.friendActivities = []
                    self.isLoadingFeed = false
                    return
                }
                
                print("[SocialService] 📱 Received \(documents.count) friend activities")
                
                self.friendActivities = documents.compactMap { doc in
                    do {
                        var activity = try doc.data(as: SocialActivity.self)
                        activity.id = doc.documentID
                        return activity
                    } catch {
                        print("[SocialService] ❌ Error decoding friend activity: \(error)")
                        return nil
                    }
                }
                
                self.isLoadingFeed = false
            }
        }
        
        listeners.append(listener)
    }
    
    // MARK: - Global Feed (TikTok For You Page style)
    
    private func startGlobalFeed() async throws {
        print("[SocialService] 🌍 Starting global feed...")
        
        // Global trending activities from all users
        let globalRef = db.collection("socialActivities")
            .whereField("isPublic", isEqualTo: true)
            .whereField("isTrending", isEqualTo: true)
            .order(by: "engagementScore", descending: true)
            .limit(to: 100)
        
        let listener = globalRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("[SocialService] ❌ Global feed listener error: \(error)")
                    return
                }
                
                self.globalFeed = snapshot?.documents.compactMap { doc in
                    do {
                        var activity = try doc.data(as: SocialActivity.self)
                        activity.id = doc.documentID
                        return activity
                    } catch {
                        print("[SocialService] ❌ Error decoding global activity: \(error)")
                        return nil
                    }
                } ?? []
                
                print("[SocialService] 🌍 Loaded \(self.globalFeed.count) global activities")
            }
        }
        
        listeners.append(listener)
    }
    
    // MARK: - Friend Suggestions (Instagram-style)
    
    private func loadFriendSuggestions(userId: String) async throws {
        print("[SocialService] 🔍 Loading friend suggestions...")
        isLoadingFriends = true
        
        // Get users with similar interests or mutual connections
        let suggestionsQuery = db.collection("users")
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "socialScore", descending: true)
            .limit(to: 20)
        
        let snapshot = try await suggestionsQuery.getDocuments()
        
        let suggestions = snapshot.documents.compactMap { doc -> FitConnectUser? in
            guard doc.documentID != userId else { return nil } // Don't suggest self
            
            do {
                var user = try doc.data(as: FitConnectUser.self)
                user.id = doc.documentID
                return user
            } catch {
                print("[SocialService] ❌ Error decoding user suggestion: \(error)")
                return nil
            }
        }
        
        // Filter out users already following
        let followingIds = try await getUserFollowing(userId: userId)
        let filteredSuggestions = suggestions.filter { user in
            guard let userID = user.id else { return false }
            return !followingIds.contains(userID)
        }
        
        self.friendSuggestions = Array(filteredSuggestions.prefix(10))
        self.isLoadingFriends = false
        
        print("[SocialService] ✅ Loaded \(self.friendSuggestions.count) friend suggestions")
    }
    
    // MARK: - Trending Challenges (TikTok Challenge style)
    
    private func loadTrendingChallenges() async throws {
        print("[SocialService] 📈 Loading trending challenges...")
        isLoadingChallenges = true
        
        let trendingQuery = db.collection("challenges")
            .whereField("isActive", isEqualTo: true)
            .order(by: "participantCount", descending: true)
            .limit(to: 10)
        
        let snapshot = try await trendingQuery.getDocuments()
        
        self.trendingChallenges = snapshot.documents.compactMap { doc in
            do {
                var challenge = try doc.data(as: Challenge.self)
                challenge.id = doc.documentID
                return challenge
            } catch {
                print("[SocialService] ❌ Error decoding trending challenge: \(error)")
                return nil
            }
        }
        
        self.isLoadingChallenges = false
        
        print("[SocialService] ✅ Loaded \(self.trendingChallenges.count) trending challenges")
    }
    
    // MARK: - Social Stats
    
    private func loadSocialStats(userId: String) async throws {
        print("[SocialService] 📊 Loading social stats...")
        
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data() else { return }
        
        let followerCount = userData["followersCount"] as? Int ?? 0
        let followingCount = userData["followingCount"] as? Int ?? 0
        let totalLikes = userData["totalLikesReceived"] as? Int ?? 0
        let engagementRate = userData["engagementRate"] as? Double ?? 0.0
        let socialScore = userData["socialScore"] as? Double ?? 0.0
        
        self.socialStats = SocialStats(
            followerCount: followerCount,
            followingCount: followingCount,
            totalLikes: totalLikes,
            engagementRate: engagementRate,
            socialScore: socialScore
        )
        
        print("[SocialService] 📊 Social stats: \(followerCount) followers, \(followingCount) following")
    }
    
    // MARK: - Notifications
    
    private func startNotificationListener(userId: String) async throws {
        print("[SocialService] 🔔 Starting notification listener...")
        
        let notificationsRef = db.collection("socialNotifications")
            .whereField("recipientId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
        
        let listener = notificationsRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let error = error {
                    print("[SocialService] ❌ Notifications listener error: \(error)")
                    return
                }
                
                self.notifications = snapshot?.documents.compactMap { doc in
                    do {
                        var notification = try doc.data(as: SocialNotification.self)
                        notification.id = doc.documentID
                        return notification
                    } catch {
                        print("[SocialService] ❌ Error decoding notification: \(error)")
                        return nil
                    }
                } ?? []
                
                print("[SocialService] 🔔 Loaded \(self.notifications.count) unread notifications")
            }
        }
        
        listeners.append(listener)
    }
    
    // MARK: - Social Actions (Instagram/TikTok-style interactions)
    
    func createActivity(
        type: SocialActivityType,
        content: String,
        imageURL: String? = nil,
        challengeId: String? = nil,
        workoutId: String? = nil,
        achievements: [String] = []
    ) async throws {
        
        guard let userId = sessionStore?.currentUserId,
              let user = sessionStore?.currentUser else {
            throw SocialError.userNotAuthenticated
        }
        
        print("[SocialService] 📝 Creating social activity: \(type.displayName)")
        
        let activity = SocialActivity(
            userId: userId,
            userName: user.fullName,
            userAvatar: user.profileImageURL,
            type: type,
            content: content,
            imageURL: imageURL,
            challengeId: challengeId,
            workoutId: workoutId,
            achievements: achievements,
            createdAt: Timestamp(date: Date()),
            isPublic: true,
            engagementScore: 0.0
        )
        
        try await db.collection("socialActivities").addDocument(from: activity)
        
        print("[SocialService] ✅ Social activity created successfully")
        
        // Update user's social score
        try await updateUserSocialScore(userId: userId, boost: 10)
    }
    
    func likeActivity(_ activityId: String) async throws {
        guard let userId = sessionStore?.currentUserId else {
            throw SocialError.userNotAuthenticated
        }
        
        let batch = db.batch()
        
        // Add like document
        let likeRef = db.collection("socialActivities")
            .document(activityId)
            .collection("likes")
            .document(userId)
        
        batch.setData([
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: likeRef)
        
        // Update activity like count and engagement
        let activityRef = db.collection("socialActivities").document(activityId)
        batch.updateData([
            "likesCount": FieldValue.increment(Int64(1)),
            "engagementScore": FieldValue.increment(Int64(1)),
            "lastEngagement": FieldValue.serverTimestamp()
        ], forDocument: activityRef)
        
        try await batch.commit()
        
        print("[SocialService] 👍 Liked activity: \(activityId)")
        
        // Send notification to activity owner
        try await sendEngagementNotification(
            activityId: activityId,
            type: .like,
            fromUserId: userId
        )
    }
    
    func unlikeActivity(_ activityId: String) async throws {
        guard let userId = sessionStore?.currentUserId else {
            throw SocialError.userNotAuthenticated
        }
        
        let batch = db.batch()
        
        // Remove like document
        let likeRef = db.collection("socialActivities")
            .document(activityId)
            .collection("likes")
            .document(userId)
        
        batch.deleteDocument(likeRef)
        
        // Update activity like count
        let activityRef = db.collection("socialActivities").document(activityId)
        batch.updateData([
            "likesCount": FieldValue.increment(Int64(-1)),
            "engagementScore": FieldValue.increment(Int64(-1))
        ], forDocument: activityRef)
        
        try await batch.commit()
        
        print("[SocialService] 👎 Unliked activity: \(activityId)")
    }
    
    func commentOnActivity(_ activityId: String, comment: String) async throws {
        guard let userId = sessionStore?.currentUserId,
              let user = sessionStore?.currentUser else {
            throw SocialError.userNotAuthenticated
        }
        
        let commentData = SocialComment(
            userId: userId,
            userName: user.fullName,
            userAvatar: user.profileImageURL,
            content: comment,
            createdAt: Timestamp(date: Date())
        )
        
        let batch = db.batch()
        
        // Add comment document
        let commentRef = db.collection("socialActivities")
            .document(activityId)
            .collection("comments")
            .document()
        
        try batch.setData(from: commentData, forDocument: commentRef)
        
        // Update activity comment count
        let activityRef = db.collection("socialActivities").document(activityId)
        batch.updateData([
            "commentsCount": FieldValue.increment(Int64(1)),
            "engagementScore": FieldValue.increment(Int64(2)), // Comments worth more than likes
            "lastEngagement": FieldValue.serverTimestamp()
        ], forDocument: activityRef)
        
        try await batch.commit()
        
        print("[SocialService] 💬 Commented on activity: \(activityId)")
        
        // Send notification to activity owner
        try await sendEngagementNotification(
            activityId: activityId,
            type: .comment,
            fromUserId: userId,
            content: comment
        )
    }
    
    func shareActivity(_ activityId: String, platform: SocialPlatform) async throws {
        guard let userId = sessionStore?.currentUserId else {
            throw SocialError.userNotAuthenticated
        }
        
        // Update share count
        try await db.collection("socialActivities")
            .document(activityId)
            .updateData([
                "sharesCount": FieldValue.increment(Int64(1)),
                "engagementScore": FieldValue.increment(Int64(5)), // Shares worth the most
                "lastEngagement": FieldValue.serverTimestamp()
            ])
        
        print("[SocialService] 📤 Shared activity: \(activityId) to \(platform.displayName)")
        
        // Track share analytics
        try await trackSocialAction(
            userId: userId,
            action: "share_activity",
            platform: platform.rawValue,
            activityId: activityId
        )
    }
    
    // MARK: - Challenge Social Features
    
    func createChallengePost(
        challengeId: String,
        challengeTitle: String,
        progress: Double,
        targetValue: Double,
        unit: String,
        message: String,
        imageURL: String? = nil
    ) async throws {
        
        let content = "\(message)\n\n💪 Progress: \(Int(progress))/\(Int(targetValue)) \(unit)"
        
        try await createActivity(
            type: .challengeProgress,
            content: content,
            imageURL: imageURL,
            challengeId: challengeId
        )
        
        print("[SocialService] 🎯 Created challenge progress post")
    }
    
    func completeChallenge(
        challengeId: String,
        challengeTitle: String,
        finalProgress: Double,
        achievements: [String] = []
    ) async throws {
        
        let content = "🎉 Just completed the '\(challengeTitle)' challenge! Final score: \(Int(finalProgress))"
        
        try await createActivity(
            type: .challengeCompleted,
            content: content,
            challengeId: challengeId,
            achievements: achievements
        )
        
        print("[SocialService] 🏆 Created challenge completion post")
        
        // Boost social score for completing challenges
        if let userId = sessionStore?.currentUserId {
            try await updateUserSocialScore(userId: userId, boost: 50)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserFollowing(userId: String) async throws -> [String] {
        let followingQuery = db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
        
        let snapshot = try await followingQuery.getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: UserFollow.self).followingId
        }
    }
    
    private func updateUserSocialScore(userId: String, boost: Int) async throws {
        try await db.collection("users").document(userId).updateData([
            "socialScore": FieldValue.increment(Int64(boost)),
            "lastSocialActivity": FieldValue.serverTimestamp()
        ])
    }
    
    private func sendEngagementNotification(
        activityId: String,
        type: SocialNotificationType,
        fromUserId: String,
        content: String? = nil
    ) async throws {
        
        // Get activity owner
        let activityDoc = try await db.collection("socialActivities").document(activityId).getDocument()
        guard let activityData = activityDoc.data(),
              let ownerId = activityData["userId"] as? String,
              ownerId != fromUserId else { return } // Don't notify self
        
        // Get sender info
        let senderDoc = try await db.collection("users").document(fromUserId).getDocument()
        guard let senderData = senderDoc.data(),
              let senderName = senderData["fullName"] as? String else { return }
        
        let notification = SocialNotification(
            recipientId: ownerId,
            senderId: fromUserId,
            senderName: senderName,
            senderAvatar: senderData["profileImageURL"] as? String,
            type: type,
            activityId: activityId,
            content: content,
            createdAt: Timestamp(date: Date()),
            isRead: false
        )
        
        try await db.collection("socialNotifications").addDocument(from: notification)
    }
    
    private func trackSocialAction(
        userId: String,
        action: String,
        platform: String,
        activityId: String
    ) async throws {
        
        let analytics = [
            "userId": userId,
            "action": action,
            "platform": platform,
            "activityId": activityId,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String: Any]
        
        try await db.collection("socialAnalytics").addDocument(data: analytics)
    }
    
    // MARK: - Cleanup
    
    private func stopAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        print("[SocialService] 🛑 Stopped all listeners")
    }
    
    private func clearData() {
        friendActivities.removeAll()
        globalFeed.removeAll()
        friendSuggestions.removeAll()
        trendingChallenges.removeAll()
        notifications.removeAll()
        socialStats = SocialStats()
        errorMessage = nil
        
        isLoadingFeed = false
        isLoadingFriends = false
        isLoadingChallenges = false
        
        print("[SocialService] 🧹 Cleared all data")
    }
    
    // MARK: - Public Utility Methods
    
    func hasUserLikedActivity(_ activityId: String) async -> Bool {
        guard let userId = sessionStore?.currentUserId else { return false }
        
        do {
            let doc = try await db.collection("socialActivities")
                .document(activityId)
                .collection("likes")
                .document(userId)
                .getDocument()
            
            return doc.exists
        } catch {
            print("[SocialService] ❌ Error checking like status: \(error)")
            return false
        }
    }
    
    func markNotificationAsRead(_ notificationId: String) async throws {
        try await db.collection("socialNotifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    func getUserEngagementMetrics(userId: String) async throws -> EngagementMetrics {
        // Get user's total likes, comments, shares across all activities
        let activitiesSnapshot = try await db.collection("socialActivities")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var totalLikes = 0
        var totalComments = 0
        var totalShares = 0
        
        for doc in activitiesSnapshot.documents {
            let data = doc.data()
            totalLikes += data["likesCount"] as? Int ?? 0
            totalComments += data["commentsCount"] as? Int ?? 0
            totalShares += data["sharesCount"] as? Int ?? 0
        }
        
        let totalPosts = activitiesSnapshot.documents.count
        let engagementRate = totalPosts > 0 ? Double(totalLikes + totalComments + totalShares) / Double(totalPosts) : 0.0
        
        return EngagementMetrics(
            totalPosts: totalPosts,
            totalLikes: totalLikes,
            totalComments: totalComments,
            totalShares: totalShares,
            engagementRate: engagementRate
        )
    }
}

// MARK: - Supporting Models

struct SocialActivity: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let userAvatar: String?
    let type: SocialActivityType
    let content: String
    let imageURL: String?
    let challengeId: String?
    let workoutId: String?
    let achievements: [String]
    let createdAt: Timestamp
    let isPublic: Bool
    var engagementScore: Double
    
    // Engagement metrics
    var likesCount: Int = 0
    var commentsCount: Int = 0
    var sharesCount: Int = 0
    var lastEngagement: Timestamp?
    var isTrending: Bool = false
}

enum SocialActivityType: String, Codable, CaseIterable {
    case workoutCompleted = "workout_completed"
    case challengeJoined = "challenge_joined"
    case challengeProgress = "challenge_progress"
    case challengeCompleted = "challenge_completed"
    case achievement = "achievement"
    case milestone = "milestone"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .workoutCompleted: return "Workout Completed"
        case .challengeJoined: return "Joined Challenge"
        case .challengeProgress: return "Challenge Progress"
        case .challengeCompleted: return "Challenge Completed"
        case .achievement: return "Achievement Unlocked"
        case .milestone: return "Milestone Reached"
        case .general: return "General Update"
        }
    }
    
    var icon: String {
        switch self {
        case .workoutCompleted: return "figure.run"
        case .challengeJoined: return "flag.fill"
        case .challengeProgress: return "chart.bar.fill"
        case .challengeCompleted: return "trophy.fill"
        case .achievement: return "star.fill"
        case .milestone: return "target"
        case .general: return "bubble.left.fill"
        }
    }
    
    var color: String {
        switch self {
        case .workoutCompleted: return "#FF6B6B"
        case .challengeJoined: return "#4ECDC4"
        case .challengeProgress: return "#45B7D1"
        case .challengeCompleted: return "#FFA726"
        case .achievement: return "#AB47BC"
        case .milestone: return "#66BB6A"
        case .general: return "#78909C"
        }
    }
}

struct SocialComment: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let userAvatar: String?
    let content: String
    let createdAt: Timestamp
}

struct SocialNotification: Identifiable, Codable {
    @DocumentID var id: String?
    let recipientId: String
    let senderId: String
    let senderName: String
    let senderAvatar: String?
    let type: SocialNotificationType
    let activityId: String?
    let content: String?
    let createdAt: Timestamp
    var isRead: Bool
}

enum SocialNotificationType: String, Codable {
    case like = "like"
    case comment = "comment"
    case follow = "follow"
    case challengeInvite = "challenge_invite"
    case achievement = "achievement"
    
    var displayText: String {
        switch self {
        case .like: return "liked your post"
        case .comment: return "commented on your post"
        case .follow: return "started following you"
        case .challengeInvite: return "invited you to a challenge"
        case .achievement: return "earned a new achievement"
        }
    }
    
    var icon: String {
        switch self {
        case .like: return "heart.fill"
        case .comment: return "bubble.left.fill"
        case .follow: return "person.badge.plus.fill"
        case .challengeInvite: return "flag.fill"
        case .achievement: return "star.fill"
        }
    }
}

enum SocialPlatform: String, CaseIterable {
    case instagram = "instagram"
    case tiktok = "tiktok"
    case twitter = "twitter"
    case snapchat = "snapchat"
    case facebook = "facebook"
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .twitter: return "Twitter/X"
        case .snapchat: return "Snapchat"
        case .facebook: return "Facebook"
        }
    }
}

struct SocialStats: Codable {
    let followerCount: Int
    let followingCount: Int
    let totalLikes: Int
    let engagementRate: Double
    let socialScore: Double
    
    init() {
        self.followerCount = 0
        self.followingCount = 0
        self.totalLikes = 0
        self.engagementRate = 0.0
        self.socialScore = 0.0
    }
    
    init(followerCount: Int, followingCount: Int, totalLikes: Int, engagementRate: Double, socialScore: Double) {
        self.followerCount = followerCount
        self.followingCount = followingCount
        self.totalLikes = totalLikes
        self.engagementRate = engagementRate
        self.socialScore = socialScore
    }
}

struct EngagementMetrics {
    let totalPosts: Int
    let totalLikes: Int
    let totalComments: Int
    let totalShares: Int
    let engagementRate: Double
}

// MARK: - Errors

enum SocialError: LocalizedError {
    case userNotAuthenticated
    case activityNotFound
    case permissionDenied
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "You must be logged in to perform this action"
        case .activityNotFound:
            return "Activity not found"
        case .permissionDenied:
            return "Permission denied for this action"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}