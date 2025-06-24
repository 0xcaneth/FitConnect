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
    
    // Custom coding keys to handle both data formats
    enum CodingKeys: String, CodingKey {
        case id, mealName, foodLabel, mealType, portionIndex, portionWeight
        case nutrition, timestamp, dateString, userId, imageURL, confidence
        case calories, protein, fat, carbs, fiber, sugars, sodium
    }
    
    // Custom decoder to handle both nested and flat nutrition data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode basic fields
        mealName = try container.decode(String.self, forKey: .mealName)
        foodLabel = try container.decodeIfPresent(String.self, forKey: .foodLabel)
        mealType = try container.decode(String.self, forKey: .mealType)
        portionIndex = try container.decodeIfPresent(Int.self, forKey: .portionIndex)
        portionWeight = try container.decodeIfPresent(Double.self, forKey: .portionWeight)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        dateString = try container.decode(String.self, forKey: .dateString)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        confidence = try container.decodeIfPresent(Double.self, forKey: .confidence)
        
        // Try to decode nutrition data - first check if nested structure exists
        if let nestedNutrition = try? container.decode(NutritionData.self, forKey: .nutrition) {
            // LogMeal format - nested nutrition
            nutrition = nestedNutrition
        } else {
            // ScanMeal format - flat nutrition fields
            let calories = try container.decode(Int.self, forKey: .calories)
            let protein = try container.decode(Double.self, forKey: .protein)
            let fat = try container.decode(Double.self, forKey: .fat)
            let carbs = try container.decode(Double.self, forKey: .carbs)
            let fiber = try container.decodeIfPresent(Double.self, forKey: .fiber) ?? 0.0
            let sugars = try container.decodeIfPresent(Double.self, forKey: .sugars) ?? 0.0
            let sodium = try container.decodeIfPresent(Double.self, forKey: .sodium) ?? 0.0
            
            nutrition = NutritionData(
                calories: calories,
                protein: protein,
                fat: fat,
                carbs: carbs,
                fiber: fiber,
                sugars: sugars,
                sodium: sodium
            )
        }
    }
    
    // Custom encoder to always save in the new nested format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mealName, forKey: .mealName)
        try container.encodeIfPresent(foodLabel, forKey: .foodLabel)
        try container.encode(mealType, forKey: .mealType)
        try container.encodeIfPresent(portionIndex, forKey: .portionIndex)
        try container.encodeIfPresent(portionWeight, forKey: .portionWeight)
        try container.encode(nutrition, forKey: .nutrition)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(dateString, forKey: .dateString)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(confidence, forKey: .confidence)
    }
    
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