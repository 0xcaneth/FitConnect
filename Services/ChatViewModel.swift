import Foundation
import FirebaseFirestore
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private var listener: ListenerRegistration?
    private var chatId: String = ""
    
    let clientId: String
    let dietitianId: String
    let currentUserId: String
    
    init(clientId: String, dietitianId: String, currentUserId: String) {
        self.clientId = clientId
        self.dietitianId = dietitianId
        self.currentUserId = currentUserId
        
        setupChat()
    }
    
    private func setupChat() {
        isLoading = true
        
        ChatService.shared.getOrCreateChatDocument(
            clientId: clientId,
            dietitianId: dietitianId
        ) { [weak self] chatId in
            guard let self = self else { return }
            
            self.chatId = chatId
            self.isLoading = false
            
            // Start listening for messages
            self.listener = ChatService.shared.listenForMessages(chatId: chatId) { messages in
                DispatchQueue.main.async {
                    self.messages = messages
                }
            }
        }
    }
    
    func sendMessage(text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        guard !trimmedText.isEmpty, !chatId.isEmpty else { return }
        
        ChatService.shared.sendMessage(
            chatId: chatId,
            senderId: currentUserId,
            text: trimmedText,
            clientId: clientId,
            dietitianId: dietitianId
        ) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
    }
    
    func detachListener() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        detachListener()
    }
}
