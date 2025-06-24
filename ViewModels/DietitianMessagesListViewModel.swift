import Foundation
import Combine
import FirebaseFirestore

class DietitianMessagesListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var chatService = ChatService.shared
    private var cancellables = Set<AnyCancellable>()
    private var chatsListenerRegistration: ListenerRegistration?

    init() {} // Default initializer for @StateObject

    func fetchChats(dietitianId: String) {
        isLoading = true
        self.chatsListenerRegistration = chatService.observeChats(forUserId: dietitianId) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let chats):
                self.chats = chats
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = "Error fetching dietitian chats: \(error.localizedDescription)"
                print("Error fetching dietitian chats: \(error.localizedDescription)")
            }
        }
    }
    
    func getClientParticipant(for chat: ChatSummary, dietitianId: String) -> ParticipantInfo? {
        return chat.otherParticipant(currentUserId: dietitianId)
    }

    deinit {
        chatsListenerRegistration?.remove()
    }
}
