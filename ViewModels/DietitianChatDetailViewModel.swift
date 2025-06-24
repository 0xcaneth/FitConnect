import Foundation
import Combine
import FirebaseFirestore

class DietitianChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var errorMessage: String?
    @Published var currentChat: ChatSummary

    private let chatService = ChatService.shared
    private var messagesListenerRegistration: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    let currentDietitianId: String
    let clientParticipant: ParticipantInfo
    
    init(chat: ChatSummary, currentDietitianId: String) {
        self.currentChat = chat
        self.currentDietitianId = currentDietitianId
        guard let client = chat.otherParticipant(currentUserId: currentDietitianId) else {
            fatalError("Client participant not found in chat for DietitianChatDetailViewModel")
        }
        self.clientParticipant = client
        fetchMessages()
    }

    func fetchMessages() {
        messagesListenerRegistration = chatService.observeMessages(chatId: currentChat.id!) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let fetchedMessages):
                self.messages = fetchedMessages
                self.markMessagesAsReadForDietitian(messages: fetchedMessages)
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = "Error fetching messages: \(error.localizedDescription)"
                print("Error fetching messages: \(error.localizedDescription)")
            }
        }
    }

    func sendMessage(text: String, dietitianParticipant: ParticipantInfo) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let chatId = currentChat.id else { return }

        chatService.sendMessage(chatId: chatId, sender: dietitianParticipant, text: text, recipientId: clientParticipant.id) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = "Error sending message: \(error.localizedDescription)"
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func markMessagesAsReadForDietitian(messages: [ChatMessage]) {
        guard let chatId = currentChat.id else { return }
        // Mark messages sent by client as read by this dietitian
        let unreadMessagesFromClient = messages.filter { $0.senderId == clientParticipant.id && !$0.isReadByRecipient }
        if !unreadMessagesFromClient.isEmpty {
            chatService.markMessagesAsRead(chatId: chatId, currentUserId: currentDietitianId, messages: unreadMessagesFromClient) { result in
                if case .failure(let error) = result {
                    print("Failed to mark messages as read for dietitian: \(error.localizedDescription)")
                }
            }
        }
    }
    
    deinit {
        messagesListenerRegistration?.remove()
    }
}
