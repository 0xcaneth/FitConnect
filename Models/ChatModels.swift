import FirebaseFirestore

// Represents participant information.
struct ParticipantInfo: Hashable {
    var id: String
    var fullName: String
    var photoURL: String?

    init(id: String, fullName: String, photoURL: String? = nil) {
        self.id = id
        self.fullName = fullName
        self.photoURL = photoURL
    }

    // Initialize from Firestore dictionary
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let fullName = dictionary["fullName"] as? String else {
            return nil
        }
        self.id = id
        self.fullName = fullName
        self.photoURL = dictionary["photoURL"] as? String
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "fullName": fullName
        ]
        if let photoURL {
            dict["photoURL"] = photoURL
        }
        return dict
    }
}

// Represents a chat overview.
struct ChatSummary: Identifiable, Hashable {
    var id: String
    var participantIds: [String]
    var participantDetails: [String: ParticipantInfo]

    var lastMessageText: String?
    var lastMessageTimestamp: Timestamp?
    var lastMessageSenderId: String?
    var unreadCounts: [String: Int]

    var createdAt: Timestamp?
    var updatedAt: Timestamp?

    // Convenience init for creation
    init(chatId: String, client: ParticipantInfo, dietitian: ParticipantInfo) {
        self.id = chatId
        self.participantIds = [client.id, dietitian.id].sorted()
        self.participantDetails = [client.id: client, dietitian.id: dietitian]
        self.lastMessageText = "Chat started."
        self.lastMessageTimestamp = Timestamp(date: Date())
        self.lastMessageSenderId = nil
        self.unreadCounts = [client.id: 0, dietitian.id: 0]
        self.createdAt = Timestamp(date: Date())
        self.updatedAt = Timestamp(date: Date())
    }

    // Initialize from Firestore dictionary
    init?(documentID: String, dictionary: [String: Any]) {
        guard let participantIds = dictionary["participantIds"] as? [String],
              let participantDetailsDict = dictionary["participantDetails"] as? [String: [String: Any]],
              let unreadCounts = dictionary["unreadCounts"] as? [String: Int]
        else {
            print("Failed to parse required fields for ChatSummary")
            return nil
        }

        self.id = documentID
        self.participantIds = participantIds
        
        var details: [String: ParticipantInfo] = [:]
        for (key, value) in participantDetailsDict {
            if let participant = ParticipantInfo(dictionary: value) {
                details[key] = participant
            } else {
                print("Failed to parse participant detail for key \(key) in ChatSummary")
                return nil
            }
        }
        self.participantDetails = details
        self.unreadCounts = unreadCounts

        self.lastMessageText = dictionary["lastMessageText"] as? String
        self.lastMessageTimestamp = dictionary["lastMessageTimestamp"] as? Timestamp
        self.lastMessageSenderId = dictionary["lastMessageSenderId"] as? String
        self.createdAt = dictionary["createdAt"] as? Timestamp
        self.updatedAt = dictionary["updatedAt"] as? Timestamp
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "participantIds": participantIds,
            "participantDetails": participantDetails.mapValues { $0.toDictionary() },
            "unreadCounts": unreadCounts,
            "updatedAt": updatedAt ?? Timestamp(date:Date())
        ]
        if let lastMessageText { dict["lastMessageText"] = lastMessageText }
        if let lastMessageTimestamp { dict["lastMessageTimestamp"] = lastMessageTimestamp }
        if let lastMessageSenderId { dict["lastMessageSenderId"] = lastMessageSenderId }
        if let createdAt { dict["createdAt"] = createdAt }
        
        return dict
    }
    
    func otherParticipant(currentUserId: String) -> ParticipantInfo? {
        guard let otherId = participantIds.first(where: { $0 != currentUserId }) else { return nil }
        return participantDetails[otherId]
    }
}

enum MessageSendStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case sent = "sent"
    case failed = "failed"
}

enum AttachmentType: String, Codable, CaseIterable {
    case image = "image"
    case video = "video"
    case file = "file"
}

