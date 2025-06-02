import PhotosUI
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UIKit // For haptics and UIApplication

@available(iOS 16.0, *)
struct ChatView: View {
    let chatId: String
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dietitianName: String = "Dietitian"
    @State private var messages: [ChatMessage] = []
    @State private var newMessageText: String = ""
    @State private var isLoading: Bool = true
    @State private var listenerRegistration: ListenerRegistration?
    @State private var showErrorBorder: Bool = false
    @State private var showingAttachmentOptions: Bool = false
    @State private var isSendingAnimated: Bool = false
    @State private var animationProgress: CGFloat = 0.0
    @State private var isRecording: Bool = false
    @State private var textHeight: CGFloat = 40
    @State private var showingPhotoPicker: Bool = false
    @State private var showingDocumentPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var accentGradientColors: [Color] = [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]
    
    private var accentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: accentGradientColors),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    init(chatId: String) {
        self.chatId = chatId
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView()
                
                if isLoading {
                    loadingView()
                } else if messages.isEmpty {
                    emptyStateView()
                } else {
                    messagesScrollView()
                }
                
                whatsAppInputView()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupMessageListener()
        }
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.white.opacity(0.1)).clipShape(Circle())
            }
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(accentGradient).frame(width: 40, height: 40)
                    Image(systemName: "stethoscope").font(.system(size: 18, weight: .medium)).foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chat with \(dietitianName)")
                        .font(.custom("SFProRounded-Semibold", size: 16)).foregroundColor(.white)
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Online").font(.custom("SFProText-Regular", size: 12)).foregroundColor(.green)
                    }
                }
            }
            Spacer()
            
            Menu {
                Button(action: {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    print("View Profile tapped")
                }) {
                    Label("View Profile", systemImage: "person.circle")
                }
                
                Button(action: {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    print("Mute Conversation tapped")
                }) {
                    Label("Mute Conversation", systemImage: "speaker.slash")
                }

                Divider()

                Button(role: .destructive, action: {
                    let haptic = UIImpactFeedbackGenerator(style: .heavy)
                    haptic.impactOccurred()
                    print("Clear Chat tapped")
                }) {
                    Label("Clear Chat", systemImage: "trash")
                }
                
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .onTapGesture {
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Color(hex: "#0D0F14").opacity(0.9))
        .overlay(Rectangle().frame(height: 0.5).foregroundColor(Color.white.opacity(0.1)), alignment: .bottom)
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: accentGradientColors.first ?? .purple))
            Text("Loading conversation...")
                .font(.custom("SFProText-Regular", size: 16)).foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48, weight: .light)).foregroundStyle(accentGradient)
            Text("Start your conversation!")
                .font(.custom("SFProRounded-Semibold", size: 20)).foregroundColor(.white)
            Text("Send a message to begin chatting with your dietitian.")
                .font(.custom("SFProText-Regular", size: 16)).foregroundColor(Color.white.opacity(0.7))
                .multilineTextAlignment(.center).padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
        
    @ViewBuilder
    private func messagesScrollView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message, isFromCurrentUser: message.senderId == session.currentUserId)
                            .id(message.id)
                            .transition(.move(edge: message.senderId == session.currentUserId ? .trailing : .leading).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 16)
            }
            .onAppear { scrollToBottom(proxy: proxy, animated: false) }
            .onChange(of: messages.count) { newValue in
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onTapGesture { hideKeyboard() }
        }
    }
    
    @ViewBuilder
    private func whatsAppInputView() -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(alignment: .bottom, spacing: 8) {
                Button(action: {
                    let haptic = UIImpactFeedbackGenerator(style: .medium)
                    haptic.impactOccurred()
                    showingAttachmentOptions = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(accentGradient)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        )
                        .scaleEffect(showingAttachmentOptions ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: showingAttachmentOptions)
                }
                .accessibilityLabel("Attach media")
                .accessibilityHint("Tap to attach photos or files")
                
                HStack(alignment: .bottom, spacing: 8) {
                    whatsAppTextEditor()
                    
                    whatsAppActionButton()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: textHeight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 8)
        }
        .background(Color(hex: "#0D0F14").opacity(0.95))
        .actionSheet(isPresented: $showingAttachmentOptions) {
            ActionSheet(title: Text("Send Attachment"), message: Text("Select an option"), buttons: [
                .default(Text("Send Photo")) {
                    showingPhotoPicker = true
                    print("Send Photo tapped, showingPhotoPicker: \(showingPhotoPicker)")
                },
                .default(Text("Send File")) {
                    showingDocumentPicker = true
                    print("Send File tapped, showingDocumentPicker: \(showingDocumentPicker)")
                },
                .cancel()
            ])
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.item], // Allows all file types, can be restricted
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                // Handle the selected file URL
                print("Selected file: \(url.lastPathComponent)")
                // TODO: Implement file sending logic
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    // Handle the selected photo data
                    print("Selected photo data: \(data.count) bytes")
                    // TODO: Implement photo sending logic (e.g., upload to Firebase Storage)
                }
            }
        }
    }
    
    @ViewBuilder
    private func whatsAppTextEditor() -> some View {
        ZStack(alignment: .topLeading) {
            // Placeholder text
            if newMessageText.isEmpty {
                Text("Type a message...")
                    .font(.custom("SFProText-Regular", size: 16))
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
            }
            
            // Text editor with dynamic height
            GeometryReader { geometry in
                TextEditor(text: $newMessageText)
                    .font(.custom("SFProText-Regular", size: 16))
                    .foregroundColor(.primary)
                    .background(Color.clear)
                    .frame(minHeight: 24, maxHeight: min(getTextHeight(), 80))
                    .onChange(of: newMessageText) { _ in
                        updateTextHeight()
                    }
                    .onAppear {
                        // Remove default TextEditor background
                        UITextView.appearance().backgroundColor = UIColor.clear
                    }
            }
            .frame(height: max(24, min(getTextHeight(), 80)))
        }
        .frame(minHeight: 24)
        .accessibilityLabel("Message input")
        .accessibilityHint("Type your message here")
    }
    
    @ViewBuilder
    private func whatsAppActionButton() -> some View {
        let isEmpty = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        Button(action: {
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            haptic.impactOccurred()
            
            if isEmpty {
                // Start/stop voice recording
                isRecording.toggle()
                print("Voice recording: \(isRecording ? "started" : "stopped")")
            } else {
                // Send message
                sendMessage()
            }
        }) {
            Image(systemName: isEmpty ? "mic.fill" : "paperplane.fill")
                .font(.system(size: isEmpty ? 18 : 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(getButtonBackground(isEmpty: isEmpty))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                )
                .scaleEffect(isEmpty && isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isEmpty)
                .animation(.easeInOut(duration: 0.15), value: isRecording)
        }
        .accessibilityLabel(isEmpty ? "Record voice message" : "Send message")
        .accessibilityHint(isEmpty ? "Tap and hold to record" : "Tap to send your message")
    }
    
    private func getButtonBackground(isEmpty: Bool) -> LinearGradient {
        if isEmpty && isRecording {
            return LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.red]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            return accentGradient
        }
    }
    
    private func getTextHeight() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 16)
        let textView = UITextView()
        textView.font = font
        textView.text = newMessageText.isEmpty ? "Placeholder" : newMessageText
        
        let fixedWidth = UIScreen.main.bounds.width - 120
        let size = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        return max(24, min(size.height, 80))
    }
    
    private func updateTextHeight() {
        withAnimation(.easeInOut(duration: 0.2)) {
            textHeight = getTextHeight()
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        guard !messages.isEmpty, let lastMessageId = messages.last?.id else { return }
        if animated {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { proxy.scrollTo(lastMessageId, anchor: .bottom) }
        } else {
            proxy.scrollTo(lastMessageId, anchor: .bottom)
        }
    }
    
    private func setupMessageListener() {
        guard !session.currentUserId.isEmpty else { isLoading = false; return }
        removeMessageListener(); isLoading = true
        let db = Firestore.firestore()
        listenerRegistration = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { querySnapshot, error in
                isLoading = false
                if let error = error { print("[ChatView] Error listening: \(error.localizedDescription)"); return }
                guard let documents = querySnapshot?.documents else { messages = []; return }
                self.messages = documents.compactMap { doc -> ChatMessage? in
                    var msg = try? doc.data(as: ChatMessage.self)
                    msg?.id = doc.documentID; return msg
                }
            }
    }
    
    private func removeMessageListener() {
        listenerRegistration?.remove(); listenerRegistration = nil
    }
    
    private func sendMessage() {
        let textToSend = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToSend.isEmpty, !session.currentUserId.isEmpty else { return }
        
        showErrorBorder = false
        let currentSenderName = session.currentUser?.displayName ?? session.currentUser?.email ?? "User"
        let newMessage = ChatMessage(senderId: session.currentUserId, senderName: currentSenderName, text: textToSend)
        let db = Firestore.firestore(); let batch = db.batch()
        let messageRef = db.collection("chats").document(chatId).collection("messages").document()
        do {
            try batch.setData(Firestore.Encoder().encode(newMessage), forDocument: messageRef)
        } catch {
            print("[ChatView] Error encoding message for batch: \(error.localizedDescription)")
            self.showErrorBorder = true
            return
        }
        let chatRef = db.collection("chats").document(chatId)
        batch.updateData([
            "lastMessage": textToSend, "updatedAt": Timestamp(date: Date()),
            "participants": FieldValue.arrayUnion([session.currentUserId])
        ], forDocument: chatRef)
        
        batch.commit { error in
            if let error = error {
                print("[ChatView] Error sending message: \(error.localizedDescription)")
                self.showErrorBorder = true
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.newMessageText = ""
                    self.textHeight = 40
                }
                hideKeyboard()
            }
        }
    }
}

