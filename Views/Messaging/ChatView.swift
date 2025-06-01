import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    let chatId: String
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var messages: [ChatMessage] = []
    @State private var newMessageText: String = ""
    @State private var isLoading: Bool = true
    @State private var listenerRegistration: ListenerRegistration?
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if messages.isEmpty {
                            Text("No messages yet. Start the conversation!")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(Color(hex: "#B0B3BA"))
                                .padding(.top, 50)
                        } else {
                            ForEach(messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == session.currentUserId
                                )
                                .id(message.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    // Auto scroll to bottom when new message arrives
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input Bar
            HStack(spacing: 12) {
                TextField("Type a message…", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16, design: .rounded))
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "#1E1F25"))
        }
        .background(Color(hex: "#0D0F14"))
        .navigationTitle("Chat with Dietitian")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupMessageListener()
        }
        .onDisappear {
            removeMessageListener()
        }
    }
    
    private func setupMessageListener() {
        guard !session.currentUserId.isEmpty else {
            print("[ChatView] User not logged in, cannot setup message listener.")
            isLoading = false
            return
        }
        
        removeMessageListener()
        
        let db = Firestore.firestore()
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        
        listenerRegistration = messagesRef
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("[ChatView] Error listening to messages: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("[ChatView] No messages found")
                        self.messages = []
                        return
                    }
                    
                    self.messages = documents.compactMap { document in
                        do {
                            return try document.data(as: ChatMessage.self)
                        } catch {
                            print("[ChatView] Error decoding message \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("[ChatView] Loaded \(self.messages.count) messages")
                }
            }
    }
    
    private func removeMessageListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    private func sendMessage() {
        let messagetext = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messagetext.isEmpty, !session.currentUserId.isEmpty else { return }
        
        let currentUser = session.currentUser
        let senderName = currentUser?.displayName ?? currentUser?.email ?? "Unknown User"
        
        let newMessage = ChatMessage(
            senderId: session.currentUserId,
            senderName: senderName,
            text: messagetext,
            timestamp: Timestamp(date: Date())
        )
        
        let db = Firestore.firestore()
        let messagesRef = db.collection("chats").document(chatId).collection("messages")
        let chatRef = db.collection("chats").document(chatId)
        
        // Add message to subcollection
        do {
            try messagesRef.addDocument(from: newMessage) { error in
                if let error = error {
                    print("[ChatView] Error sending message: \(error.localizedDescription)")
                    // TODO: Show error to user
                } else {
                    print("[ChatView] Message sent successfully")
                    
                    // Update chat metadata
                    chatRef.updateData([
                        "lastMessage": messagetext,
                        "updatedAt": Timestamp(date: Date())
                    ]) { error in
                        if let error = error {
                            print("[ChatView] Error updating chat metadata: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            print("[ChatView] Error encoding message: \(error.localizedDescription)")
        }
        
        // Clear input field
        newMessageText = ""
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                Text(message.text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: isCurrentUser ? 
                                [Color(hex: "#102849"), Color(hex: "#0A1635")] :
                                [Color(hex: "#0E1E3D"), Color(hex: "#13274C")]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#8A8F9B"))
            }
            .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp.dateValue())
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(chatId: "preview-chat-id")
                .environmentObject(SessionStore.previewStore())
        }
        .preferredColorScheme(.dark)
    }
}
#endif
