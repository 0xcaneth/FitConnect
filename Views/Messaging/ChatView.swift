import SwiftUI

struct ChatView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: ChatViewModel
    @State private var currentText: String = ""
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            navigationBar()
            
            // Messages List
            messagesView()
            
            // Message Input
            messageInputView()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.10), // #0A0A1A
                    Color(red: 0.10, green: 0.10, blue: 0.12)  // #1A1A1F
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .onDisappear {
            viewModel.detachListener()
        }
    }
    
    @ViewBuilder
    private func navigationBar() -> some View {
        HStack {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(Color(red: 0.42, green: 0.31, blue: 0.85)) // #6E4EFF
            }
            
            Spacer()
            
            Text("Chat with Dietitian")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10)) // #14141A
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.3), value: showContent)
    }
    
    @ViewBuilder
    private func messagesView() -> some View {
        if viewModel.isLoading {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.9, blue: 1.0)))
                    .scaleEffect(1.2)
                Spacer()
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.senderId == viewModel.currentUserId
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func messageInputView() -> some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $currentText)
                .font(.system(size: 16))
                .padding(12)
                .background(Color(red: 0.20, green: 0.20, blue: 0.23)) // #333339
                .foregroundColor(.black)
                .cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(
                        currentText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? Color.gray
                        : Color(red: 0.0, green: 0.9, blue: 1.0) // #00E5FF
                    )
            }
            .disabled(currentText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.10, green: 0.10, blue: 0.12)) // #1A1A1F
    }
    
    private func sendMessage() {
        let messageText = currentText.trimmingCharacters(in: .whitespaces)
        guard !messageText.isEmpty else { return }
        
        viewModel.sendMessage(text: messageText)
        currentText = ""
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct MessageBubbleView: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                
                Text(message.text)
                    .font(.system(size: 16))
                    .padding(12)
                    .background(Color(red: 0.0, green: 0.9, blue: 1.0)) // #00E5FF
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    // Dietitian avatar
                    Circle()
                        .fill(Color(red: 0.42, green: 0.31, blue: 0.85)) // #6E4EFF
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("D")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(message.text)
                        .font(.system(size: 16))
                        .padding(12)
                        .background(Color(red: 0.20, green: 0.20, blue: 0.23)) // #333339
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                    
                    Spacer()
                }
            }
        }
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ChatViewModel(
            clientId: "client1",
            dietitianId: "dietitian1",
            currentUserId: "client1"
        )
        ChatView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}
#endif
