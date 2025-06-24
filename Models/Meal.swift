import Foundation
import FirebaseFirestore

struct Meal: Identifiable, Codable {
    @DocumentID var id: String?
    var mealName: String
    var mealType: MealType
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var timestamp: Date
    var imageURL: String?
    var userId: String
    var confidence: Double?
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
    
    init(mealName: String, mealType: MealType, calories: Int, protein: Double, fat: Double, carbs: Double, timestamp: Date = Date(), imageURL: String? = nil, userId: String, confidence: Double? = nil) {
        self.mealName = mealName
        self.mealType = mealType
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.timestamp = timestamp
        self.imageURL = imageURL
        self.userId = userId
        self.confidence = confidence
    }
}

struct MealAnalysis: Codable {
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double 
    let sugars: Double 
    let sodium: Double 
    let confidence: Double
    
    init(calories: Int, protein: Double, fat: Double, carbs: Double, fiber: Double = 0.0, sugars: Double = 0.0, sodium: Double = 0.0, confidence: Double = 0.8) {
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.sugars = sugars
        self.sodium = sodium
        self.confidence = confidence
    }
}