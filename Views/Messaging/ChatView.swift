import PhotosUI
import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit
import UniformTypeIdentifiers
import AVKit

@available(iOS 16.0, *)
struct ChatView: View {
    let chatId: String
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var chatService = EnhancedChatService.shared
    @State private var newMessageText: String = ""
    @State private var isLoading: Bool = true
    @State private var showingImageViewer = false
    @State private var selectedImageURL = ""
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL = ""
    @State private var lastTypingTime = Date()
    
    private let typingDebounceTime: TimeInterval = 1.0
    
    var otherParticipant: ParticipantInfo? {
        guard let currentUserId = session.currentUserId,
              let chat = chatService.chats.first(where: { $0.id == chatId }) else {
            return nil
        }
        return chat.otherParticipant(currentUserId: currentUserId)
    }
    
    var recipientId: String {
        return otherParticipant?.id ?? ""
    }
    
    var body: some View {
        ZStack {
            FitConnectColors.backgroundDark.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if isLoading {
                    loadingView
                } else if chatService.messages.isEmpty {
                    emptyStateView
                } else {
                    messagesScrollView
                }
                
                // Typing indicator
                if !chatService.typingUsers.isEmpty {
                    typingIndicatorView
                }
                
                enhancedInputView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupChat()
        }
        .onDisappear {
            cleanup()
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            FullScreenImageViewer(imageURL: selectedImageURL, isPresented: $showingImageViewer)
        }
        .fullScreenCover(isPresented: $showingVideoPlayer) {
            if let url = URL(string: selectedVideoURL) {
                VideoPlayer(player: AVPlayer(url: url))
                    .overlay(alignment: .topTrailing) {
                        Button("Done") {
                            showingVideoPlayer = false
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .padding()
                    }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            HStack(spacing: 12) {
                // Participant avatar
                AsyncImage(url: URL(string: otherParticipant?.photoURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(FitConnectColors.accentPurple)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "stethoscope")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(otherParticipant?.fullName ?? "Chat")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(chatService.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(chatService.isConnected ? "Online" : "Offline")
                            .font(.system(size: 12))
                            .foregroundColor(chatService.isConnected ? .green : .gray)
                    }
                }
            }
            
            Spacer()
            
            // Menu button
            Menu {
                Button("Mark as Read") {
                    markAllAsRead()
                }
                Button("Clear Chat", role: .destructive) {
                    // TODO: Implement clear chat
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(FitConnectColors.backgroundDark)
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
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentPurple))
            Text("Loading conversation...")
                .font(.body)
                .foregroundColor(FitConnectColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(FitConnectColors.accentPurple)
            
            Text("Start your conversation!")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Send a message to begin chatting with your \(session.role == "client" ? "dietitian" : "client").")
                .font(.body)
                .foregroundColor(FitConnectColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatService.messages) { message in
                        EnhancedMessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.senderId == session.currentUserId,
                            userRole: session.role,
                            onRetry: {
                                chatService.retryMessage(message)
                            },
                            onImageTap: { imageURL in
                                selectedImageURL = imageURL
                                showingImageViewer = true
                            },
                            onVideoTap: { videoURL in
                                selectedVideoURL = videoURL
                                showingVideoPlayer = true
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            }
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: chatService.messages.count) { _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    private var typingIndicatorView: some View {
        HStack {
            HStack(spacing: 8) {
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(FitConnectColors.textSecondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: chatService.typingUsers.count
                            )
                    }
                }
                
                Text("\(typingUsersText) typing...")
                    .font(.caption)
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(FitConnectColors.cardBackground)
            )
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: chatService.typingUsers.count)
    }
    
    private var enhancedInputView: some View {
        EnhancedChatInputView(
            text: $newMessageText,
            chatId: chatId,
            sender: ParticipantInfo(
                id: session.currentUserId ?? "",
                fullName: session.currentUser?.fullName ?? ""
            ),
            recipientId: recipientId,
            onSendText: {
                sendTextMessage()
            },
            onSendImage: { imageData in
                sendImageMessage(imageData)
            },
            onSendVideo: { videoURL in
                sendVideoMessage(videoURL)
            },
            onTypingChanged: { isTyping in
                handleTypingChanged(isTyping)
            }
        )
    }
    
    private var typingUsersText: String {
        let typingUserNames = chatService.typingUsers
            .filter { $0.userId != session.currentUserId }
            .map { $0.userName }
        
        if typingUserNames.count == 1 {
            return typingUserNames.first ?? "Someone is"
        } else if typingUserNames.count == 2 {
            return "\(typingUserNames[0]) and \(typingUserNames[1]) are"
        } else if typingUserNames.count > 2 {
            return "Multiple people are"
        } else {
            return "Someone is"
        }
    }
    
    // MARK: - Actions
    
    private func setupChat() {
        guard let currentUserId = session.currentUserId else { return }
        
        // Start listening to messages and typing indicators
        chatService.startListeningToMessages(chatId: chatId)
        
        // Mark messages as read when view appears
        Task {
            try await chatService.markMessagesAsRead(chatId: chatId, userId: currentUserId)
        }
        
        isLoading = false
    }
    
    private func cleanup() {
        chatService.stopListening(to: "messages_\(chatId)")
        chatService.stopListening(to: "typing_\(chatId)")
        
        // Stop typing indicator
        if let currentUserId = session.currentUserId,
           let userName = session.currentUser?.fullName {
            chatService.updateTypingIndicator(
                chatId: chatId,
                userId: currentUserId,
                userName: userName,
                isTyping: false
            )
        }
    }
    
    private func sendTextMessage() {
        guard let currentUserId = session.currentUserId,
              let currentUserName = session.currentUser?.fullName,
              !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        newMessageText = ""
        
        Task {
            do {
                try await chatService.sendTextMessage(
                    chatId: chatId,
                    senderId: currentUserId,
                    senderName: currentUserName,
                    text: text,
                    recipientId: recipientId
                )
                
                // Stop typing indicator
                chatService.updateTypingIndicator(
                    chatId: chatId,
                    userId: currentUserId,
                    userName: currentUserName,
                    isTyping: false
                )
            } catch {
                print("Failed to send message: \(error)")
                // TODO: Handle error (add to failed messages)
            }
        }
    }
    
    private func sendImageMessage(_ imageData: Data) {
        guard let currentUserId = session.currentUserId,
              let currentUserName = session.currentUser?.fullName else {
            return
        }
        
        Task {
            do {
                try await chatService.sendImageMessage(
                    chatId: chatId,
                    senderId: currentUserId,
                    senderName: currentUserName,
                    imageData: imageData,
                    text: newMessageText.trimmingCharacters(in: .whitespacesAndNewlines),
                    recipientId: recipientId
                )
                
                if !newMessageText.isEmpty {
                    newMessageText = ""
                }
            } catch {
                print("Failed to send image: \(error)")
            }
        }
    }
    
    private func sendVideoMessage(_ videoURL: URL) {
        guard let currentUserId = session.currentUserId,
              let currentUserName = session.currentUser?.fullName else {
            return
        }
        
        Task {
            do {
                try await chatService.sendVideoMessage(
                    chatId: chatId,
                    senderId: currentUserId,
                    senderName: currentUserName,
                    videoURL: videoURL,
                    text: newMessageText.trimmingCharacters(in: .whitespacesAndNewlines),
                    recipientId: recipientId
                )
                
                if !newMessageText.isEmpty {
                    newMessageText = ""
                }
            } catch {
                print("Failed to send video: \(error)")
            }
        }
    }
    
    private func handleTypingChanged(_ isTyping: Bool) {
        guard let currentUserId = session.currentUserId,
              let currentUserName = session.currentUser?.fullName else {
            return
        }
        
        lastTypingTime = Date()
        
        chatService.updateTypingIndicator(
            chatId: chatId,
            userId: currentUserId,
            userName: currentUserName,
            isTyping: isTyping
        )
        
        // Auto-stop typing indicator after debounce time
        if isTyping {
            DispatchQueue.main.asyncAfter(deadline: .now() + typingDebounceTime) {
                if Date().timeIntervalSince(self.lastTypingTime) >= self.typingDebounceTime {
                    chatService.updateTypingIndicator(
                        chatId: chatId,
                        userId: currentUserId,
                        userName: currentUserName,
                        isTyping: false
                    )
                }
            }
        }
    }
    
    private func markAllAsRead() {
        guard let currentUserId = session.currentUserId else { return }
        
        Task {
            do {
                try await chatService.markMessagesAsRead(chatId: chatId, userId: currentUserId)
            } catch {
                print("Failed to mark messages as read: \(error)")
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard !chatService.messages.isEmpty,
              let lastMessageId = chatService.messages.last?.id else { return }
        
        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                proxy.scrollTo(lastMessageId, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessageId, anchor: .bottom)
        }
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct FullScreenImageViewer: View {
    let imageURL: String
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .failure(_):
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.6))
                        Text("Failed to load image")
                            .foregroundColor(.white.opacity(0.6))
                    }
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore(isLoggedIn: true, unreadNotifications: 0)
        return ChatView(chatId: "preview_chat_id_123")
            .environmentObject(mockSession)
            .preferredColorScheme(.dark)
    }
}
#endif
