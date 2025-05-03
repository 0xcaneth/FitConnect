import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable {
  let id: String
  let text: String
  let senderId: String
  let timestamp: Date

  var isFromDietitian: Bool {
    senderId != Auth.auth().currentUser?.uid
  }

  init(id: String, data: [String:Any]) {
    self.id        = id
    self.text      = data["text"]      as? String    ?? ""
    self.senderId  = data["senderId"]  as? String    ?? ""
    self.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
  }

  var asDictionary: [String:Any] {
    [
      "text": text,
      "senderId": senderId,
      "timestamp": FieldValue.serverTimestamp()
    ]
  }
}
