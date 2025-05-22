// Services/ChatService.swift


class ChatService {
  private let col = Firestore.firestore().collection("chats")

  /// Send a new message
  func send(text: String, from userId: String) {
    let msg = ChatMessage(text: text, senderId: userId)
    do {
      _ = try col.addDocument(from: msg)
    } catch {
      print("ChatService › send error:", error)
    }
  }

  /// Listen for updates, returns a listener you can hold onto
  func listen(onUpdate: @escaping ([ChatMessage]) -> Void)
    -> ListenerRegistration
  {
    return col
      .order(by: "timestamp", descending: false)
      .addSnapshotListener { snap, err in
        guard let docs = snap?.documents else { return }
        let msgs = docs.compactMap(ChatMessage.init(from:))
        onUpdate(msgs)
      }
  }
}
