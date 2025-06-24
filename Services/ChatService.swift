import Foundation
import FirebaseFirestore
import Combine

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()

    private var chatsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    deinit {
        chatsListener?.remove()
        messagesListener?.remove()
    }

    // MARK: - Chat Management

    func getOrCreateChat(client: ParticipantInfo, dietitian: ParticipantInfo, completion: @escaping (Result<ChatSummary, Error>) -> Void) {
        let chatId = ChatHelpers.generateChatId(userId1: client.id, userId2: dietitian.id)
        let chatRef = db.collection("chats").document(chatId)

        chatRef.getDocument { documentSnapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let documentSnapshot, documentSnapshot.exists, let data = documentSnapshot.data() {
                // Chat exists
                if let chat = ChatSummary(documentID: documentSnapshot.documentID, dictionary: data) {
                    completion(.success(chat))
                } else {
                    completion(.failure(NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse existing chat data."])))
                }
            } else {
                // Chat doesn't exist, create it
                let newChat = ChatSummary(chatId: chatId, client: client, dietitian: dietitian)
                chatRef.setData(newChat.toDictionary()) { error in
                    if let error {
                        completion(.failure(error))
                    } else {
                        completion(.success(newChat))
                    }
                }
            }
        }
    }
    
    func observeChats(forUserId userId: String, completion: @escaping (Result<[ChatSummary], Error>) -> Void) -> ListenerRegistration {
        chatsListener?.remove()
        
        let query = db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)

        chatsListener = query.addSnapshotListener { querySnapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            let chats = documents.compactMap { doc -> ChatSummary? in
                guard let data = doc.data() as [String: Any]? else {
                    // This guard now checks if data is nil after the cast.
                    // If doc.data() was truly non-optional, `as [String: Any]?` makes it optional.
                    // If doc.data() was already optional, this doesn't change its optionality for the guard.
                    return nil
                }
                return ChatSummary(documentID: doc.documentID, dictionary: data)
            }
            completion(.success(chats))
        }
        return chatsListener!
    }

    // MARK: - Message Management
    
    func observeMessages(chatId: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) -> ListenerRegistration {
        messagesListener?.remove()
        
        let query = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)

        messagesListener = query.addSnapshotListener { querySnapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            let messages = documents.compactMap { doc -> ChatMessage? in
                guard let data = doc.data() as [String: Any]? else {
                    return nil
                }
                return ChatMessage(documentID: doc.documentID, dictionary: data)
            }
            completion(.success(messages))
        }
        return messagesListener!
    }

    func sendMessage(chatId: String, sender: ParticipantInfo, text: String, recipientId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageData = ChatMessage(
            chatId: chatId,
            senderId: sender.id,
            senderName: sender.fullName,
            text: text,
            timestamp: Timestamp(date: Date()),
            isReadByRecipient: false
        ).toDictionary()

        let chatRef = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let chatDocument: DocumentSnapshot
            do {
                try chatDocument = transaction.getDocument(chatRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let chatDocData = chatDocument.data(), 
                  var chatSummary = ChatSummary(documentID: chatDocument.documentID, dictionary: chatDocData) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode chat data during transaction"])
                errorPointer?.pointee = error
                return nil
            }
            
            var currentUnread = chatSummary.unreadCounts[recipientId] ?? 0
            currentUnread += 1
            chatSummary.unreadCounts[recipientId] = currentUnread

            transaction.updateData([
                "lastMessageText": text,
                "lastMessageTimestamp": Timestamp(date: Date()),
                "lastMessageSenderId": sender.id,
                "updatedAt": Timestamp(date: Date()),
                "unreadCounts.\(recipientId)": currentUnread
            ], forDocument: chatRef)

            transaction.setData(messageData, forDocument: messageRef)
            
            return nil
        }) { (object, error) in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func sendVideoMessage(chatId: String, sender: ParticipantInfo, videoURL: String, thumbnailURL: String? = nil, recipientId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let messageData = ChatMessage(
            chatId: chatId,
            senderId: sender.id,
            senderName: sender.fullName,
            text: "🎥 Workout Video",
            timestamp: Timestamp(date: Date()),
            isReadByRecipient: false,
            videoURL: videoURL
        ).toDictionary()

        let chatRef = db.collection("chats").document(chatId)
        let messageRef = chatRef.collection("messages").document()

        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let chatDocument: DocumentSnapshot
            do {
                try chatDocument = transaction.getDocument(chatRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let chatDocData = chatDocument.data(), 
                  var chatSummary = ChatSummary(documentID: chatDocument.documentID, dictionary: chatDocData) else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode chat data during transaction"])
                errorPointer?.pointee = error
                return nil
            }
            
            var currentUnread = chatSummary.unreadCounts[recipientId] ?? 0
            currentUnread += 1
            chatSummary.unreadCounts[recipientId] = currentUnread

            transaction.updateData([
                "lastMessageText": "🎥 Workout Video",
                "lastMessageTimestamp": Timestamp(date: Date()),
                "lastMessageSenderId": sender.id,
                "updatedAt": Timestamp(date: Date()),
                "unreadCounts.\(recipientId)": currentUnread
            ], forDocument: chatRef)

            transaction.setData(messageData, forDocument: messageRef)
            
            return nil
        }) { (object, error) in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func markMessagesAsRead(chatId: String, currentUserId: String, messages: [ChatMessage], completion: @escaping (Result<Void, Error>) -> Void) {
        let chatRef = db.collection("chats").document(chatId)
        let batch = db.batch()
        
        for message in messages {
            if message.senderId != currentUserId && !message.isReadByRecipient {
                let messageDocRef = chatRef.collection("messages").document(message.id)
                batch.updateData(["isReadByRecipient": true], forDocument: messageDocRef)
            }
        }
        
        batch.updateData([
            "unreadCounts.\(currentUserId)": 0,
            "updatedAt": Timestamp(date:Date())
        ], forDocument: chatRef)

        batch.commit { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func removeChatsListener() {
        chatsListener?.remove()
        chatsListener = nil
    }

    func removeMessagesListener() {
        messagesListener?.remove()
        messagesListener = nil
    }
}