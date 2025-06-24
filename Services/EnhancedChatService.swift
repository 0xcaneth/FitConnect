import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine
import Network
import AVFoundation

@MainActor
class EnhancedChatService: ObservableObject {
    static let shared = EnhancedChatService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    // Published properties for real-time updates
    @Published var chats: [ChatSummary] = []
    @Published var messages: [ChatMessage] = []
    @Published var typingUsers: [TypingIndicator] = []
    @Published var isConnected = true
    @Published var failedMessages: [ChatMessage] = []
    
    // Private properties
    private var listeners: [String: ListenerRegistration] = [:]
    private var retryTimers: [String: Timer] = [:]
    private var lastTypingUpdate: Date = Date()
    
    private init() {
        setupFirestorePersistence()
        setupNetworkMonitoring()
    }
    
    deinit {
        Task { @MainActor in
            await self.cleanupAsync()
        }
    }
    
    private func cleanupAsync() async {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        retryTimers.values.forEach { $0.invalidate() }
        retryTimers.removeAll()
        networkMonitor.cancel()
    }
    
    // MARK: - Setup
    
    private func setupFirestorePersistence() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        db.settings = settings
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                if path.status == .satisfied {
                    self?.retryFailedMessages()
                }
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // MARK: - Chat Management
    
    func startListeningToChats(userId: String) {
        let listener = db.collection("chats")
            .whereField("participantIds", arrayContains: userId)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to chats: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.chats = documents.compactMap { doc in
                    ChatSummary(documentID: doc.documentID, dictionary: doc.data())
                }
            }
        
