import SwiftUI
import FirebaseFirestore
import Combine

@available(iOS 16.0, *)
struct DietitianMessagesListView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var messagingService = MessagingService.shared
    @State private var conversations: [ConversationPreview] = []
    @State private var selectedConversation: ConversationPreview?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
                }
            }
            .navigationTitle("Client Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FitConnectColors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadConversations()
            }
            .sheet(item: $selectedConversation) { conversation in
                NavigationStack {
                    DietitianChatDetailView(
                        recipientId: conversation.id,
                        recipientName: conversation.otherUserName,
                        recipientAvatarUrl: conversation.otherUserAvatarUrl
                    )
                    .environmentObject(session)
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
                loadConversations()
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
    
    private var conversationListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(conversations) { conversation in
                    DietitianConversationRowView(conversation: conversation)
                        .onTapGesture {
                            selectedConversation = conversation
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    private func loadConversations() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                for try await conversationPreviews in messagingService.getConversationPreviews() {
                    // Filter only conversations with clients
                    let clientConversations = conversationPreviews.filter { conversation in
                        // Here you might want to add additional filtering based on user roles
                        // For now, we'll show all conversations
                        return true
                    }
                    
                    await MainActor.run {
                        self.conversations = clientConversations
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct DietitianConversationRowView: View {
    let conversation: ConversationPreview
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: conversation.otherUserAvatarUrl ?? "")) { image in
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
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage.displayText)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                } else {
                    Text("No messages yet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Time and unread count
            VStack(alignment: .trailing, spacing: 4) {
                if let lastMessage = conversation.lastMessage {
                    Text(relativeTimeString(from: lastMessage.timestamp))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
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