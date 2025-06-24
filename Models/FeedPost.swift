import Foundation
import FirebaseFirestore

struct FeedPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var authorPhotoURL: String?
    var type: FeedPostType
    var content: String
    var imageURL: String?
    var timestamp: Timestamp
    var likes: [String]
    
    init(authorId: String, authorName: String, authorPhotoURL: String? = nil, type: FeedPostType, content: String, imageURL: String? = nil, timestamp: Timestamp = Timestamp(date: Date()), likes: [String] = []) {
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.type = type
        self.content = content
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.likes = likes
    }
}

enum FeedPostType: String, Codable, CaseIterable {
    case badge = "badge"
    case achievement = "achievement"
    case motivation = "motivation"
    
    var displayName: String {
        switch self {
        case .badge:
            return "Badge"
        case .achievement:
            return "Achievement"
        case .motivation:
            return "Motivation"
        }
    }
    
    var iconName: String {
        switch self {
        case .badge:
            return "star.circle.fill"
        case .achievement:
            return "trophy.circle.fill"
        case .motivation:
            return "quote.bubble.fill"
        }
    }
}
