import Foundation
import FirebaseFirestore

struct Chat: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String] // Array of user UIDs
    var lastMessage: String
    var updatedAt: Timestamp
    var createdAt: Timestamp?
    
    init(participants: [String], lastMessage: String = "", updatedAt: Timestamp = Timestamp(date: Date()), createdAt: Timestamp = Timestamp(date: Date())) {
        self.participants = participants
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }
}
