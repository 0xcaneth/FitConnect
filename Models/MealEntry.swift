import Foundation
import FirebaseFirestore

struct MealEntry: Identifiable, Codable {
    @DocumentID var id: String?
    var mealName: String
    var foodLabel: String?
    var mealType: String
    var portionIndex: Int?
    var portionWeight: Double?
    var nutrition: NutritionData
    var timestamp: Date
    var dateString: String
    var userId: String?
    var imageURL: String?
    var confidence: Double?
    
    // Computed properties for display
    var displayText: String {
        return mealName
    }
    
    var foodEmoji: String {
        // Simple mapping of food types to emojis
        let name = mealName.lowercased()
        
        if name.contains("apple") { return "🍎" }
        if name.contains("banana") { return "🍌" }
        if name.contains("bread") || name.contains("sandwich") { return "🥪" }
        if name.contains("chicken") || name.contains("meat") { return "🍗" }
        if name.contains("fish") || name.contains("salmon") { return "🐟" }
        if name.contains("salad") || name.contains("lettuce") { return "🥗" }
        if name.contains("pizza") { return "🍕" }
        if name.contains("burger") { return "🍔" }
        if name.contains("rice") { return "🍚" }
        if name.contains("pasta") { return "🍝" }
        if name.contains("egg") { return "🥚" }
        if name.contains("milk") || name.contains("yogurt") { return "🥛" }
        if name.contains("cheese") { return "🧀" }
        if name.contains("fruit") || name.contains("berry") { return "🍓" }
        if name.contains("vegetable") || name.contains("carrot") { return "🥕" }
        if name.contains("soup") { return "🍲" }
        if name.contains("cake") || name.contains("dessert") { return "🍰" }
        if name.contains("cookie") { return "🍪" }
        
        // Default emoji based on meal type
        switch mealType.lowercased() {
        case "breakfast":
            return "🥞"
        case "lunch":
            return "🍽️"
        case "dinner":
            return "🍽️"
        case "snack":
            return "🍿"
        default:
            return "🍽️"
        }
    }
    
    var shortTimeString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: timestamp)
        }
    }
    
    init(mealName: String, foodLabel: String? = nil, mealType: String, portionIndex: Int? = nil, portionWeight: Double? = nil, nutrition: NutritionData, timestamp: Date = Date(), userId: String? = nil, imageURL: String? = nil, confidence: Double? = nil) {
        self.mealName = mealName
        self.foodLabel = foodLabel
        self.mealType = mealType
        self.portionIndex = portionIndex
        self.portionWeight = portionWeight
        self.nutrition = nutrition
        self.timestamp = timestamp
        self.userId = userId
        self.imageURL = imageURL
        self.confidence = confidence
        
        // Generate dateString
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.dateString = dateFormatter.string(from: timestamp)
    }
}

struct NutritionData: Codable {
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var fiber: Double
    var sugars: Double
    var sodium: Double
    
    init(calories: Int, protein: Double, fat: Double, carbs: Double, fiber: Double = 0.0, sugars: Double = 0.0, sodium: Double = 0.0) {
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.sugars = sugars
        self.sodium = sodium
    }
    
    // Convenience initializer from MealAnalysis
    init(from analysis: MealAnalysis) {
        self.calories = analysis.calories
        self.protein = analysis.protein
        self.fat = analysis.fat
        self.carbs = analysis.carbs
        self.fiber = analysis.fiber
        self.sugars = analysis.sugars
        self.sodium = analysis.sodium
    }
}