// Models/ChatMessage.swift

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Identifiable, Codable {
  @DocumentID var id: String?
  let text: String
  let senderId: String
  let timestamp: Date

  init(text: String, senderId: String, timestamp: Date = Date()) {
    self.id = nil
    self.text = text
    self.senderId = senderId
    self.timestamp = timestamp
  }

  // allow decoding from a Firestore snapshot
  init?(from doc: DocumentSnapshot) {
    guard
      let data = doc.data(),
      let text = data["text"] as? String,
      let senderId = data["senderId"] as? String,
      let ts = (data["timestamp"] as? Timestamp)?.dateValue()
    else { return nil }

    self.id = doc.documentID
    self.text = text
    self.senderId = senderId
    self.timestamp = ts
  }
}
