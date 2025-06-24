import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ClientsService: ObservableObject {
    @Published var clients: [DietitianClient] = []
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let db = Firestore.firestore()
    private var clientsListener: ListenerRegistration?
    
    init() {
        setupClientsListener()
    }
    
    private func setupClientsListener() {
        guard let dietitianId = Auth.auth().currentUser?.uid else {
            print("[ClientsService] No authenticated user found")
            self.isLoading = false
            return
        }
        
        print("[ClientsService] Setting up clients listener for dietitian: \(dietitianId)")
        
        // Listen to real-time updates on dietitians/{dietitianId}/clients
        clientsListener = db.collection("dietitians")
            .document(dietitianId)
            .collection("clients")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("[ClientsService] Error fetching clients: \(error.localizedDescription)")
                        self.errorMessage = "Failed to load clients: \(error.localizedDescription)"
                        self.showingError = true
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[ClientsService] No client documents found")
                        self.clients = []
                        self.isLoading = false
                        return
                    }
                    
                    print("[ClientsService] Found \(documents.count) client connections")
                    
                    // Extract client IDs from the documents
                    let clientIds = documents.map { $0.documentID }
                    let connectionDates = documents.reduce(into: [String: Date]()) { result, doc in
                        if let timestamp = doc.data()["connectedAt"] as? Timestamp {
                            result[doc.documentID] = timestamp.dateValue()
                        }
                    }
                    
                    // Fetch detailed client information
                    self.fetchClientDetails(clientIds: clientIds, connectionDates: connectionDates)
                }
            }
    }
    
    private func fetchClientDetails(clientIds: [String], connectionDates: [String: Date]) {
        guard !clientIds.isEmpty else {
            self.clients = []
            self.isLoading = false
            return
        }
        
        let group = DispatchGroup()
        var fetchedClients: [DietitianClient] = []
        
        for clientId in clientIds {
            group.enter()
            
            db.collection("users").document(clientId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    print("[ClientsService] Error fetching client \(clientId): \(error.localizedDescription)")
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    print("[ClientsService] Client document \(clientId) not found")
                    return
                }
                
                let client = DietitianClient(
                    id: clientId,
                    name: data["fullName"] as? String ?? "Unknown Client",
                    photoURL: data["photoURL"] as? String,
                    email: data["email"] as? String ?? "",
                    lastOnline: (data["lastOnline"] as? Timestamp)?.dateValue() ?? Date(),
                    connectedAt: connectionDates[clientId]
                )
                
                fetchedClients.append(client)
            }
        }
        
        group.notify(queue: .main) {
            // Sort clients by last online (most recent first)
            self.clients = fetchedClients.sorted { $0.lastOnline > $1.lastOnline }
            self.isLoading = false
            print("[ClientsService] Successfully loaded \(self.clients.count) clients")
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.showingError = false
        }
    }
    
    deinit {
        clientsListener?.remove()
        print("[ClientsService] Clients listener removed")
    }
}