import Foundation
import FirebaseFirestore

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func getOrCreateChatDocument(clientId: String, dietitianId: String, completion: @escaping (String) -> Void) {
        let chatId = "chat_\(clientId)_\(dietitianId)"
        let docRef = db.collection("chats").document(chatId)
        
        docRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                completion(chatId)
            } else {
                // Create new chat document
                let data: [String: Any] = [
                    "clientId": clientId,
                    "dietitianId": dietitianId,
                    "lastMessage": "",
                    "lastUpdated": Timestamp(date: Date())
                ]
                
                docRef.setData(data) { error in
                    if let error = error {
                        print("Error creating chat document: \(error)")
                    }
                    completion(chatId)
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
                    let data = doc.data()
                    return ChatMessage(dict: data, id: doc.documentID)
                }
                
                onUpdate(messages)
            }
    }
    
    func sendMessage(
        chatId: String,
        senderId: String,
        text: String,
        clientId: String,
        dietitianId: String,
        completion: @escaping (Error?) -> Void
    ) {
        let messageData: [String: Any] = [
            "senderId": senderId,
            "text": text,
            "timestamp": Timestamp(date: Date()),
            "type": "text"
        ]
        
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        
        messagesRef.addDocument(data: messageData) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Update chat document with last message info
            let chatUpdateData: [String: Any] = [
                "lastMessage": text,
                "lastUpdated": Timestamp(date: Date())
            ]
            
            self.db.collection("chats").document(chatId).updateData(chatUpdateData) { updateError in
                completion(updateError)
            }
        }
    }
}
