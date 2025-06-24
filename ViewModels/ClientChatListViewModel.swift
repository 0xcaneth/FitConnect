import Foundation
import Combine
import FirebaseFirestore

class ClientChatListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var chatService = ChatService.shared
    private var cancellables = Set<AnyCancellable>()
    private var chatsListenerRegistration: ListenerRegistration?

    func fetchChats(clientId: String) {
        isLoading = true
        self.chatsListenerRegistration = chatService.observeChats(forUserId: clientId) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let chats):
                self.chats = chats
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = "Error fetching chats: \(error.localizedDescription)"
                print("Error fetching chats: \(error.localizedDescription)")
            }
        }
    }
    
    func getDietitianParticipant(for chat: ChatSummary, clientId: String) -> ParticipantInfo? {
        return chat.otherParticipant(currentUserId: clientId)
    }

    deinit {
        chatsListenerRegistration?.remove()
    }
}