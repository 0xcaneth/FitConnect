import Foundation
import FirebaseFirestore

/// Enum for Post Status
enum PostStatus: String, Codable, CaseIterable {
    case pending
    case published
    case rejected
    // Potentially more statuses like 'archived' or 'flagged_for_review'
}

/// Firestore 'posts' belgesini temsil eden model
struct Post: Identifiable, Codable, Hashable {
    // MARK: - Document fields
    @DocumentID var id: String?                // Firestore'un oto-ID'si
    var authorId: String                       // UID
    var authorName: String
    var authorAvatarURL: String?               // optional
    var createdAt: Timestamp                   // Firestore timestamp
    var type: PostType                         // badge / achievement / motivation
    var category: String?                      // e.g., "Fitness & Activity", "Nutrition & Health"
    var content: String?                       // motivasyon sözü veya achievement description
    var badgeName: String?                     // type == .badge
    var achievementName: String?               // type == .achievement, stores the specific achievement *name* if predefined, or can be nil if only category + custom description
    var imageURL: String?                      // kullanıcı resmi
    var likesCount: Int                        // default 0
    var commentsCount: Int                     // default 0
    var status: PostStatus?
    
    // MARK: - Helpers (not persisted)
    var createdDate: Date { createdAt.dateValue() }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}

/// Enum ‑ Firestore'da `type` alanına karşılık gelir.
/// FirestoreCodable desteği için `String` rawValue kullanıyoruz.
enum PostType: String, Codable, Hashable, CaseIterable {
    case badge
    case achievement
    case motivation
}

struct PostLike: Identifiable, Codable {
    // likes alt koleksiyonunda doküman id = likerId
    @DocumentID var id: String?
    var likerId: String
    var createdAt: Timestamp
    
    var createdDate: Date { createdAt.dateValue() }
}

struct PostComment: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var commenterId: String
    var commenterName: String
    var commenterAvatarURL: String?
    var text: String
    var createdAt: Timestamp
    
    var createdDate: Date { createdAt.dateValue() }

    static func == (lhs: PostComment, rhs: PostComment) -> Bool {
        lhs.id == rhs.id && // Primary check
        lhs.text == rhs.text && // Check text for content changes
        lhs.commenterId == rhs.commenterId // Ensure same commenter
        // Add other fields if they are relevant for equality in your context
    }
}