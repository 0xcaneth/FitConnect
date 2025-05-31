import Foundation
import FirebaseFirestore

struct Meal: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var type: MealType
    var foods: [Food]
    var totalCalories: Int
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var imageURL: String?
    var createdAt: Date
    
    enum MealType: String, Codable, CaseIterable {
        case breakfast = "breakfast"
        case lunch = "lunch"
        case dinner = "dinner"
        case snack = "snack"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "sunset.fill"
            case .snack: return "leaf.fill"
            }
        }
    }
}

struct Food: Identifiable, Codable {
    var id = UUID()
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var quantity: Double
    var unit: String
}