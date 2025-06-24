import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientChatDetailView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: ClientChatDetailViewModel
    
    let chatId: String
    let dietitianName: String
    let dietitianAvatarURL: String?

    init(chatId: String, dietitianName: String, dietitianAvatarURL: String? = nil, session: SessionStore) {
        self.chatId = chatId
        self.dietitianName = dietitianName
        self.dietitianAvatarURL = dietitianAvatarURL
        self._viewModel = StateObject(wrappedValue: ClientChatDetailViewModel(chatId: chatId, sessionStore: session))
    }

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messageListView
            }
            
            messageInputView
        }
        .background(Color(hex: "0D0F14").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            print("[ClientChatDetailView] onAppear called for chatId: \(chatId)")
            viewModel.startListeningForMessages()
            Task {
                await viewModel.markChatAsReadByClient()
            }
        }
        .alert(isPresented: $viewModel.showSendError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Failed to send message."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var customHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            HStack(spacing: 12) {
                if let avatarURLString = dietitianAvatarURL, !avatarURLString.isEmpty, let url = URL(string: avatarURLString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color(hex: "AB47BC"))
                            .overlay(
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: "AB47BC"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "stethoscope")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.actualDietitianName.isEmpty ? dietitianName : viewModel.actualDietitianName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "0D0F14"))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "3C9CFF")))
            Text("Loading conversation...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "3C9CFF"))
            
            Text("Start your conversation!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Send a message to begin chatting with your dietitian.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ClientMessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.senderId == session.currentUserId
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessageId = viewModel.messages.last?.id {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }

    private var messageInputView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(spacing: 12) {
                TextField("Type a message…", text: $viewModel.newMessageText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    viewModel.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.gray.opacity(0.3)
                                        : Color(hex: "3C9CFF")
                                )
                        )
                        .scaleEffect(
                            viewModel.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? 0.9 : 1.0
                        )
                }
                .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, safeAreaBottomInset())
            .background(Color(hex: "0D0F14"))
        }
    }
}

