import Foundation
import FirebaseFirestore

struct Flag: Codable, Identifiable {
    @DocumentID var id: String?
    var flaggedUserId: String
    var flaggedByUserId: String // UID of the dietitian/moderator
    var reason: String? // Optional: if you want to allow a reason for flagging
    var timestamp: Timestamp
    
    init(id: String? = nil, flaggedUserId: String, flaggedByUserId: String, reason: String? = nil, timestamp: Timestamp = Timestamp(date:Date())) {
        self.id = id
        self.flaggedUserId = flaggedUserId
        self.flaggedByUserId = flaggedByUserId
        self.reason = reason
        self.timestamp = timestamp
    }
}