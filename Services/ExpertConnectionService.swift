import Foundation
import FirebaseFirestore
import FirebaseAuth

class ExpertConnectionService: ObservableObject {
    static let shared = ExpertConnectionService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Link to Expert
    
    func linkExpert(dietitianId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ExpertConnectionError.noCurrentUser
        }
        
        print("[ExpertConnectionService] Linking user \(userId) to expert \(dietitianId)")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // First, verify the dietitian exists in users collection with role "dietitian"
            let dietitianDoc = try await db.collection("users").document(dietitianId).getDocument()
            
            guard dietitianDoc.exists,
                  let data = dietitianDoc.data(),
                  let role = data["role"] as? String,
                  role == "dietitian" else {
                throw ExpertConnectionError.dietitianNotFound
            }
            
            // Add client document under dietitians/{dietitianId}/clients using the dietitian's uid
            try await db.collection("dietitians")
                .document(dietitianId)
                .collection("clients")
                .document(userId)
                .setData([
                    "cachedAnalysis": [:],
                    "connectedAt": FieldValue.serverTimestamp(),
                    "userId": userId
                ])
            
            // Update current user's document with expertId
            try await db.collection("users")
                .document(userId)
                .updateData(["expertId": dietitianId])
            
            print("[ExpertConnectionService] Successfully linked to expert \(dietitianId)")
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
        } catch {
            print("[ExpertConnectionService] Error linking to expert: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = self.handleConnectionError(error)
                self.showingError = true
            }
            
            throw error
        }
    }
    
    // MARK: - Leave Expert Service
    
    func leaveExpert() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw ExpertConnectionError.noCurrentUser
        }
        
        // Get current user's expertId
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(),
              let expertId = userData["expertId"] as? String else {
            throw ExpertConnectionError.noExpertLinked
        }
        
        print("[ExpertConnectionService] User \(userId) leaving expert \(expertId)")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Delete client document from dietitian's clients collection
            try await db.collection("dietitians")
                .document(expertId)
                .collection("clients")
                .document(userId)
                .delete()
            
            // Clear expertId from user's document
            try await db.collection("users")
                .document(userId)
                .updateData(["expertId": FieldValue.delete()])
            
            print("[ExpertConnectionService] Successfully left expert service")
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
        } catch {
            print("[ExpertConnectionService] Error leaving expert service: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = self.handleConnectionError(error)
                self.showingError = true
            }
            
            throw error
        }
    }
    
    // MARK: - Fetch Expert Info
    
    func fetchExpertInfo(expertId: String) async throws -> ExpertInfo {
        print("[ExpertConnectionService] Fetching expert info for \(expertId)")
        
        // Fetch from users collection instead of dietitians collection
        let expertDoc = try await db.collection("users").document(expertId).getDocument()
        
        guard expertDoc.exists,
              let data = expertDoc.data(),
              let role = data["role"] as? String,
              role == "dietitian" else {
            throw ExpertConnectionError.dietitianNotFound
        }
        
        let expertInfo = ExpertInfo(
            id: expertId,
            name: data["fullName"] as? String ?? "Expert",
            photoURL: data["photoURL"] as? String,
            email: data["email"] as? String ?? "",
            bio: data["bio"] as? String
        )
        
        print("[ExpertConnectionService] Successfully fetched expert info: \(expertInfo.name)")
        return expertInfo
    }
    
    // MARK: - Error Handling
    
    private func handleConnectionError(_ error: Error) -> String {
        if let connectionError = error as? ExpertConnectionError {
            return connectionError.localizedDescription
        }
        
        return "An unexpected error occurred: \(error.localizedDescription)"
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.showingError = false
        }
    }
}

// MARK: - Expert Info Model

struct ExpertInfo: Identifiable {
    let id: String
    let name: String
    let photoURL: String?
    let email: String
    let bio: String?
}

// MARK: - Custom Errors

enum ExpertConnectionError: LocalizedError {
    case noCurrentUser
    case dietitianNotFound
    case noExpertLinked
    case invalidQRCode
    case cameraPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No user is currently signed in."
        case .dietitianNotFound:
            return "The expert ID was not found or the user is not a dietitian. Please check the ID and try again."
        case .noExpertLinked:
            return "You are not currently linked to any expert."
        case .invalidQRCode:
            return "The QR code does not contain a valid expert ID."
        case .cameraPermissionDenied:
            return "Camera permission is required to scan QR codes. Please enable it in Settings."
        }
    }
}