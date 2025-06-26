import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit
import AVFoundation

@MainActor
class MessagingService: ObservableObject {
    static let shared = MessagingService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - Send Messages
    
    /// Send a text message
    func sendTextMessage(to recipientId: String, text: String, senderName: String, senderAvatarUrl: String?) async throws {
        guard let currentUserId = getCurrentUserId() else {
            throw MessagingError.notAuthenticated
        }
        
        let message = Message(
            senderId: currentUserId,
            recipientId: recipientId,
            type: .text,
            text: text,
            senderName: senderName,
            senderAvatarUrl: senderAvatarUrl
        )
        
        try await saveMessage(message)
    }
    
    /// Send a photo message
    func sendPhotoMessage(to recipientId: String, image: UIImage, senderName: String, senderAvatarUrl: String?) async throws {
        print("[MessagingService] Starting to send photo message")
        guard let currentUserId = getCurrentUserId() else {
            print("[MessagingService] No current user ID found")
            throw MessagingError.notAuthenticated
        }
        
        print("[MessagingService] Current user ID: \(currentUserId), recipient: \(recipientId)")
        
        // Upload image to Storage
        print("[MessagingService] Starting image upload...")
        let imageUrl = try await uploadImage(image, path: "messages/photos/\(UUID().uuidString).jpg")
        print("[MessagingService] Image uploaded successfully to: \(imageUrl)")
        
        let message = Message(
            senderId: currentUserId,
            recipientId: recipientId,
            type: .photo,
            contentUrl: imageUrl,
            senderName: senderName,
            senderAvatarUrl: senderAvatarUrl
        )
        
        print("[MessagingService] Saving message to Firestore...")
        try await saveMessage(message)
        print("[MessagingService] Photo message sent successfully!")
    }
    
    /// Send a video message
    func sendVideoMessage(to recipientId: String, videoUrl: URL, senderName: String, senderAvatarUrl: String?) async throws {
        guard let currentUserId = getCurrentUserId() else {
            throw MessagingError.notAuthenticated
        }
        
        // Upload video to Storage
        let uploadedVideoUrl = try await uploadVideo(from: videoUrl, path: "messages/videos/\(UUID().uuidString).mp4")
        
        let message = Message(
            senderId: currentUserId,
            recipientId: recipientId,
            type: .video,
            contentUrl: uploadedVideoUrl,
            senderName: senderName,
            senderAvatarUrl: senderAvatarUrl
        )
        
        try await saveMessage(message)
    }
    
    /// Send a snap (disappearing photo)
    func sendSnapMessage(to recipientId: String, image: UIImage, senderName: String, senderAvatarUrl: String?) async throws {
        guard let currentUserId = getCurrentUserId() else {
            throw MessagingError.notAuthenticated
        }
        
        // Upload image to Storage
        let imageUrl = try await uploadImage(image, path: "messages/snaps/\(UUID().uuidString).jpg")
        
        let message = Message(
            senderId: currentUserId,
            recipientId: recipientId,
            type: .snap,
            contentUrl: imageUrl,
            isConsumed: false,
            senderName: senderName,
            senderAvatarUrl: senderAvatarUrl
        )
        
        try await saveMessage(message)
    }
    
    // MARK: - Message Management
    
    private func saveMessage(_ message: Message) async throws {
        print("[MessagingService] Saving message with ID: \(message.id)")
        let messageRef = db.collection("messages").document(message.id)
        
        do {
            let messageData = message.toDictionary()
            print("[MessagingService] Message data: \(messageData)")
            try await messageRef.setData(messageData)
            print("[MessagingService] Message saved successfully to Firestore")
        } catch {
            print("[MessagingService] Failed to save message: \(error)")
            throw error
        }
    }
    
