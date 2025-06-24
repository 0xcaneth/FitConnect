import SwiftUI
import FirebaseFirestore
import Combine
import FitConnect

@available(iOS 16.0, *)
struct DietitianMessagesListView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = DietitianMessagesListViewModel()
    @State private var selectedChat: ChatSummary?

    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else if viewModel.chats.isEmpty {
                    emptyStateView
                } else {
                    chatListView
                }
            }
            .navigationTitle("Client Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FitConnectColors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                viewModel.setup(session: session)
            }
            .sheet(item: $selectedChat) { chatToPresent in
                if let dietitianId = session.currentUserId {
                    NavigationView {
                        DietitianChatDetailView(
                            viewModel: DietitianChatDetailViewModel(chat: chatToPresent, currentDietitianId: dietitianId)
                        )
                        .environmentObject(session)
                    }
                } else {
                    Text("Error: Dietitian session not found.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
            Text("Loading client conversations...")
                .font(.system(size: 16))
                .foregroundColor(FitConnectColors.textSecondary)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                viewModel.setup(session: session)
            }
            .padding()
            .background(FitConnectColors.accentCyan)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No client conversations yet")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Clients will appear here when they start conversations with you")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var chatListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    if let clientInfo = chat.otherParticipant(currentUserId: session.currentUserId ?? "") {
                        DietitianChatRowView(
                            chat: chat,
                            clientInfo: clientInfo,
                            unreadCount: chat.unreadCounts[session.currentUserId ?? ""] ?? 0
                        )
                        .onTapGesture {
                            selectedChat = chat
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
}

@MainActor
class DietitianMessagesListViewModel: ObservableObject {
    @Published var chats: [ChatSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var chatListener: ListenerRegistration?
    private var session: SessionStore?
    
    func setup(session: SessionStore) {
        print("[DietitianMessagesListVM] Setup called")
        self.session = session
        startListeningForChats()
    }
    
    private func startListeningForChats() {
        guard let dietitianId = session?.currentUserId else {
            errorMessage = "Dietitian ID not found. Please log in."
            print("[DietitianMessagesListVM] No dietitianId found")
            return
        }
        
        print("[DietitianMessagesListVM] Starting to listen for chats for dietitian: \(dietitianId)")
        isLoading = true
        errorMessage = nil
        
        chatListener = ChatService.shared.observeChats(forUserId: dietitianId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let fetchedChats):
                    self.chats = fetchedChats
                    self.errorMessage = nil
                    print("[DietitianMessagesListVM] Successfully loaded \(self.chats.count) chats")
                case .failure(let error):
                    self.errorMessage = "Failed to load conversations: \(error.localizedDescription)"
                    self.chats = []
                    print("[DietitianMessagesListVM] Error: \(error)")
                }
            }
        }
    }
    
    deinit {
        chatListener?.remove()
    }
}

struct DietitianChatRowView: View {
    let chat: ChatSummary
    let clientInfo: ParticipantInfo
    let unreadCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: clientInfo.photoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(FitConnectColors.accentCyan)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clientInfo.fullName)
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

#if DEBUG
@available(iOS 16.0, *)
struct DietitianMessagesListView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianMessagesListView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif
