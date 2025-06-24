import Foundation

struct FoodNutritionDatabase {
    private static let nutritionData: [String: NutritionInfo] = [
        // Fruits
        "apple": NutritionInfo(calories: 95, protein: 0.5, fat: 0.3, carbs: 25.0, fiber: 4.0, sugar: 19.0),
        "banana": NutritionInfo(calories: 105, protein: 1.3, fat: 0.4, carbs: 27.0, fiber: 3.1, sugar: 14.0),
        "orange": NutritionInfo(calories: 62, protein: 1.2, fat: 0.2, carbs: 15.4, fiber: 3.1, sugar: 12.2),
        "strawberry": NutritionInfo(calories: 32, protein: 0.7, fat: 0.3, carbs: 7.7, fiber: 2.0, sugar: 4.9),
        "grapes": NutritionInfo(calories: 62, protein: 0.6, fat: 0.4, carbs: 16.0, fiber: 0.9, sugar: 15.0),
        
        // Vegetables
        "broccoli": NutritionInfo(calories: 34, protein: 2.8, fat: 0.4, carbs: 7.0, fiber: 2.6, sugar: 1.5),
        "carrot": NutritionInfo(calories: 25, protein: 0.5, fat: 0.1, carbs: 6.0, fiber: 1.7, sugar: 2.9),
        "spinach": NutritionInfo(calories: 7, protein: 0.9, fat: 0.1, carbs: 1.1, fiber: 0.7, sugar: 0.1),
        "tomato": NutritionInfo(calories: 18, protein: 0.9, fat: 0.2, carbs: 3.9, fiber: 1.2, sugar: 2.6),
        "cucumber": NutritionInfo(calories: 8, protein: 0.3, fat: 0.1, carbs: 2.0, fiber: 0.5, sugar: 0.9),
        
        // Proteins
        "chicken breast": NutritionInfo(calories: 165, protein: 31.0, fat: 3.6, carbs: 0.0, fiber: 0.0, sugar: 0.0),
        "salmon": NutritionInfo(calories: 208, protein: 22.0, fat: 12.0, carbs: 0.0, fiber: 0.0, sugar: 0.0),
        "egg": NutritionInfo(calories: 68, protein: 6.0, fat: 4.8, carbs: 0.4, fiber: 0.0, sugar: 0.2),
        "tofu": NutritionInfo(calories: 76, protein: 8.0, fat: 4.8, carbs: 1.9, fiber: 0.3, sugar: 0.9),
        "ground beef": NutritionInfo(calories: 250, protein: 26.0, fat: 15.0, carbs: 0.0, fiber: 0.0, sugar: 0.0),
        
        // Grains & Starches
        "white rice": NutritionInfo(calories: 130, protein: 2.7, fat: 0.3, carbs: 28.0, fiber: 0.4, sugar: 0.1),
        "brown rice": NutritionInfo(calories: 112, protein: 2.3, fat: 0.9, carbs: 23.0, fiber: 1.8, sugar: 0.2),
        "pasta": NutritionInfo(calories: 131, protein: 5.0, fat: 1.1, carbs: 25.0, fiber: 1.8, sugar: 0.8),
        "bread": NutritionInfo(calories: 79, protein: 2.3, fat: 1.0, carbs: 14.0, fiber: 1.2, sugar: 1.4),
        "potato": NutritionInfo(calories: 77, protein: 2.0, fat: 0.1, carbs: 17.0, fiber: 2.2, sugar: 0.8),
        
        // Fast Food & Prepared
        "pizza": NutritionInfo(calories: 285, protein: 12.0, fat: 10.0, carbs: 36.0, fiber: 2.5, sugar: 3.8),
        "burger": NutritionInfo(calories: 540, protein: 25.0, fat: 31.0, carbs: 40.0, fiber: 3.0, sugar: 5.0),
        "sandwich": NutritionInfo(calories: 195, protein: 6.0, fat: 11.0, carbs: 20.0, fiber: 2.0, sugar: 3.0),
        "salad": NutritionInfo(calories: 180, protein: 8.0, fat: 16.0, carbs: 5.0, fiber: 3.0, sugar: 2.0),
        "soup": NutritionInfo(calories: 120, protein: 6.0, fat: 4.0, carbs: 15.0, fiber: 2.0, sugar: 3.0),
        
        // Snacks & Desserts
        "cookie": NutritionInfo(calories: 49, protein: 0.6, fat: 2.3, carbs: 6.8, fiber: 0.2, sugar: 3.9),
        "chocolate": NutritionInfo(calories: 155, protein: 2.2, fat: 8.8, carbs: 17.0, fiber: 1.9, sugar: 14.0),
        "chips": NutritionInfo(calories: 152, protein: 2.0, fat: 10.0, carbs: 15.0, fiber: 1.4, sugar: 0.2),
        "yogurt": NutritionInfo(calories: 59, protein: 10.0, fat: 0.4, carbs: 3.6, fiber: 0.0, sugar: 3.2),
        "nuts": NutritionInfo(calories: 607, protein: 20.0, fat: 54.0, carbs: 16.0, fiber: 8.0, sugar: 4.0)
    ]
    
    static func getNutritionInfo(for foodLabel: String) -> NutritionInfo {
        let cleanLabel = foodLabel.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try exact match first
        if let nutrition = nutritionData[cleanLabel] {
            return nutrition
        }
        
        // Try partial matches
        for (key, nutrition) in nutritionData {
            if cleanLabel.contains(key) || key.contains(cleanLabel) {
                return nutrition
            }
        }
        
        // Return default nutrition if no match found
        return NutritionInfo(calories: 200, protein: 8.0, fat: 6.0, carbs: 25.0, fiber: 2.0, sugar: 3.0)
    }
    
    static func searchFoods(containing query: String) -> [String] {
        let cleanQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return nutritionData.keys.filter { $0.contains(cleanQuery) }.sorted()
    }
}

struct NutritionInfo {
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double
    let sugar: Double
    
    var mealAnalysis: MealAnalysis {
        MealAnalysis(
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            confidence: 0.85
        )
    }
}