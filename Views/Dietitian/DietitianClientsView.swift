import SwiftUI
import FirebaseFirestore

// Mock client data structure
struct ClientData: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let avatarURL: String?
}

@MainActor
class DietitianClientsViewModel: ObservableObject {
    @Published var clients: [ClientData] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var showNewClientModal = false
    
    // Mock data for demonstration
    init() {
        loadMockClients()
    }
    
    private func loadMockClients() {
        clients = [
            ClientData(name: "Jane Smith", lastMessage: "Last message sue.", timestamp: Date(), unreadCount: 0, avatarURL: nil),
            ClientData(name: "Robert Johnson", lastMessage: "Early earlimore", timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), unreadCount: 0, avatarURL: nil),
            ClientData(name: "Emily Davis", lastMessage: "Last messages", timestamp: Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date(), unreadCount: 0, avatarURL: nil),
            ClientData(name: "Michael Wilson", lastMessage: "", timestamp: Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date(), unreadCount: 0, avatarURL: nil)
        ]
    }
    
    var filteredClients: [ClientData] {
        if searchText.isEmpty {
            return clients
        }
        return clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    func addNewClient(name: String, email: String) {
        // Here you would implement actual client creation logic
        let newClient = ClientData(
            name: name,
            lastMessage: "No messages yet",
            timestamp: Date(),
            unreadCount: 0,
            avatarURL: nil
        )
        clients.append(newClient)
    }
}

struct DietitianClientsView: View {
    @StateObject private var viewModel = DietitianClientsViewModel()
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0A0A0F")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with FAB
                ZStack {
                    HStack {
                        Text("My Clients")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        
                        // Floating Action Button
                        Button(action: {
                            viewModel.showNewClientModal = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 96, height: 96)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#9333EA") ?? .purple, Color(hex: "#3C00FF") ?? .indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    TextField("Search clients...", text: $viewModel.searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Content
                ScrollView {
                    if viewModel.filteredClients.isEmpty {
                        // Empty State
                        VStack(spacing: 20) {
                            Image(systemName: "person.2")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.gray)
                            
                            Text("No clients assigned yet")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.filteredClients.enumerated()), id: \.element.id) { index, client in
                                ClientRow(client: client)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(x: showContent ? 0 : 300)
                                    .animation(.easeOut(duration: 0.5).delay(Double(index) * 0.1), value: showContent)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
        .sheet(isPresented: $viewModel.showNewClientModal) {
            NewClientModalView(
                onCancel: {
                    viewModel.showNewClientModal = false
                },
                onAddClient: { name, email in
                    viewModel.addNewClient(name: name, email: email)
                    viewModel.showNewClientModal = false
                }
            )
        }
    }
}

struct ClientRow: View {
    let client: ClientData
    
    var body: some View {
        ZStack {
            // Card background with purple outline
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#9333EA") ?? .purple, lineWidth: 2)
                )
            
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(client.name)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                    
                    if !client.lastMessage.isEmpty {
                        Text(client.lastMessage)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Right side content
                VStack(alignment: .trailing, spacing: 8) {
                    Text(timeString(from: client.timestamp))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    if client.unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Text("\(client.unreadCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(height: 80)
    }
    
    private func timeString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.compare(date, to: now, toGranularity: .day) == .orderedSame {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.dateInterval(of: .day, for: now)?.start.timeIntervalSince(calendar.dateInterval(of: .day, for: date)?.start ?? date) == 86400 {
            return "Mon"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

#if DEBUG
struct DietitianClientsView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianClientsView()
    }
}
#endif