struct ClientMessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .background(
                        backgroundGradient
                            .cornerRadius(20, corners: cornerMask)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var backgroundGradient: LinearGradient {
        if isFromCurrentUser {
            return LinearGradient(
                colors: [Color(hex: "42A5F5"), Color(hex: "1E88E5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(hex: "AB47BC"), Color(hex: "8E24AA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cornerMask: UIRectCorner {
        if isFromCurrentUser {
            return [.topLeft, .topRight, .bottomLeft]
        } else {
            return [.topLeft, .topRight, .bottomRight]
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: message.timestamp.dateValue())
    }
}

@MainActor
class ClientChatDetailViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessageText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSendError: Bool = false
    @Published var actualDietitianName: String = ""
    
    let chatId: String
    private var db = Firestore.firestore()
    private var messageListener: ListenerRegistration?
    var sessionStore: SessionStore
    private var chatDocumentRef: DocumentReference
    private var currentClientUid: String { sessionStore.currentUserId ?? "" }

    init(chatId: String, sessionStore: SessionStore) {
        self.chatId = chatId
        self.sessionStore = sessionStore
        self.chatDocumentRef = db.collection("chats").document(chatId)
        
        fetchDietitianName()
    }

    deinit {
        messageListener?.remove()
    }
    
    private func fetchDietitianName() {
        chatDocumentRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("[ClientChatDetailVM] Error fetching dietitian name: \(error.localizedDescription)")
                    self.errorMessage = "Could not load dietitian details."
                    return
                }
                if let data = snapshot?.data() {
                    if let participants = data["participantIds"] as? [String],
                       let participantNames = data["participantNames"] as? [String: String] {
                        let dietitianUID = participants.first(where: { $0 != self.currentClientUid }) ?? ""
                        self.actualDietitianName = participantNames[dietitianUID] ?? "Dietitian"
                    } else {
                        self.actualDietitianName = data["dietitianName"] as? String ?? "Dietitian"
                    }
                } else {
                    self.actualDietitianName = "Dietitian"
                }
            }
        }
    }

    func startListeningForMessages() {
        isLoading = true
        print("[ClientChatDetailVM] Starting to listen for messages in chat: \(chatId)")
        
        messageListener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Error fetching messages: \(error.localizedDescription)"
                        print("[ClientChatDetailVM] Error listening for messages: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = querySnapshot?.documents else {
                        print("[ClientChatDetailVM] No message documents found - setting empty messages array.")
                        self.messages = []
                        return
                    }

                    let newMessages = documents.compactMap { document -> ChatMessage? in
                        return ChatMessage(documentID: document.documentID, dictionary: document.data())
                    }
                    
                    print("[ClientChatDetailVM] Found \(documents.count) message documents, parsed \(newMessages.count) messages")
                    
                    if self.messages != newMessages {
                        self.messages = newMessages
                        print("[ClientChatDetailVM] Updated messages count: \(self.messages.count)")
                    }
                    
                    Task {
                        for message in self.messages where message.senderId != self.currentClientUid && !message.isReadByRecipient {
                            let messageId = message.id
                            await self.markMessageAsReadByClient(messageId: messageId)
                        }
                    }
                }
            }
    }

    func sendMessage() async {
        let trimmed = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("[ClientChatDetailVM] Cannot send empty message")
            return
        }
        
        guard let senderId = sessionStore.currentUserId,
              let senderUser = sessionStore.currentUser else {
            await MainActor.run {
                showSendError = true
                errorMessage = "User information not available to send message."
            }
            return
        }

        let senderName = senderUser.fullName

        guard let chatParticipants = await getChatParticipants(),
              chatParticipants.count == 2 else {
            await MainActor.run {
                showSendError = true
                errorMessage = "Could not determine chat participants."
            }
            return
        }
        
        let recipientId = chatParticipants.first(where: { $0 != senderId }) ?? ""
        
        let newMessageRef = db.collection("chats").document(chatId).collection("messages").document()
        let message = ChatMessage(
            id: newMessageRef.documentID,
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: trimmed,
            timestamp: Timestamp(date: Date()),
            isReadByRecipient: false,
            senderAvatarURL: senderUser.photoURL
        )
        let messageData = message.toDictionary()

        do {
            try await newMessageRef.setData(messageData)
            
            try await chatDocumentRef.updateData([
                "lastMessageText": trimmed,
                "lastMessageTimestamp": FieldValue.serverTimestamp(),
                "lastMessageSenderId": senderId,
                "unreadCounts.\(senderId)": 0,
                "unreadCounts.\(recipientId)": FieldValue.increment(Int64(1))
            ])
            
            await MainActor.run {
                self.newMessageText = ""
            }
        } catch {
            await MainActor.run {
                self.showSendError = true
                self.errorMessage = "Failed to send message: \(error.localizedDescription)"
            }
        }
    }
    
    private func getChatParticipants() async -> [String]? {
        do {
            let documentSnapshot = try await chatDocumentRef.getDocument()
            guard let data = documentSnapshot.data(),
                  let participants = data["participantIds"] as? [String] else {
                return nil
            }
            return participants
        } catch {
            print("[ClientChatDetailVM] Error fetching chat participants: \(error.localizedDescription)")
            return nil
        }
    }

    func markChatAsReadByClient() async {
        guard let clientId = sessionStore.currentUserId else { return }
        do {
            try await chatDocumentRef.updateData(["unreadCounts.\(clientId)": 0])
        } catch {
            print("[ClientChatDetailVM] Error marking chat as read by client: \(error.localizedDescription)")
        }
    }

    private func markMessageAsReadByClient(messageId: String) async {
        let messageRef = db.collection("chats").document(chatId).collection("messages").document(messageId)
        do {
            try await messageRef.updateData(["isReadByRecipient": true])
        } catch {
            print("[ClientChatDetailVM] Error marking message \(messageId) as read by client: \(error.localizedDescription)")
        }
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

private func safeAreaBottomInset() -> CGFloat {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return 0
    }
    return window.safeAreaInsets.bottom
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore(isLoggedIn: true, role: "client")
        return ClientChatDetailView(
            chatId: "preview_chat_id",
            dietitianName: "Dr. Sarah Adams",
            session: mockSession
        )
        .environmentObject(mockSession)
        .preferredColorScheme(.dark)
    }
}
#endif