private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    private var dietitianBubbleGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#0E1E3D"), Color(hex: "#13274C")]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    private var clientBubbleGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color(hex: "#102849"), Color(hex: "#0A1635")]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 50) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.custom("SFProText-Medium", size: 12)).foregroundColor(Color.white.opacity(0.6)).padding(.leading, 10)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(message.text)
                        .font(.custom("SFProText-Regular", size: 15))
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .background(isFromCurrentUser ? clientBubbleGradient : dietitianBubbleGradient)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                }
                
                Text(formatTimestamp(message.timestamp))
                    .font(.custom("SFProText-Regular", size: 10)).foregroundColor(Color.white.opacity(0.5)).padding(.horizontal, 12)
            }
            .contentShape(Rectangle())
            .contextMenu {
                if isFromCurrentUser {
                    Button {
                        print("Edit message tapped: \(message.text)")
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }

                Button(role: .destructive) {
                    if isFromCurrentUser {
                        print("Delete message tapped: \(message.text)")
                    } else {
                        print("Context menu on other user's message (delete placeholder): \(message.text)")
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
        .padding(.vertical, 3)
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "h:mm a"; formatter.amSymbol = "AM"; formatter.pmSymbol = "PM"
        return formatter.string(from: timestamp.dateValue())
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore()
        ChatView(chatId: "preview_chat_id_123")
            .environmentObject(mockSession)
            .preferredColorScheme(.dark)
    }
}
#endif
