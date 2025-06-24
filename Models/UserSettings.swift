import Foundation
import FirebaseFirestore

struct UserSettings: Codable {
    var dailyStepGoal: Int
    var dailyCaloriesGoal: Int
    var dailyWaterGoalML: Int
    var lastUpdated: Timestamp?
    
    static let `default` = UserSettings(
        dailyStepGoal: 10000,
        dailyCaloriesGoal: 500,
        dailyWaterGoalML: 2000
    )
    
    init(dailyStepGoal: Int = 10000, dailyCaloriesGoal: Int = 500, dailyWaterGoalML: Int = 2000, lastUpdated: Timestamp? = nil) {
        self.dailyStepGoal = dailyStepGoal
        self.dailyCaloriesGoal = dailyCaloriesGoal
        self.dailyWaterGoalML = dailyWaterGoalML
        self.lastUpdated = lastUpdated
    }
}
