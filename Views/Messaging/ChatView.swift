import SwiftUI
import PhotosUI
import FirebaseAuth

struct ChatView: View {
    let conversation: Conversation
    let currentUser: String

    @StateObject var vm = ChatViewModel()
    @State private var newMsg = ""
    @State private var sending = false
    @State private var showImagePicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var imageUploading = false

    var body: some View {
        VStack {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(vm.messages) { msg in
                            MessageBubbleView(msg: msg, isMine: msg.senderUID == currentUser)
                                .id(msg.id)
                                .contextMenu {
                                    Button("Copy") { UIPasteboard.general.string = msg.text ?? "" }
                                    Button("Mark as Feedback") { vm.markFeedback(conversation: conversation, message: msg) }
                                    Button(role: .destructive) { vm.deleteMsg(conversation: conversation, msg: msg) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _, _ in
                    if let last = vm.messages.last?.id { withAnimation {
                        scrollProxy.scrollTo(last, anchor: .bottom)
                    } }
                }
            }
            Divider()
            HStack {
                TextField("Message...", text: $newMsg)
                    .textFieldStyle(.roundedBorder)
                    .disabled(sending)
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                }
                .onChange(of: photoPickerItem) { _, item in
                    guard let item else { return }
                    imageUploading = true
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            vm.sendImage(convo: conversation, currentUser: currentUser, image: uiImage) {
                                imageUploading = false
                            }
                        } else {
                            imageUploading = false
                        }
                    }
                }
                Button("Send") {
                    sending = true
                    vm.send(convo: conversation, text: newMsg, currentUser: currentUser) {
                        sending = false
                        newMsg = ""
                    }
                }
                .disabled(newMsg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending || imageUploading)
            }
            .padding()
        }
        .navigationTitle(conversation.otherParticipantName ?? "Chat")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color("Background"))
        .onAppear { vm.subscribe(conversationID: conversation.id) }
        .alert(vm.errorMessage ?? "", isPresented: $vm.showError) { Button("OK", role: .cancel) { } }
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    
    private var reg: ListenerRegistration?
    let service = ChatService()

    func subscribe(conversationID: String?) {
        reg?.remove()
        guard let conversationID else { return }
        reg = service.getMessages(conversationID: conversationID) { [weak self] msgs in
            DispatchQueue.main.async {
                self?.messages = msgs
            }
        }
    }

    func send(convo: Conversation, text: String, currentUser: String, done: @escaping () -> Void) {
        guard let convoID = convo.id else { done(); return }
        service.sendMessage(conversationID: convoID, senderUID: currentUser, text: text) { [weak self] error in
            if let e = error {
                self?.errorMessage = e.localizedDescription
                self?.showError = true
            }
            done()
        }
    }

    func sendImage(convo: Conversation, currentUser: String, image: UIImage, done: @escaping () -> Void) {
        guard let convoID = convo.id else { done(); return }
        let path = "chatmedia/\(convoID)/\(UUID().uuidString).jpg"
        service.uploadImage(image, path: path) { [weak self] result in
            switch result {
            case .success(let url):
                self?.service.sendMessage(conversationID: convoID, senderUID: currentUser, text: nil, imageURL: url.absoluteString) { _ in done() }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                self?.showError = true
                done()
            }
        }
    }
    
    func markFeedback(conversation: Conversation, message: ChatMessage) {
        // Not implemented: For demo, would update message document's isFeedback property
    }
    
    func deleteMsg(conversation: Conversation, msg: ChatMessage) {
        // Not implemented: For demo, would delete a message document
    }
}