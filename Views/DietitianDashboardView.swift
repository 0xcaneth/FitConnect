import SwiftUI
import FirebaseFirestore

struct DietitianDashboardView: View {
    @EnvironmentObject var session: SessionStore
    @State private var clients: [UserProfile] = []
    @State private var showingChat = false
    @State private var selectedClient: UserProfile?
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection()
                    
                    // Clients List
                    if clients.isEmpty {
                        emptyStateView()
                    } else {
                        clientsListView()
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6), value: showContent)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            fetchClients()
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showingChat) {
            if #available(iOS 16.0, *) {
                if let client = selectedClient {
                    ChatSheetView(
                        clientId: client.uid,
                        dietitianId: session.currentUserId,
                        clientName: client.fullName
                    )
                    .environmentObject(session)
                }
            } else {
                // Fallback on earlier versions
                // You could show an alert or a different view here
                Text("Chat feature requires iOS 16 or later.")
            }
        }
    }
    
    @ViewBuilder
    private func headerSection() -> some View {
        VStack(spacing: 16) {
            // Top navigation bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dietitian Dashboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                    
                    Text("Manage your clients")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                }
                
                Spacer()
                
                // Sign out button
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                    impactFeedback.impactOccurred()
                    try? session.signOut()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.2)) // #FF3B30
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "power")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19)) // #FF3B30
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Stats cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Clients",
                    value: "\(clients.count)",
                    icon: "person.3.fill",
                    color: Color(red: 0.0, green: 0.9, blue: 1.0) // #00E5FF
                )
                
                StatCard(
                    title: "Active Chats",
                    value: "\(clients.count)",
                    icon: "bubble.left.and.bubble.right.fill",
                    color: Color(red: 0.43, green: 0.31, blue: 1.0) // #6E4EFF
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func clientsListView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clients")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                .padding(.horizontal, 20)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(clients) { client in
                        ClientRow(
                            client: client,
                            onChatTap: {
                                selectedClient = client
                                showingChat = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
            
            Text("No Clients Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
            
            Text("Assigned clients will appear here.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func fetchClients() {
        Firestore.firestore()
            .collection("users")
            .whereField("role", isEqualTo: "client")
            .whereField("assignedDietitianId", isEqualTo: session.currentUserId)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self.clients = docs.compactMap { doc in
                    let data = doc.data()
                    guard let fullName = data["fullName"] as? String,
                          let email = data["email"] as? String else { return nil }
                    return UserProfile(uid: doc.documentID, fullName: fullName, email: email)
                }
            }
    }
}

struct UserProfile: Identifiable {
    let uid: String
    let fullName: String
    let email: String
    var id: String { uid }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
            }
            
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9)) // #1E1E26 @90%
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
    }
}

struct ClientRow: View {
    let client: UserProfile
    let onChatTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.43, green: 0.31, blue: 1.0), // #6E4EFF
                            Color(red: 0.0, green: 0.9, blue: 1.0)   // #00E5FF
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(client.fullName.prefix(1)).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Client info
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                
                Text(client.email)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
            }
            
            Spacer()
            
            // Chat button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onChatTap()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Chat")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                    Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9)) // #1E1E26 @90%
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

@available(iOS 16.0, *)
struct ChatSheetView: View {
    let clientId: String
    let dietitianId: String  
    let clientName: String
    @EnvironmentObject var session: SessionStore
    @State private var chatId: String?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Setting up chat...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.07, green: 0.08, blue: 0.10)) // #0D0F14
            } else if let chatId = chatId {
                NavigationView {
                    ChatView(chatId: chatId)
                        .navigationTitle("Chat with \(clientName)")
                        .navigationBarTitleDisplayMode(.inline)
                        .environmentObject(session)
                }
            } else {
                VStack {
                    Text("Error creating chat")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.07, green: 0.08, blue: 0.10)) // #0D0F14
            }
        }
        .onAppear {
            createOrFindChat()
        }
    }
    
    private func createOrFindChat() {
        let participantIds = [clientId, dietitianId].sorted()
        let generatedChatId = "chat_\(participantIds.joined(separator: "_"))"
        
        let db = Firestore.firestore()
        let chatRef = db.collection("chats").document(generatedChatId)
        
        chatRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ChatSheetView] Error checking for existing chat: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                if let document = document, document.exists {
                    // Chat exists
                    print("[ChatSheetView] Using existing chat: \(generatedChatId)")
                    self.chatId = generatedChatId
                    self.isLoading = false
                } else {
                    // Create new chat
                    let newChat = Chat(
                        participants: [clientId, dietitianId],
                        lastMessage: "",
                        updatedAt: Timestamp(date: Date()),
                        createdAt: Timestamp(date: Date())
                    )
                    
                    do {
                        try chatRef.setData(from: newChat) { error in
                            if let error = error {
                                print("[ChatSheetView] Error creating new chat: \(error.localizedDescription)")
                                self.isLoading = false
                            } else {
                                print("[ChatSheetView] Successfully created new chat: \(generatedChatId)")
                                self.chatId = generatedChatId
                                self.isLoading = false
                            }
                        }
                    } catch {
                        print("[ChatSheetView] Error encoding new chat: \(error.localizedDescription)")
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

#if DEBUG
struct DietitianDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianDashboardView()
            .environmentObject(SessionStore())
            .preferredColorScheme(.dark)
    }
}
#endif
