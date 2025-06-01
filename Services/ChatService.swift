import Foundation
import FirebaseFirestore

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func getOrCreateChatDocument(clientId: String, dietitianId: String, completion: @escaping (String) -> Void) {
        let participantIds = [clientId, dietitianId].sorted()
        let chatId = "chat_\(participantIds.joined(separator: "_"))"
        let docRef = db.collection("chats").document(chatId)
        
        docRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                completion(chatId)
            } else {
                // Create new chat document using new Chat model
                let newChat = Chat(
                    participants: [clientId, dietitianId],
                    lastMessage: "",
                    updatedAt: Timestamp(date: Date()),
                    createdAt: Timestamp(date: Date())
                )
                
                do {
                    try docRef.setData(from: newChat) { error in
                        if let error = error {
                            print("Error creating chat document: \(error)")
                        }
                        completion(chatId)
                    }
                } catch {
                    print("Error encoding chat: \(error)")
                    completion(chatId) // Still return chatId even if creation failed
                }
            }
        }
    }
    
    func listenForMessages(chatId: String, onUpdate: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        return db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening for messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                
                let messages = documents.compactMap { doc -> ChatMessage? in
                    do {
                        return try doc.data(as: ChatMessage.self)
                    } catch {
                        print("Error decoding message \(doc.documentID): \(error)")
                        return nil
                    }
                }
                
                onUpdate(messages)
            }
    }
    
    func sendMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        text: String,
        completion: @escaping (Error?) -> Void
    ) {
        let newMessage = ChatMessage(
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Timestamp(date: Date())
        )
        
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        
        do {
            try messagesRef.addDocument(from: newMessage) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Update chat document with last message info
                let chatUpdateData: [String: Any] = [
                    "lastMessage": text,
                    "updatedAt": Timestamp(date: Date())
                ]
                
                self.db.collection("chats").document(chatId).updateData(chatUpdateData) { updateError in
                    completion(updateError)
                }
            }
        } catch {
            completion(error)
        }
    }
}
