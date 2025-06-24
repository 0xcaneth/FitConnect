import Foundation
import FirebaseFirestore

struct UserPreferences: Codable {
    var stepGoal: Int
    var calorieGoal: Int
    var waterGoal: Int
    var lastUpdated: Timestamp?
    
    static let `default` = UserPreferences(
        stepGoal: 10000,
        calorieGoal: 500,
        waterGoal: 2000
    )
    
    init(stepGoal: Int = 10000, calorieGoal: Int = 500, waterGoal: Int = 2000, lastUpdated: Timestamp? = nil) {
        self.stepGoal = stepGoal
        self.calorieGoal = calorieGoal
        self.waterGoal = waterGoal
        self.lastUpdated = lastUpdated
    }
}
