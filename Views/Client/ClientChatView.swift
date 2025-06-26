import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientChatView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var messagingService = MessagingService.shared
    @State private var dietitianInfo: DietitianInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showError = false
    
    private struct DietitianInfo {
        let id: String
        let name: String
        let avatarUrl: String?
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if let dietitian = dietitianInfo {
                    // Direct chat with dietitian
                    ClientChatDetailView(
                        recipientId: dietitian.id,
                        recipientName: dietitian.name,
                        recipientAvatarUrl: dietitian.avatarUrl
                    )
                    .environmentObject(session)
                } else {
                    noDietitianView
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(FitConnectColors.backgroundDark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                loadDietitianInfo()
            }
            .alert("Error", isPresented: $showError) {
                Button("Retry") {
                    loadDietitianInfo()
                }
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
            Text("Loading your dietitian...")
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
                loadDietitianInfo()
            }
            .padding()
            .background(FitConnectColors.accentCyan)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var noDietitianView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No dietitian assigned")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("You haven't been assigned to a dietitian yet. Once assigned, you'll be able to chat with them here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Connect with Expert") {
                // Navigate to expert connection view
                // This could open ExpertPanelView or similar
            }
            .padding()
            .background(FitConnectColors.accentCyan)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func loadDietitianInfo() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let dietitian = try await fetchAssignedDietitian()
                await MainActor.run {
                    self.dietitianInfo = dietitian
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    self.showError = true
                }
            }
        }
    }
    
    private func fetchAssignedDietitian() async throws -> DietitianInfo? {
        guard let currentUserId = session.currentUserId else {
            throw NSError(domain: "ClientChatView", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let db = Firestore.firestore()
        
        // First, check if user has assignedDietitianId
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let userData = userDoc.data() else {
            throw NSError(domain: "ClientChatView", code: 2, userInfo: [NSLocalizedDescriptionKey: "User data not found"])
        }
        
        var dietitianId: String?
        
        // Check assignedDietitianId first
        if let assignedId = userData["assignedDietitianId"] as? String, !assignedId.isEmpty {
            dietitianId = assignedId
        }
        // If not found, check expertId
        else if let expertId = userData["expertId"] as? String, !expertId.isEmpty {
            dietitianId = expertId
        }
        // If still not found, check if this client appears in any dietitian's clients list
        else {
            let dietitiansSnapshot = try await db.collection("dietitians").getDocuments()
            for dietitianDoc in dietitiansSnapshot.documents {
                let clientDoc = try await dietitianDoc.reference.collection("clients").document(currentUserId).getDocument()
                if clientDoc.exists {
                    dietitianId = dietitianDoc.documentID
                    break
                }
            }
        }
        
        guard let finalDietitianId = dietitianId else {
            return nil // No dietitian assigned
        }
        
        // Fetch dietitian details
        let dietitianDoc = try await db.collection("users").document(finalDietitianId).getDocument()
        guard let dietitianData = dietitianDoc.data() else {
            throw NSError(domain: "ClientChatView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Dietitian data not found"])
        }
        
        let name = dietitianData["fullName"] as? String ?? "Dietitian"
        let avatarUrl = dietitianData["photoURL"] as? String
        
        return DietitianInfo(id: finalDietitianId, name: name, avatarUrl: avatarUrl)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientChatView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore(isLoggedIn: true, role: "client")
        return ClientChatView()
            .environmentObject(mockSession)
            .preferredColorScheme(.dark)
    }
}
#endif