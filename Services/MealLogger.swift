import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// MealLogger service handles CSV parsing, Firestore write operations, and console logging for meal data
/// What changed: New service combining CSV nutrition lookup with Firebase persistence and comprehensive logging
class MealLogger: ObservableObject {
    static let shared = MealLogger()
    
    private let db = Firestore.firestore()
    private let nutritionManager = NutritionDataManager.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private init() {
        print("MealLogger initialized")
    }
    
    // MARK: - Main Logging Function
    @MainActor
    func logMeal(
        foodName: String,
        portionIndex: Int,
        mealType: Meal.MealType,
        selectedDate: Date = Date(),
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "MealLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        // Get nutrition data from CSV
        guard let nutrition = getNutritionFromCSV(foodName: foodName, portionIndex: portionIndex) else {
            let error = NSError(domain: "MealLogger", code: 2, userInfo: [NSLocalizedDescriptionKey: "Nutrition data not found for \(foodName)"])
            completion(.failure(error))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Prepare meal data for Firestore
        let mealData = prepareMealData(
            foodName: foodName,
            nutrition: nutrition,
            mealType: mealType,
            portionIndex: portionIndex,
            selectedDate: selectedDate
        )
        
        // Save to Firestore
        saveMealToFirestore(userId: userId, mealData: mealData) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    // Console logging for successful save
                    let logMessage = "Logged meal: \(foodName), \(nutrition.weight)g → {calories: \(nutrition.calories), protein: \(nutrition.protein), fat: \(nutrition.fats), carbs: \(nutrition.carbohydrates)}"
                    print(" " + logMessage)
                    
                    self?.successMessage = "Meal logged successfully!"
                    completion(.success(()))
                    
                case .failure(let error):
                    print(" Error logging meal: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to log meal: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - CSV Nutrition Lookup
    @MainActor
    private func getNutritionFromCSV(foodName: String, portionIndex: Int) -> NutritionEntry? {
        // Search for food in nutrition manager
        let searchResults = nutritionManager.searchFoods(foodName)
        
        // Find exact or close match
        let matchedFood = searchResults.first { food in
            food.displayName.lowercased() == foodName.lowercased() ||
            food.label.lowercased() == foodName.lowercased() ||
            food.displayName.lowercased().contains(foodName.lowercased())
        }
        
        guard let food = matchedFood else {
            print(" No nutrition data found for: \(foodName)")
            print("Available foods: \(searchResults.prefix(5).map { $0.displayName }.joined(separator: ", "))")
            return nil
        }
        
        // Get nutrition for specific portion
        let nutrition = nutritionManager.getNutrition(for: food.label, portionIndex: portionIndex)
        
        if let nutrition = nutrition {
            print(" Found nutrition data for \(foodName): \(nutrition.calories) cal, \(nutrition.weight)g")
        } else {
            print(" Invalid portion index \(portionIndex) for \(foodName)")
        }
        
        return nutrition
    }
    
    // MARK: - Prepare Meal Data
    private func prepareMealData(
        foodName: String,
        nutrition: NutritionEntry,
        mealType: Meal.MealType,
        portionIndex: Int,
        selectedDate: Date
    ) -> [String: Any] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        return [
            "mealName": foodName,
            "foodLabel": nutrition.label,
            "mealType": mealType.rawValue,
            "portionIndex": portionIndex,
            "portionWeight": nutrition.weight,
            "calories": nutrition.calories,
            "protein": nutrition.protein,
            "fat": nutrition.fats,
            "carbs": nutrition.carbohydrates,
            "fiber": nutrition.fiber,
            "sugars": nutrition.sugars,
            "sodium": nutrition.sodium,
            "timestamp": Timestamp(date: selectedDate),
            "dateString": dateString,
            "loggedAt": Timestamp(date: Date())
        ]
    }
    
    // MARK: - Firestore Save Operation
    private func saveMealToFirestore(
        userId: String,
        mealData: [String: Any],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let dateString = mealData["dateString"] as? String ?? ""
        
        db.collection("users")
            .document(userId)
            .collection("healthData")
            .document(dateString)
            .collection("meals")
            .addDocument(data: mealData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Batch Logging (for multiple meals)
    @MainActor
    func logMultipleMeals(
        meals: [(foodName: String, portionIndex: Int, mealType: Meal.MealType, date: Date)],
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard let userId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "MealLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        let batch = db.batch()
        var successCount = 0
        
        for meal in meals {
            guard let nutrition = getNutritionFromCSV(foodName: meal.foodName, portionIndex: meal.portionIndex) else {
                continue
            }
            
            let mealData = prepareMealData(
                foodName: meal.foodName,
                nutrition: nutrition,
                mealType: meal.mealType,
                portionIndex: meal.portionIndex,
                selectedDate: meal.date
            )
            
            let dateString = mealData["dateString"] as? String ?? ""
            let docRef = db.collection("users")
                .document(userId)
                .collection("healthData")
                .document(dateString)
                .collection("meals")
                .document()
            
            batch.setData(mealData, forDocument: docRef)
            successCount += 1
        }
        
        if successCount == 0 {
            let error = NSError(domain: "MealLogger", code: 3, userInfo: [NSLocalizedDescriptionKey: "No valid meals to log"])
            completion(.failure(error))
            return
        }
        
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("✅ Batch logged \(successCount) meals")
                completion(.success(successCount))
            }
        }
    }
    
    // MARK: - Get Recent Meals
    func getRecentMeals(limit: Int = 10, completion: @escaping (Result<[Meal], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            let error = NSError(domain: "MealLogger", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            completion(.failure(error))
            return
        }
        
        db.collectionGroup("meals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let meals = snapshot?.documents.compactMap { doc -> Meal? in
                    return try? doc.data(as: Meal.self)
                } ?? []
                
                completion(.success(meals))
            }
    }
    
    // MARK: - Clear Messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

// MARK: - Extension for MealLogger
extension MealLogger {
    // Helper method to get available foods
    @MainActor
    func getAvailableFoods() -> [FoodItem] {
        return nutritionManager.foodItems
    }
    
    // Helper method to search foods
    @MainActor
    func searchFoods(_ query: String) -> [FoodItem] {
        return nutritionManager.searchFoods(query)
    }
    
    // Helper method to get nutrition for specific food and portion
    @MainActor
    func getNutrition(for foodLabel: String, portionIndex: Int) -> NutritionEntry? {
        return nutritionManager.getNutrition(for: foodLabel, portionIndex: portionIndex)
    }
}