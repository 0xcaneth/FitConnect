import Foundation
import FirebaseFirestore

struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String // The user who receives the notification
    var type: NotificationType
    var fromUserId: String? // User who triggered the notification (e.g., liked the post)
    var fromUserName: String? // Name of the user who triggered
    var postId: String? // Relevant post ID, if any
    var postContentPreview: String? // A short preview of the post content
    var challengeId: String? // Relevant challenge ID, if any
    var challengeTitle: String? // Title of the challenge
    var message: String? // Generic message if not covered by other fields
    var timestamp: Timestamp
    var isRead: Bool = false

    // Enum for different notification types
    enum NotificationType: String, Codable {
        case newLike = "new_like"
        case newComment = "new_comment" // Future
        case newFollower = "new_follower" // Future
        case challengeCompleted = "challenge_completed" // Future
        case badgeUnlocked = "badge_unlocked" // Future
        case dietitianMessage = "dietitian_message" // Future
        case motivationPosted = "motivation_posted" // Future (for dietitian motivation posts)
        // Add other types as needed
    }
}