        listeners["chats_\(userId)"] = listener
    }
    
    func startListeningToMessages(chatId: String) {
        let listener = db.collection("chats")
            .document(chatId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { doc in
                    ChatMessage(documentID: doc.documentID, dictionary: doc.data())
                }
            }
        
        listeners["messages_\(chatId)"] = listener
        
        // Also start listening to typing indicators
        startListeningToTypingIndicators(chatId: chatId)
    }
    
    // MARK: - Typing Indicators
    
    private func startListeningToTypingIndicators(chatId: String) {
        let listener = db.collection("chats")
            .document(chatId)
            .collection("typingIndicators")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to typing indicators: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let indicators = documents.compactMap { doc in
                    TypingIndicator(dictionary: doc.data())
                }.filter { $0.isActive }
                
                self.typingUsers = indicators
            }
        
        listeners["typing_\(chatId)"] = listener
    }
    
    func updateTypingIndicator(chatId: String, userId: String, userName: String, isTyping: Bool) {
        // Throttle typing updates to avoid too many writes
        let now = Date()
        guard now.timeIntervalSince(lastTypingUpdate) > 1.0 else { return }
        lastTypingUpdate = now
        
        let typingRef = db.collection("chats")
            .document(chatId)
            .collection("typingIndicators")
            .document(userId)
        
        if isTyping {
            let indicator = TypingIndicator(userId: userId, userName: userName)
            typingRef.setData(indicator.toDictionary())
        } else {
            typingRef.delete()
        }
    }
    
    // MARK: - Message Sending
    
    func sendTextMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        text: String,
        recipientId: String
    ) async throws {
        let message = ChatMessage(
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Timestamp(date: Date()),
            messageSendStatus: .sending
        )
        
        try await sendMessage(message, recipientId: recipientId)
    }
    
    func sendImageMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        imageData: Data,
        text: String = "",
        recipientId: String
    ) async throws {
        // Upload image first
        let imageURL = try await uploadImage(chatId: chatId, imageData: imageData)
        
        let message = ChatMessage(
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Timestamp(date: Date()),
            imageURL: imageURL,
            messageSendStatus: .sending
        )
        
        try await sendMessage(message, recipientId: recipientId)
    }
    
    func sendVideoMessage(
        chatId: String,
        senderId: String,
        senderName: String,
        videoURL: URL,
        text: String = "",
        recipientId: String
    ) async throws {
        // Upload video first
        let uploadedVideoURL = try await uploadVideo(chatId: chatId, videoURL: videoURL)
        
        let message = ChatMessage(
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: Timestamp(date: Date()),
            videoURL: uploadedVideoURL,
            messageSendStatus: .sending
        )
        
        try await sendMessage(message, recipientId: recipientId)
    }
    
    private func sendMessage(_ message: ChatMessage, recipientId: String) async throws {
        let chatRef = db.collection("chats").document(message.chatId)
        let messageRef = chatRef.collection("messages").document()
        
        // Update message status
        var updatedMessage = message
        updatedMessage.id = messageRef.documentID
        updatedMessage.messageSendStatus = .sent
        
        try await db.runTransaction { transaction, errorPointer in
            do {
                // Get current chat data
                let chatDoc = try transaction.getDocument(chatRef)
                guard var chatData = chatDoc.data(),
                      var chat = ChatSummary(documentID: chatDoc.documentID, dictionary: chatData) else {
                    let error = NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read chat data"])
                    errorPointer?.pointee = error
                    return nil
                }
                
                // Update unread count
                chat.unreadCounts[recipientId] = (chat.unreadCounts[recipientId] ?? 0) + 1
                chat.lastMessageText = message.displayText
                chat.lastMessageTimestamp = message.timestamp
                chat.lastMessageSenderId = message.senderId
                chat.updatedAt = Timestamp(date: Date())
                
                // Write message and update chat
                transaction.setData(updatedMessage.toDictionary(), forDocument: messageRef)
                transaction.updateData(chat.toDictionary(), forDocument: chatRef)
                
                return nil
            } catch {
                let nsError = error as NSError
                errorPointer?.pointee = nsError
                return nil
            }
        }
    }
    
    // MARK: - File Upload
    
    private func uploadImage(chatId: String, imageData: Data) async throws -> String {
        let imageId = UUID().uuidString
        let imagePath = "chat_attachments/\(chatId)/images/\(imageId).jpg"
        let imageRef = storage.reference().child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    private func uploadVideo(chatId: String, videoURL: URL) async throws -> String {
        let videoId = UUID().uuidString
        let videoPath = "chat_attachments/\(chatId)/videos/\(videoId).mp4"
        let videoRef = storage.reference().child(videoPath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        _ = try await videoRef.putFileAsync(from: videoURL, metadata: metadata)
        let downloadURL = try await videoRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    // MARK: - Read Receipts
    
    func markMessagesAsRead(chatId: String, userId: String) async throws {
        let unreadMessages = messages.filter { 
            $0.senderId != userId && !$0.isReadByRecipient 
        }
        
        guard !unreadMessages.isEmpty else { return }
        
        let batch = db.batch()
        
        // Mark messages as read
        for message in unreadMessages {
            let messageRef = db.collection("chats")
                .document(chatId)
                .collection("messages")
                .document(message.id)
            batch.updateData(["isReadByRecipient": true], forDocument: messageRef)
        }
        
        // Reset unread count
        let chatRef = db.collection("chats").document(chatId)
        batch.updateData([
            "unreadCounts.\(userId)": 0,
            "updatedAt": Timestamp(date: Date())
        ], forDocument: chatRef)
        
        try await batch.commit()
    }
    
    // MARK: - Offline Support & Retry
    
    private func retryFailedMessages() {
        Task {
            for message in failedMessages {
                do {
                    // Determine recipient ID (this would need to be stored or derived)
                    let chat = chats.first { $0.id == message.chatId }
                    let recipientId = chat?.participantIds.first { $0 != message.senderId } ?? ""
                    
                    try await sendMessage(message, recipientId: recipientId)
                    
                    // Remove from failed messages
                    if let index = failedMessages.firstIndex(where: { $0.id == message.id }) {
                        failedMessages.remove(at: index)
                    }
                } catch {
                    print("Retry failed for message: \(error)")
                }
            }
        }
    }
    
    func retryMessage(_ message: ChatMessage) {
        Task {
            do {
                let chat = chats.first { $0.id == message.chatId }
                let recipientId = chat?.participantIds.first { $0 != message.senderId } ?? ""
                
                try await sendMessage(message, recipientId: recipientId)
                
                if let index = failedMessages.firstIndex(where: { $0.id == message.id }) {
                    failedMessages.remove(at: index)
                }
            } catch {
                print("Manual retry failed: \(error)")
            }
        }
    }
    
    // MARK: - Cleanup
    
    func stopListening(to key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
    
    func cleanup() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
        retryTimers.values.forEach { $0.invalidate() }
        retryTimers.removeAll()
        networkMonitor.cancel()
    }
}