struct TypingIndicator: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var lastActive: Timestamp
    
    init(userId: String, userName: String) {
        self.id = userId
        self.userId = userId
        self.userName = userName
        self.lastActive = Timestamp(date: Date())
    }
    
    var isActive: Bool {
        let fiveSecondsAgo = Date().addingTimeInterval(-5)
        return lastActive.dateValue() > fiveSecondsAgo
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "userName": userName,
            "lastActive": lastActive
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let userId = dictionary["userId"] as? String,
              let userName = dictionary["userName"] as? String,
              let lastActive = dictionary["lastActive"] as? Timestamp else {
            return nil
        }
        self.id = userId
        self.userId = userId
        self.userName = userName
        self.lastActive = lastActive
    }
}

enum MessageSender {
    case currentUser
    case otherUser
}

struct ChatMessage: Identifiable, Hashable, Codable {
    var id: String
    var chatId: String
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Timestamp
    var isReadByRecipient: Bool
    var senderAvatarURL: String?
    
    var imageURL: String?
    var videoURL: String?
    var fileURL: String?
    var fileName: String?
    var fileSize: Int64?
    var messageSendStatus: MessageSendStatus?
    
    init(id: String? = nil, chatId: String, senderId: String, senderName: String, text: String, timestamp: Timestamp, isReadByRecipient: Bool = false, senderAvatarURL: String? = nil, imageURL: String? = nil, videoURL: String? = nil, fileURL: String? = nil, fileName: String? = nil, fileSize: Int64? = nil, messageSendStatus: MessageSendStatus? = nil) {
        self.id = id ?? UUID().uuidString
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.isReadByRecipient = isReadByRecipient
        self.senderAvatarURL = senderAvatarURL
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.messageSendStatus = messageSendStatus
    }

    init?(documentID: String, dictionary: [String: Any]) {
        guard let chatId = dictionary["chatId"] as? String,
              let senderId = dictionary["senderId"] as? String,
              let senderName = dictionary["senderName"] as? String,
              let text = dictionary["text"] as? String,
              let timestamp = dictionary["timestamp"] as? Timestamp
        else {
            print("Failed to parse required fields for ChatMessage from dictionary: \(dictionary)")
            return nil
        }
        self.id = documentID
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
        self.isReadByRecipient = dictionary["isReadByRecipient"] as? Bool ?? false
        self.senderAvatarURL = dictionary["senderAvatarURL"] as? String
        self.imageURL = dictionary["imageURL"] as? String
        self.videoURL = dictionary["videoURL"] as? String
        self.fileURL = dictionary["fileURL"] as? String
        self.fileName = dictionary["fileName"] as? String
        self.fileSize = dictionary["fileSize"] as? Int64
        
        if let statusString = dictionary["messageSendStatus"] as? String {
            self.messageSendStatus = MessageSendStatus(rawValue: statusString)
        }
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "chatId": chatId,
            "senderId": senderId,
            "senderName": senderName,
            "text": text,
            "timestamp": timestamp,
            "isReadByRecipient": isReadByRecipient
        ]
        if let senderAvatarURL {
            dict["senderAvatarURL"] = senderAvatarURL
        }
        if let imageURL {
            dict["imageURL"] = imageURL
        }
        if let videoURL {
            dict["videoURL"] = videoURL
        }
        if let fileURL {
            dict["fileURL"] = fileURL
        }
        if let fileName {
            dict["fileName"] = fileName
        }
        if let fileSize {
            dict["fileSize"] = fileSize
        }
        if let messageSendStatus {
            dict["messageSendStatus"] = messageSendStatus.rawValue
        }
        return dict
    }
    
    var hasAttachment: Bool {
        return imageURL != nil || videoURL != nil || fileURL != nil
    }
    
    var attachmentType: AttachmentType? {
        if imageURL != nil { return .image }
        if videoURL != nil { return .video }
        if fileURL != nil { return .file }
        return nil
    }
    
    var displayText: String {
        if !text.isEmpty {
            return text
        } else if let type = attachmentType {
            switch type {
            case .image: return "📸 Image"
            case .video: return "🎥 Video"
            case .file: return "📄 \(fileName ?? "File")"
            }
        }
        return ""
    }
}