    /// Get messages between current user and another user
    func getMessages(with userId: String) -> AsyncThrowingStream<[Message], Error> {
        guard let currentUserId = getCurrentUserId() else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: MessagingError.notAuthenticated)
            }
        }
        
        return AsyncThrowingStream { continuation in
            let query = db.collection("messages")
                .whereField("senderId", in: [currentUserId, userId])
                .whereField("recipientId", in: [currentUserId, userId])
                .order(by: "timestamp", descending: false)
            
            let listener = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    continuation.yield([])
                    return
                }
                
                let messages = documents.compactMap { doc in
                    Message(documentId: doc.documentID, data: doc.data())
                }.filter { message in
                    // Filter messages between these two users only
                    return (message.senderId == currentUserId && message.recipientId == userId) ||
                           (message.senderId == userId && message.recipientId == currentUserId)
                }
                
                continuation.yield(messages)
            }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    /// Get conversation previews for current user
    func getConversationPreviews() -> AsyncThrowingStream<[ConversationPreview], Error> {
        guard let currentUserId = getCurrentUserId() else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: MessagingError.notAuthenticated)
            }
        }
        
        return AsyncThrowingStream { continuation in
            // Get all messages where current user is sender or recipient
            let query = db.collection("messages")
                .whereField("senderId", isEqualTo: currentUserId)
                .order(by: "timestamp", descending: true)
            
            let query2 = db.collection("messages")
                .whereField("recipientId", isEqualTo: currentUserId)
                .order(by: "timestamp", descending: true)
            
            var allMessages: [Message] = []
            var listenersCount = 0
            let totalListeners = 2
            
            let processMessages = {
                // Group messages by conversation partner
                var conversationsDict: [String: [Message]] = [:]
                
                for message in allMessages {
                    let otherUserId = message.senderId == currentUserId ? message.recipientId : message.senderId
                    if conversationsDict[otherUserId] == nil {
                        conversationsDict[otherUserId] = []
                    }
                    conversationsDict[otherUserId]?.append(message)
                }
                
                // Create conversation previews
                var previews: [ConversationPreview] = []
                
                for (otherUserId, messages) in conversationsDict {
                    let sortedMessages = messages.sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
                    let lastMessage = sortedMessages.first
                    
                    // Count unread messages (messages sent by other user that haven't been consumed if snaps)
                    let unreadCount = messages.filter { message in
                        message.senderId == otherUserId && 
                        (message.type != .snap || !(message.isConsumed ?? false))
                    }.count
                    
                    // Get other user's name from the last message
                    let otherUserName = lastMessage?.senderId == otherUserId ? 
                        (lastMessage?.senderName ?? "User") : "User"
                    let otherUserAvatarUrl = lastMessage?.senderId == otherUserId ? 
                        lastMessage?.senderAvatarUrl : nil
                    
                    let preview = ConversationPreview(
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserAvatarUrl: otherUserAvatarUrl,
                        lastMessage: lastMessage,
                        unreadCount: unreadCount
                    )
                    previews.append(preview)
                }
                
                // Sort by last message timestamp
                let sortedPreviews = previews.sorted { preview1, preview2 in
                    guard let time1 = preview1.lastMessage?.timestamp.dateValue(),
                          let time2 = preview2.lastMessage?.timestamp.dateValue() else {
                        return false
                    }
                    return time1 > time2
                }
                
                continuation.yield(sortedPreviews)
            }
            
            let listener1 = query.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                let messages = snapshot?.documents.compactMap { doc in
                    Message(documentId: doc.documentID, data: doc.data())
                } ?? []
                
                allMessages.removeAll { $0.senderId == currentUserId }
                allMessages.append(contentsOf: messages)
                
                listenersCount += 1
                if listenersCount >= totalListeners {
                    processMessages()
                }
            }
            
            let listener2 = query2.addSnapshotListener { snapshot, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                }
                
                let messages = snapshot?.documents.compactMap { doc in
                    Message(documentId: doc.documentID, data: doc.data())
                } ?? []
                
                allMessages.removeAll { $0.recipientId == currentUserId }
                allMessages.append(contentsOf: messages)
                
                listenersCount += 1
                if listenersCount >= totalListeners {
                    processMessages()
                }
            }
            
            continuation.onTermination = { _ in
                listener1.remove()
                listener2.remove()
            }
        }
    }
    
    /// Mark a snap as consumed
    func markSnapAsConsumed(_ message: Message) async throws {
        guard message.type == .snap else {
            throw MessagingError.invalidOperation("Message is not a snap")
        }
        
        let messageRef = db.collection("messages").document(message.id)
        try await messageRef.updateData(["isConsumed": true])
        
        // Optionally delete the image from Storage to save space
        if let contentUrl = message.contentUrl {
            try? await deleteFromStorage(url: contentUrl)
        }
    }
    
    // MARK: - User Validation
    
    /// Check if current user can message the specified user (based on dietitian-client relationship)
    func canMessageUser(_ userId: String) async -> Bool {
        guard let currentUserId = getCurrentUserId() else { return false }
        
        do {
            // Get current user's role
            let currentUserDoc = try await db.collection("users").document(currentUserId).getDocument()
            guard let currentUserData = currentUserDoc.data(),
                  let currentUserRole = currentUserData["role"] as? String else {
                return false
            }
            
            // Get target user's role
            let targetUserDoc = try await db.collection("users").document(userId).getDocument()
            guard let targetUserData = targetUserDoc.data(),
                  let targetUserRole = targetUserData["role"] as? String else {
                return false
            }
            
            // Check valid relationships
            if currentUserRole == "client" && targetUserRole == "dietitian" {
                // Check if client is assigned to this dietitian
                if let assignedDietitianId = currentUserData["assignedDietitianId"] as? String {
                    return assignedDietitianId == userId
                }
                
                // Or check if client is in dietitian's clients list
                let clientDoc = try await db.collection("dietitians").document(userId)
                    .collection("clients").document(currentUserId).getDocument()
                return clientDoc.exists
            }
            
            if currentUserRole == "dietitian" && targetUserRole == "client" {
                // Check if client is in dietitian's clients list
                let clientDoc = try await db.collection("dietitians").document(currentUserId)
                    .collection("clients").document(userId).getDocument()
                return clientDoc.exists
            }
            
            return false
        } catch {
            print("Error checking user messaging permissions: \(error)")
            return false
        }
    }
    
    /// Get the assigned dietitian for a client
    func getAssignedDietitian(for clientId: String) async throws -> (id: String, name: String, avatarUrl: String?)? {
        let userDoc = try await db.collection("users").document(clientId).getDocument()
        guard let userData = userDoc.data() else { return nil }
        
        var dietitianId: String?
        
        // Check various ways a client might be connected to a dietitian
        if let assignedId = userData["assignedDietitianId"] as? String, !assignedId.isEmpty {
            dietitianId = assignedId
        } else if let expertId = userData["expertId"] as? String, !expertId.isEmpty {
            dietitianId = expertId
        } else {
            // Check if client exists in any dietitian's clients collection
            let dietitiansSnapshot = try await db.collection("dietitians").getDocuments()
            for dietitianDoc in dietitiansSnapshot.documents {
                let clientDoc = try await dietitianDoc.reference.collection("clients").document(clientId).getDocument()
                if clientDoc.exists {
                    dietitianId = dietitianDoc.documentID
                    break
                }
            }
        }
        
        guard let finalDietitianId = dietitianId else { return nil }
        
        // Get dietitian details
        let dietitianDoc = try await db.collection("users").document(finalDietitianId).getDocument()
        guard let dietitianData = dietitianDoc.data() else { return nil }
        
        let name = dietitianData["fullName"] as? String ?? "Dietitian"
        let avatarUrl = dietitianData["photoURL"] as? String
        
        return (id: finalDietitianId, name: name, avatarUrl: avatarUrl)
    }
    
    // MARK: - Storage Operations
    
    private func uploadImage(_ image: UIImage, path: String) async throws -> String {
        print("[MessagingService] Converting image to JPEG data...")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("[MessagingService] Failed to convert image to JPEG data")
            throw MessagingError.invalidData("Could not convert image to data")
        }
        
        print("[MessagingService] Image data size: \(imageData.count) bytes")
        print("[MessagingService] Uploading to path: \(path)")
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            print("[MessagingService] Starting Firebase Storage upload...")
            _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            print("[MessagingService] Upload completed, getting download URL...")
            
            let downloadURL = try await storageRef.downloadURL()
            print("[MessagingService] Download URL obtained: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            print("[MessagingService] Upload failed with error: \(error)")
            throw MessagingError.uploadFailed(error.localizedDescription)
        }
    }
    
    private func uploadVideo(from localUrl: URL, path: String) async throws -> String {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        
        _ = try await storageRef.putFileAsync(from: localUrl, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    private func deleteFromStorage(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
}

// MARK: - Custom Errors

enum MessagingError: LocalizedError {
    case notAuthenticated
    case invalidData(String)
    case invalidOperation(String)
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .invalidOperation(let message):
            return "Invalid operation: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}