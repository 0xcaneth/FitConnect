import SwiftUI
import FirebaseAuth

struct ClientsView: View {
    @StateObject private var clientsService = ClientsService()
    @State private var searchText = ""
    
    private var filteredClients: [DietitianClient] {
        if searchText.isEmpty {
            return clientsService.clients
        } else {
            return clientsService.clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var currentDietitianId: String {
        return Auth.auth().currentUser?.uid ?? "Not Available"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if clientsService.isLoading {
                    loadingView()
                } else if filteredClients.isEmpty && searchText.isEmpty {
                    emptyStateView()
                } else if filteredClients.isEmpty && !searchText.isEmpty {
                    noSearchResultsView()
                } else {
                    clientsListView()
                }
            }
            .navigationTitle("My Clients")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search clients...")
        }
        .alert("Error", isPresented: $clientsService.showingError) {
            Button("OK") {
                clientsService.clearError()
            }
        } message: {
            if let errorMessage = clientsService.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func clientsListView() -> some View {
        VStack(spacing: 0) {
            // Stats Header
            if !searchText.isEmpty {
                HStack {
                    Text("\(filteredClients.count) of \(clientsService.clients.count) clients")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            } else {
                statsHeaderView()
            }
            
            // Clients List
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(filteredClients) { client in
                        DietitianClientRow(client: client)
                            .onTapGesture {
                                // TODO: Navigate to client detail view
                                print("Tapped client: \(client.name)")
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Extra space for tab bar
            }
            .animation(.easeInOut(duration: 0.3), value: filteredClients)
        }
    }
    
    @ViewBuilder
    private func statsHeaderView() -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(clientsService.clients.count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Total Clients")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(onlineClientsCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#22C55E"))
                
                Text("Online Now")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1E1F25").opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#6E56E9").opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#6E56E9")))
                .scaleEffect(1.2)
            
            Text("Loading clients...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#6E56E9").opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.2.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(hex: "#6E56E9"))
            }
            
            VStack(spacing: 8) {
                Text("No Clients Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Clients will appear here when they connect to your expert service using your dietitian ID or QR code.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            VStack(spacing: 12) {
                Text("Your Dietitian ID:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                
                HStack {
                    Text(currentDietitianId)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#2A2E3B"))
                        )
                    
                    Button(action: {
                        UIPasteboard.general.string = currentDietitianId
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#6E56E9"))
                    }
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func noSearchResultsView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(Color(hex: "#6E56E9").opacity(0.6))
            
            Text("No Results Found")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text("No clients match '\(searchText)'")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var onlineClientsCount: Int {
        clientsService.clients.filter { $0.lastOnline.isOnline }.count
    }
}

#if DEBUG
struct ClientsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientsView()
            .preferredColorScheme(.dark)
    }
}
#endif