import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct ClientChatListView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ClientChatListViewModel()
    @State private var selectedChat: ChatSummary?
    @State private var showChatDetail = false
    @State private var showNewChatSheet = false
    
    let chat: ChatSummary?
    
    init(chat: ChatSummary? = nil) {
        self.chat = chat
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.chats.isEmpty {
                    emptyStateView
                } else {
                    chatListView
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FitConnectColors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewChatSheet = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(FitConnectColors.accentCyan)
                    }
                }
            }
            .onAppear {
                print("[ClientChatListView] onAppear called")
                viewModel.setup(session: session)
                if let existingChat = chat {
                    selectedChat = existingChat
                    showChatDetail = true
                }
            }
            .sheet(isPresented: $showChatDetail) {
                if let selectedChat = selectedChat, let currentUserId = session.currentUserId {
                    let dietitian = selectedChat.otherParticipant(currentUserId: currentUserId)
                    let dietitianName = dietitian?.fullName ?? "Dietitian"
                    let dietitianAvatarURL = dietitian?.photoURL

                    NavigationStack {
                        ClientChatDetailView(
                            chatId: selectedChat.id,
                            dietitianName: dietitianName,
                            dietitianAvatarURL: dietitianAvatarURL,
                            session: session
                        )
                    }
                }
            }
            .sheet(isPresented: $showNewChatSheet) {
                NewChatSelectionView { selectedDietitian in
                    viewModel.createNewChat(with: selectedDietitian, session: session) { result in
                        switch result {
                        case .success(let newChat):
                            selectedChat = newChat
                            showChatDetail = true
                            showNewChatSheet = false
                        case .failure(let error):
                            print("Error creating chat: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
            Text("Loading conversations...")
                .font(.system(size: 16))
                .foregroundColor(FitConnectColors.textSecondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No conversations yet")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Start chatting with your dietitian")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Button("Find Dietitian") {
                showNewChatSheet = true
            }
            .padding()
            .background(FitConnectColors.accentCyan)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var chatListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chatItem in
                    let dietitian = chatItem.otherParticipant(currentUserId: session.currentUserId ?? "")
                    let dietitianName = dietitian?.fullName ?? "Dietitian"
                    let dietitianAvatarURL = dietitian?.photoURL

                    ChatRowView(
                        chat: chatItem,
                        otherUserName: dietitianName,
                        otherUserAvatarURL: dietitianAvatarURL,
                        unreadCount: chatItem.unreadCounts[session.currentUserId ?? ""] ?? 0
                    )
                    .onTapGesture {
                        selectedChat = chatItem
                        showChatDetail = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

@MainActor
class ClientChatListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    @Published var isLoading = false
    
    private var chatListener: ListenerRegistration?
    private var session: SessionStore?
    
    func setup(session: SessionStore) {
        print("[ClientChatListVM] Setup called with session")
        self.session = session
        startListeningForChats()
    }
    
    func startListeningForChats() {
        guard let currentUserId = session?.currentUserId else { 
            print("[ClientChatListVM] No currentUserId, cannot start listening")
            return 
        }
        
        print("[ClientChatListVM] Starting to listen for chats for user: \(currentUserId)")
        isLoading = true
        
        chatListener = ChatService.shared.observeChats(forUserId: currentUserId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let fetchedChats):
                    self.chats = fetchedChats
                    print("[ClientChatListVM] Successfully loaded \(self.chats.count) chats")
                case .failure(let error):
                    print("[ClientChatListVM] Error listening for chats: \(error)")
                    self.chats = []
                }
            }
        }
    }
    
    func createNewChat(with dietitian: ParticipantInfo, session: SessionStore, completion: @escaping (Result<ChatSummary, Error>) -> Void) {
        guard let currentUserId = session.currentUserId,
              let currentUser = session.currentUser else {
            completion(.failure(NSError(domain: "ClientError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            return
        }
        
        let clientParticipant = ParticipantInfo(
            id: currentUserId,
            fullName: currentUser.fullName,
            photoURL: currentUser.photoURL
        )
        
        ChatService.shared.getOrCreateChat(client: clientParticipant, dietitian: dietitian, completion: completion)
    }
    
    deinit {
        chatListener?.remove()
    }
}

struct ChatRowView: View {
    let chat: ChatSummary
    let otherUserName: String
    let otherUserAvatarURL: String?
    let unreadCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: otherUserAvatarURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(FitConnectColors.accentPurple)
                    .overlay(
                        Image(systemName: "stethoscope")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUserName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(chat.lastMessageText ?? "No messages yet") 
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let timestamp = chat.lastMessageTimestamp {
                    Text(relativeTimeString(from: timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FitConnectColors.fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [FitConnectColors.accentCyan.opacity(0.5), FitConnectColors.accentPurple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func relativeTimeString(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E"
        } else {
            formatter.dateFormat = "M/d"
        }
        
        return formatter.string(from: date)
    }
}

struct NewChatSelectionView: View {
    let onDietitianSelected: (ParticipantInfo) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var dietitians: [ParticipantInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading dietitians...")
                        .padding()
                } else if dietitians.isEmpty {
                    Text("No dietitians available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(dietitians, id: \.id) { dietitian in
                        Button(action: {
                            onDietitianSelected(dietitian)
                        }) {
                            HStack {
                                Circle()
                                    .fill(FitConnectColors.accentPurple)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "stethoscope")
                                            .foregroundColor(.white)
                                    )
                                
                                Text(dietitian.fullName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Dietitian")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDietitians()
            }
        }
    }
    
    private func loadDietitians() {
        // Mock data for now - replace with actual Firestore query
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dietitians = [
                ParticipantInfo(id: "dietitian1", fullName: "Dr. Sarah Johnson", photoURL: nil),
                ParticipantInfo(id: "dietitian2", fullName: "Dr. Mike Chen", photoURL: nil)
            ]
            self.isLoading = false
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientChatListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore(isLoggedIn: true, role: "client")
        return ClientChatListView()
            .environmentObject(mockSession)
            .preferredColorScheme(.dark)
    }
}
#endif
