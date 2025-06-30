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
    var createdAt: Timestamp?
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
    var createdDate: Date { 
        createdAt?.dateValue() ?? Date()
    }

    /// Default initializer from Decoder for Firestore
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? DocumentID(wrappedValue: nil)
        authorId = try container.decode(String.self, forKey: .authorId)
        authorName = try container.decode(String.self, forKey: .authorName)
        authorAvatarURL = try container.decodeIfPresent(String.self, forKey: .authorAvatarURL)
        
        // Handle null createdAt gracefully
        createdAt = try container.decodeIfPresent(Timestamp.self, forKey: .createdAt)
        
        type = try container.decode(PostType.self, forKey: .type)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        badgeName = try container.decodeIfPresent(String.self, forKey: .badgeName)
        achievementName = try container.decodeIfPresent(String.self, forKey: .achievementName)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount) ?? 0
        status = try container.decodeIfPresent(PostStatus.self, forKey: .status)
    }

    // MARK: - Custom initializer
    init(authorId: String,
         authorName: String,
         authorAvatarURL: String? = nil,
         createdAt: Timestamp,
         type: PostType,
         category: String? = nil,
         content: String? = nil,
         badgeName: String? = nil,
         achievementName: String? = nil,
         imageURL: String? = nil,
         likesCount: Int = 0,
         commentsCount: Int = 0,
         status: PostStatus? = .published) {
        self.id = nil // Will be set by Firestore
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatarURL = authorAvatarURL
        self.createdAt = createdAt
        self.type = type
        self.category = category
        self.content = content
        self.badgeName = badgeName
        self.achievementName = achievementName
        self.imageURL = imageURL
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.status = status
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case authorId
        case authorName
        case authorAvatarURL
        case createdAt
        case type
        case category
        case content
        case badgeName
        case achievementName
        case imageURL
        case likesCount
        case commentsCount
        case status
    }

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