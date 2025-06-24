import FirebaseFirestore

struct Chat: Identifiable, Codable, Hashable {
    var id: String? // Will be manually set
    
    var participantIds: [String]
    var participantNames: [String: String]
    var participantAvatars: [String: String?]

    var lastMessageText: String?
    var lastMessageTimestamp: Timestamp?
    var lastMessageSenderId: String?
    
    var unreadCounts: [String: Int]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    // Manual initializer from Firestore data
    init?(id: String, data: [String: Any]) {
        guard let participantIds = data["participantIds"] as? [String],
              let participantNames = data["participantNames"] as? [String: String],
              let unreadCounts = data["unreadCounts"] as? [String: Int] else {
            print("[Chat] Failed to parse required fields from data: \(data)")
            return nil
        }
        self.id = id
        self.participantIds = participantIds
        self.participantNames = participantNames
        
        if let avatars = data["participantAvatars"] as? [String: Any] {
            var avatarDict: [String: String?] = [:]
            for (key, value) in avatars {
                if let stringValue = value as? String {
                    avatarDict[key] = stringValue
                } else {
                    avatarDict[key] = nil
                }
            }
            self.participantAvatars = avatarDict
        } else {
            self.participantAvatars = [:]
        }
        
        self.lastMessageText = data["lastMessageText"] as? String
        self.lastMessageTimestamp = data["lastMessageTimestamp"] as? Timestamp
        self.lastMessageSenderId = data["lastMessageSenderId"] as? String
        self.unreadCounts = unreadCounts
        self.createdAt = data["createdAt"] as? Timestamp
        self.updatedAt = data["updatedAt"] as? Timestamp
    }

    init?(documentId: String, dictionary: [String: Any]) {
        self.init(id: documentId, data: dictionary)
    }

    // Initializer for creating new chats
    init(id: String? = nil,
         participantIds: [String],
         participantNames: [String: String],
         participantAvatars: [String: String?],
         lastMessageText: String? = nil,
         lastMessageTimestamp: Timestamp? = nil,
         lastMessageSenderId: String? = nil,
         unreadCounts: [String: Int] = [:],
         createdAt: Timestamp? = Timestamp(date: Date()),
         updatedAt: Timestamp? = Timestamp(date: Date())) {
        self.id = id
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.participantAvatars = participantAvatars
        self.lastMessageText = lastMessageText
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        
        var initialUnreadCounts = unreadCounts
        for pId in participantIds {
            if initialUnreadCounts[pId] == nil {
                initialUnreadCounts[pId] = 0
            }
        }
        self.unreadCounts = initialUnreadCounts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Function to convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "participantIds": participantIds,
            "participantNames": participantNames,
            "participantAvatars": participantAvatars.compactMapValues { $0 }, // Remove nil avatar URLs if any when converting to dictionary
            "unreadCounts": unreadCounts
        ]
        if let lastMessageText = lastMessageText { dict["lastMessageText"] = lastMessageText }
        if let lastMessageTimestamp = lastMessageTimestamp { dict["lastMessageTimestamp"] = lastMessageTimestamp }
        if let lastMessageSenderId = lastMessageSenderId { dict["lastMessageSenderId"] = lastMessageSenderId }
        if let createdAt = createdAt { dict["createdAt"] = createdAt }
        if let updatedAt = updatedAt { dict["updatedAt"] = updatedAt }
        // id is typically not stored as a field in Firestore document if it's the document ID
        return dict
    }
    
    func otherParticipantId(currentUserUID: String) -> String? {
        return participantIds.first(where: { $0 != currentUserUID })
    }
    
    func getParticipantName(for uid: String) -> String? {
        return participantNames[uid]
    }

    func getParticipantAvatar(for uid: String) -> String?? { // Double optional because dictionary lookup returns optional, and value itself is optional string
        return participantAvatars[uid]
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Chat, rhs: Chat) -> Bool {
        lhs.id == rhs.id
    }
}
