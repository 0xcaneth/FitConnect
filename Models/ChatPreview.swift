import Foundation
import FirebaseFirestore

struct ChatPreview: Identifiable, Codable {
    var id: String?
    var participants: [String]
    var lastMessage: String
    var lastMessageTimestamp: Timestamp
    var unreadCounts: [String: Int]
    var clientName: String?
    var dietitianName: String?
    var clientAvatarURL: String?
    var dietitianAvatarURL: String?
    
    init(id: String? = nil, participants: [String], lastMessage: String = "", lastMessageTimestamp: Timestamp = Timestamp(date: Date()), unreadCounts: [String: Int] = [:], clientName: String? = nil, dietitianName: String? = nil, clientAvatarURL: String? = nil, dietitianAvatarURL: String? = nil) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCounts = unreadCounts
        self.clientName = clientName
        self.dietitianName = dietitianName
        self.clientAvatarURL = clientAvatarURL
        self.dietitianAvatarURL = dietitianAvatarURL
    }
    
    // Initialize from Firestore document
    init?(documentId: String, dictionary: [String: Any]) {
        guard let participants = dictionary["participants"] as? [String],
              let unreadCounts = dictionary["unreadCounts"] as? [String: Int] else {
            return nil
        }
        
        self.id = documentId
        self.participants = participants
        self.lastMessage = dictionary["lastMessage"] as? String ?? ""
        self.lastMessageTimestamp = dictionary["lastMessageTimestamp"] as? Timestamp ?? Timestamp(date: Date())
        self.unreadCounts = unreadCounts
        self.clientName = dictionary["clientName"] as? String
        self.dietitianName = dictionary["dietitianName"] as? String
        self.clientAvatarURL = dictionary["clientAvatarURL"] as? String
        self.dietitianAvatarURL = dictionary["dietitianAvatarURL"] as? String
    }
    
    func otherParticipantId(currentUid: String) -> String {
        return participants.first { $0 != currentUid } ?? ""
    }
    
    func getUnreadCount(for userId: String) -> Int {
        return unreadCounts[userId] ?? 0
    }
}