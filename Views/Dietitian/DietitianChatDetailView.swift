import SwiftUI
import Combine
import FirebaseFirestore // For Timestamp, if needed directly
import FitConnect

// --- START OF EMBEDDED VIEWMODEL ---
// import Foundation // Already imported via SwiftUI usually or not strictly needed for this model's content
// import Combine // Already imported via SwiftUI
// import FirebaseFirestore // Already imported above

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
        // Graceful fallback: If we can't find the client, set a dummy participant and an error message instead of crashing.
        if let client = chat.otherParticipant(currentUserId: currentDietitianId) {
            self.clientParticipant = client
            fetchMessages()
        } else {
            self.clientParticipant = ParticipantInfo(id: "unknown", fullName: "Unknown Client")
            self.errorMessage = "Client participant not found in this chat."
            // Do not call fetchMessages (since data is invalid)
            return
        }
    }

    func fetchMessages() {
        messagesListenerRegistration = chatService.observeMessages(chatId: currentChat.id) { [weak self] result in
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
              !currentChat.id.isEmpty else { return }
        let chatId = currentChat.id

        chatService.sendMessage(chatId: chatId, sender: dietitianParticipant, text: text, recipientId: clientParticipant.id) { [weak self] result in
            if case .failure(let error) = result {
                self?.errorMessage = "Error sending message: \(error.localizedDescription)"
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }
    
    private func markMessagesAsReadForDietitian(messages: [ChatMessage]) {
        let chatId = currentChat.id
        guard !chatId.isEmpty else { return }
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
// --- END OF EMBEDDED VIEWMODEL ---

@available(iOS 16.0, *)
struct DietitianChatDetailView: View {
    @StateObject var viewModel: DietitianChatDetailViewModel // Passed in
    @EnvironmentObject var session: SessionStore // To get current dietitian ParticipantInfo
    @Environment(\.dismiss) var dismiss

    @State private var newMessageText: String = ""

    // Client's name for the navigation title
    private var clientName: String {
        viewModel.clientParticipant.fullName
    }

    var body: some View {
        VStack {
            // Header (Optional: You might prefer a NavigationBar title)
            // Text("Chat with \(clientName)")
            //     .font(.headline)
            //     .padding(.top)
            
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack(spacing: 8) { // Added spacing
                        ForEach(viewModel.messages) { message in
                            VStack {
                                HStack {
                                    if message.senderId == session.currentUserId {
                                        Spacer()
                                    }
                                    Text(message.text)
                                        .padding()
                                        .background(message.senderId == session.currentUserId ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    if message.senderId != session.currentUserId {
                                        Spacer()
                                    }
                                }
                                Text(message.senderName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .id(message.id)
                            .padding(.horizontal) // Padding for bubbles
                        }
                    }
                    .padding(.vertical) // Padding for the content of ScrollView
                }
                .onAppear {
                    if let lastMessage = viewModel.messages.last {
                        scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }

            // Message Input Area
            HStack {
                TextField("Message \(clientName)...", text: $newMessageText, axis: .vertical)
                    .textFieldStyle(.plain) // Using plain style
                    .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(18)
                    .lineLimit(1...5)


                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat with \(clientName)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        guard let dietitianId = session.currentUserId,
              let dietitianFullName = session.currentUser?.fullName else {
            viewModel.errorMessage = "Dietitian details not found."
            return
        }
        
        let dietitianParticipant = ParticipantInfo(id: dietitianId, fullName: dietitianFullName, photoURL: session.currentUser?.photoURL)
        
        viewModel.sendMessage(text: newMessageText, dietitianParticipant: dietitianParticipant)
        newMessageText = "" // Clear input field
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sessionStore = SessionStore() // Mock or use your preview SessionStore
        sessionStore.currentUserId = "dietitianPreviewId"
        sessionStore.currentUser = FitConnectUser(id: "dietitianPreviewId", email: "dietitian@example.com", fullName: "Dr. Preview", role: "dietitian")

        let mockClient = ParticipantInfo(id: "clientPreviewId", fullName: "Client Preview User", photoURL: nil)
        let mockDietitian = ParticipantInfo(id: "dietitianPreviewId", fullName: "Dr. Preview", photoURL: nil)

        let mockChatSummary = ChatSummary(
            chatId: ChatHelpers.generateChatId(userId1: mockClient.id, userId2: mockDietitian.id),
            client: mockClient,
            dietitian: mockDietitian
        )
        // mockChatSummary.participantDetails = [mockClient.id: mockClient, mockDietitian.id: mockDietitian]
        // mockChatSummary.participantIds = [mockClient.id, mockDietitian.id].sorted()
        
        let previewViewModel = DietitianChatDetailViewModel(chat: mockChatSummary, currentDietitianId: "dietitianPreviewId")
        
        // Add some mock messages to the ViewModel for preview
        previewViewModel.messages = [
            ChatMessage(id: "msg1", chatId: mockChatSummary.id, senderId: "clientPreviewId", senderName: "Client Preview User", text: "Hello Dr. Preview!", timestamp: Timestamp(date: Date(timeIntervalSinceNow: -120)), isReadByRecipient: true),
            ChatMessage(id: "msg2", chatId: mockChatSummary.id, senderId: "dietitianPreviewId", senderName: "Dr. Preview", text: "Hello Client! How can I help you today?", timestamp: Timestamp(date: Date(timeIntervalSinceNow: -60))),
            ChatMessage(id: "msg3", chatId: mockChatSummary.id, senderId: "clientPreviewId", senderName: "Client Preview User", text: "I have a question about my meal plan.", timestamp: Timestamp(date: Date()))
        ]

        return NavigationView { // Wrap in NavigationView for previewing navigation title
            DietitianChatDetailView(viewModel: previewViewModel)
                .environmentObject(sessionStore)
        }
    }
}
#endif
