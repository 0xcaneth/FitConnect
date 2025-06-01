import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    let type: String
    
    init?(dict: [String: Any], id: String) {
        guard let senderId = dict["senderId"] as? String,
              let text = dict["text"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp,
              let type = dict["type"] as? String else {
            return nil
        }
        
        self.id = id
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp.dateValue()
        self.type = type
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}
