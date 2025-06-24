import Foundation
import Combine
import FirebaseFirestore

@MainActor
class DietitianChatListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private var chatService = ChatService.shared
    private var chatsListenerRegistration: ListenerRegistration?
    
    func startListening(forUserId userId: String) {
        guard !userId.isEmpty else {
            errorMessage = "User ID is required"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        chatsListenerRegistration = chatService.observeChats(forUserId: userId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let chats):
                    self.chats = chats
                    self.errorMessage = nil
                    self.showError = false
                case .failure(let error):
                    self.errorMessage = "Error loading chats: \(error.localizedDescription)"
                    self.showError = true
                    print("[DietitianChatListVM] Error: \(error)")
                }
            }
        }
    }
    
    func otherParticipant(for chat: ChatSummary, currentUserId: String) -> ParticipantInfo? {
        return chat.otherParticipant(currentUserId: currentUserId)
    }
    
    func unreadCount(for chat: ChatSummary, currentUserId: String) -> Int {
        return chat.unreadCounts[currentUserId] ?? 0
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    deinit {
        chatsListenerRegistration?.remove()
    }
}