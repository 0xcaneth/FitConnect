import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class UserSettingsService: ObservableObject {
    @Published var userSettings: UserSettings = .default
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    static let shared = UserSettingsService()
    
    private init() {}
    
    func fetchSettings(for userId: String) async {
        isLoading = true
        
        do {
            let docRef = db.collection("users").document(userId).collection("settings").document("goals")
            let document = try await docRef.getDocument()
            
            if document.exists {
                userSettings = try document.data(as: UserSettings.self)
            } else {
                // Create default settings for new user
                try await saveSettings(userSettings, for: userId)
            }
        } catch {
            print("[UserSettingsService] Error fetching settings: \(error.localizedDescription)")
            userSettings = .default
        }
        
        isLoading = false
    }
    
    func saveSettings(_ settings: UserSettings, for userId: String) async throws {
        let docRef = db.collection("users").document(userId).collection("settings").document("goals")
        var updatedSettings = settings
        updatedSettings.lastUpdated = Timestamp(date: Date())
        try await docRef.setData(from: updatedSettings)
        userSettings = updatedSettings
    }
    
    func updateGoals(stepGoal: Int? = nil, caloriesGoal: Int? = nil, waterGoalML: Int? = nil, for userId: String) async {
        var updated = userSettings
        
        if let stepGoal = stepGoal { updated.dailyStepGoal = stepGoal }
        if let caloriesGoal = caloriesGoal { updated.dailyCaloriesGoal = caloriesGoal }
        if let waterGoalML = waterGoalML { updated.dailyWaterGoalML = waterGoalML }
        
        do {
            try await saveSettings(updated, for: userId)
        } catch {
            print("[UserSettingsService] Error updating goals: \(error.localizedDescription)")
        }
    }
}