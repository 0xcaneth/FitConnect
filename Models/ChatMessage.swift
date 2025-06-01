import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Timestamp
    
    init(senderId: String, senderName: String, text: String, timestamp: Timestamp = Timestamp(date: Date())) {
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
    }
}
