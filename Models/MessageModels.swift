import Foundation
import FirebaseFirestore

// MARK: - Message Types
enum MessageType: String, Codable, CaseIterable {
    case text = "text"
    case photo = "photo"
    case video = "video"
    case snap = "snap"
}

// MARK: - Core Message Model
struct Message: Identifiable, Codable, Hashable {
    var id: String
    var senderId: String
    var recipientId: String
    var timestamp: Timestamp
    var type: MessageType
    
    // Content fields
    var text: String?
    var contentUrl: String?
    
    // Snap-specific field
    var isConsumed: Bool?
    
    // Additional metadata
    var senderName: String?
    var senderAvatarUrl: String?
    
    init(id: String = UUID().uuidString,
         senderId: String,
         recipientId: String,
         timestamp: Timestamp = Timestamp(date: Date()),
         type: MessageType,
         text: String? = nil,
         contentUrl: String? = nil,
         isConsumed: Bool? = nil,
         senderName: String? = nil,
         senderAvatarUrl: String? = nil) {
        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.timestamp = timestamp
        self.type = type
        self.text = text
        self.contentUrl = contentUrl
        self.isConsumed = isConsumed
        self.senderName = senderName
        self.senderAvatarUrl = senderAvatarUrl
    }
    
    // Create from Firestore document
    init?(documentId: String, data: [String: Any]) {
        guard let senderId = data["senderId"] as? String,
              let recipientId = data["recipientId"] as? String,
              let timestamp = data["timestamp"] as? Timestamp,
              let typeString = data["type"] as? String,
              let type = MessageType(rawValue: typeString) else {
            return nil
        }
        
        self.id = documentId
        self.senderId = senderId
        self.recipientId = recipientId
        self.timestamp = timestamp
        self.type = type
        self.text = data["text"] as? String
        self.contentUrl = data["contentUrl"] as? String
        self.isConsumed = data["isConsumed"] as? Bool
        self.senderName = data["senderName"] as? String
        self.senderAvatarUrl = data["senderAvatarUrl"] as? String
    }
    
    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "senderId": senderId,
            "recipientId": recipientId,
            "timestamp": timestamp,
            "type": type.rawValue
        ]
        
        if let text = text { dict["text"] = text }
        if let contentUrl = contentUrl { dict["contentUrl"] = contentUrl }
        if let isConsumed = isConsumed { dict["isConsumed"] = isConsumed }
        if let senderName = senderName { dict["senderName"] = senderName }
        if let senderAvatarUrl = senderAvatarUrl { dict["senderAvatarUrl"] = senderAvatarUrl }
        
        return dict
    }
    
    // Check if message is a snap and consumed
    var isConsumedSnap: Bool {
        return type == .snap && (isConsumed ?? false)
    }
    
    // Get display text for message previews
    var displayText: String {
        switch type {
        case .text:
            return text ?? ""
        case .photo:
            return "📷 Photo"
        case .video:
            return "🎥 Video"
        case .snap:
            return isConsumedSnap ? "👻 Snap (viewed)" : "👻 Snap"
        }
    }
}

// MARK: - Conversation Preview Model
struct ConversationPreview: Identifiable, Hashable {
    let id: String // This will be the other participant's ID
    let otherUserName: String
    let otherUserAvatarUrl: String?
    let lastMessage: Message?
    let unreadCount: Int
    
    init(otherUserId: String, otherUserName: String, otherUserAvatarUrl: String? = nil, lastMessage: Message? = nil, unreadCount: Int = 0) {
        self.id = otherUserId
        self.otherUserName = otherUserName
        self.otherUserAvatarUrl = otherUserAvatarUrl
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
    }
}