import SwiftUI
import FirebaseAuth

struct ConversationsView: View {
    @StateObject private var vm = ConversationsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.conversations) { convo in
                    ConversationRow(conversation: convo)
                        .contentShape(Rectangle())
                        .onTapGesture { vm.selectedConversation = convo }
                        .contextMenu {
                            Button(role: .destructive) {
                                vm.deleteConversation(convo)
                            } label: {
                                Text("Delete"); Image(systemName: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Chats")
            .background(Color("AppPrimaryBackground"))
            .onAppear { vm.listen() }
            .sheet(item: $vm.selectedConversation) { convo in
                ChatView(conversation: convo, currentUser: vm.currentUID)
            }
        }
    }
}

class ConversationsViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var selectedConversation: Conversation?
    let service = ChatService()
    let currentUID = Auth.auth().currentUser?.uid ?? "NO_USER"
    private var reg: ListenerRegistration?
    
    func listen() {
        reg?.remove()
        reg = service.getConversations(for: currentUID) { [weak self] items in
            self?.conversations = items
        }
    }
    
    func deleteConversation(_ convo: Conversation) {
        if let convoID = convo.id {
            service.deleteConversation(convoID)
        }
    }
}