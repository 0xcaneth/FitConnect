import Foundation
import FirebaseFirestore

struct UserActivity: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var type: String // "workout", "meal", "achievement", etc.
    var title: String
    var description: String
    var iconName: String
    var timestamp: Timestamp
    var metadata: [String: String]? // Optional additional data
    
    init(userId: String, type: String, title: String, description: String, iconName: String, timestamp: Timestamp = Timestamp(date: Date()), metadata: [String: String]? = nil) {
        self.userId = userId
        self.type = type
        self.title = title
        self.description = description
        self.iconName = iconName
        self.timestamp = timestamp
        self.metadata = metadata
    }
}