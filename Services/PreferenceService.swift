import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class PreferenceService: ObservableObject {
    @Published var userPreferences: UserPreferences = .default
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    static let shared = PreferenceService()
    
    private init() {}
    
    func fetchPreferences(for userId: String) async {
        isLoading = true
        
        do {
            let docRef = db.collection("users").document(userId).collection("settings").document("preferences")
            let document = try await docRef.getDocument()
            
            if document.exists {
                userPreferences = try document.data(as: UserPreferences.self)
            } else {
                // Create default preferences for new user
                try await savePreferences(userPreferences, for: userId)
            }
        } catch {
            print("[PreferenceService] Error fetching preferences: \(error.localizedDescription)")
            userPreferences = .default
        }
        
        isLoading = false
    }
    
    func savePreferences(_ preferences: UserPreferences, for userId: String) async throws {
        let docRef = db.collection("users").document(userId).collection("settings").document("preferences")
        var updatedPreferences = preferences
        updatedPreferences.lastUpdated = Timestamp(date: Date())
        try await docRef.setData(from: updatedPreferences)
        userPreferences = updatedPreferences
    }
    
    func updateGoal(stepGoal: Int? = nil, calorieGoal: Int? = nil, waterGoal: Int? = nil, for userId: String) async {
        var updated = userPreferences
        
        if let stepGoal = stepGoal { updated.stepGoal = stepGoal }
        if let calorieGoal = calorieGoal { updated.calorieGoal = calorieGoal }
        if let waterGoal = waterGoal { updated.waterGoal = waterGoal }
        
        do {
            try await savePreferences(updated, for: userId)
        } catch {
            print("[PreferenceService] Error updating goals: \(error.localizedDescription)")
        }
    }
}