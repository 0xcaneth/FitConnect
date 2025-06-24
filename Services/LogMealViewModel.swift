import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class LogMealViewModel: ObservableObject {
    @Published var mealName: String = ""
    @Published var selectedMealType: Meal.MealType = .breakfast
    @Published var calories: String = ""
    @Published var protein: String = ""
    @Published var fat: String = ""
    @Published var carbs: String = ""
    @Published var mealDate: Date = Date()
    @Published var mealTime: Date = Date()
    @Published var isSaving: Bool = false
    @Published var showSuccess: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showDatePicker: Bool = false
    @Published var showTimePicker: Bool = false
    @Published var focusedField: FocusedField? = nil
    @Published var showSaveAnimation: Bool = false
    
    enum FocusedField {
        case mealName, calories, protein, fat, carbs
    }
    
    private let mealService = MealService.shared
    
    var isFormValid: Bool {
        !mealName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Int(calories) ?? 0) > 0 &&
        !calories.isEmpty
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: mealDate)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: mealTime)
    }
    
    var macroValidationMessage: String {
        guard let caloriesInt = Int(calories),
              let proteinDouble = Double(protein),
              let fatDouble = Double(fat),
              let carbsDouble = Double(carbs) else {
            return ""
        }
        
        let macroCalories = Int(proteinDouble * 4 + fatDouble * 9 + carbsDouble * 4)
        if macroCalories > caloriesInt + 50 {
            return "Macro calories (\(macroCalories)) exceed total calories"
        }
        return ""
    }
    
    func saveMeal() async {
        guard isFormValid else { return }
        
        isSaving = true
        
        do {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw NSError(domain: "LogMeal", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            // Combine date and time
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: mealDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: mealTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            let finalDate = calendar.date(from: combinedComponents) ?? Date()
            
            let nutrition = NutritionData(
                calories: Int(calories) ?? 0,
                protein: Double(protein) ?? 0,
                fat: Double(fat) ?? 0,
                carbs: Double(carbs) ?? 0,
                fiber: 0.0,
                sugars: 0.0,
                sodium: 0.0
            )
            
            let mealEntry = MealEntry(
                mealName: mealName.trimmingCharacters(in: .whitespaces),
                mealType: selectedMealType.rawValue,
                nutrition: nutrition,
                timestamp: finalDate,
                userId: userId
            )
            
            try await mealService.saveMealEntry(mealEntry)
            
            // Show success animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showSaveAnimation = true
            }
            
            // Success feedback
            let impactFeedback = UINotificationFeedbackGenerator()
            impactFeedback.notificationOccurred(.success)
            
            // Delay then show success
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.showSuccess = true
            }
            
        } catch {
            print("Failed to save meal: \(error.localizedDescription)")
            errorMessage = "Failed to save meal. Please try again."
            showError = true
            
            let impactFeedback = UINotificationFeedbackGenerator()
            impactFeedback.notificationOccurred(.error)
        }
        
        isSaving = false
    }
    
    func resetForm() {
        mealName = ""
        selectedMealType = .breakfast
        calories = ""
        protein = ""
        fat = ""
        carbs = ""
        mealDate = Date()
        mealTime = Date()
        errorMessage = ""
        focusedField = nil
    }
}