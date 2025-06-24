import Foundation
import Combine
import FirebaseFirestore

class ClientChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var currentChat: ChatSummary
    
    private let chatService = ChatService.shared
    private var messagesListenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    let currentClientId: String
    let dietitianParticipant: ParticipantInfo

    init(chat: ChatSummary, currentClientId: String) {
        self.currentChat = chat
        self.currentClientId = currentClientId
        guard let dietitian = chat.otherParticipant(currentUserId: currentClientId) else {
            // This should ideally not happen if chat is valid
            fatalError("Dietitian participant not found in chat for ClientChatDetailViewModel")
        }
        self.dietitianParticipant = dietitian
        fetchMessages()
    }

    func fetchMessages() {
        messagesListenerRegistration = chatService.observeMessages(chatId: currentChat.id!) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fetchedMessages):
                self.messages = fetchedMessages
                self.markMessagesAsReadForClient(messages: fetchedMessages)
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = "Error fetching messages: \(error.localizedDescription)"
                 print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }

    func sendMessage(text: String, clientParticipant: ParticipantInfo) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let chatId = currentChat.id else { return }

        chatService.sendMessage(chatId: chatId, sender: clientParticipant, text: text, recipientId: dietitianParticipant.id) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = "Error sending message: \(error.localizedDescription)"
                 print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func markMessagesAsReadForClient(messages: [ChatMessage]) {
        guard let chatId = currentChat.id else { return }
        // Mark messages sent by dietitian as read by this client
        let unreadMessagesFromDietitian = messages.filter { $0.senderId == dietitianParticipant.id && !$0.isReadByRecipient }
        if !unreadMessagesFromDietitian.isEmpty {
            chatService.markMessagesAsRead(chatId: chatId, currentUserId: currentClientId, messages: unreadMessagesFromDietitian) { result in
                if case .failure(let error) = result {
                    print("Failed to mark messages as read for client: \(error.localizedDescription)")
                }
            }
        }
    }

    deinit {
        messagesListenerRegistration?.remove()
    }
}