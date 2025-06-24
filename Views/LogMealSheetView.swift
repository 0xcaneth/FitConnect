import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct LogMealSheetView: View {
    let detectedFood: String
    let estimatedCalories: Int
    let analysis: MealAnalysis?
    let onDismiss: () -> Void
    let onSave: () -> Void
    
    @State private var selectedMealType: Meal.MealType
    @State private var selectedPortionSize: PortionSize = .medium
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let mealService = MealService.shared
    
    enum PortionSize: String, CaseIterable {
        case small = "Small"
        case medium = "Medium" 
        case large = "Large"
        case extraLarge = "Extra Large"
        
        var multiplier: Double {
            switch self {
            case .small: return 0.7
            case .medium: return 1.0
            case .large: return 1.3
            case .extraLarge: return 1.6
            }
        }
        
        var icon: String {
            switch self {
            case .small: return "circle.fill"
            case .medium: return "circle.fill"
            case .large: return "circle.fill"
            case .extraLarge: return "circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .small: return "70% of standard portion"
            case .medium: return "Standard portion size"
            case .large: return "130% of standard portion"
            case .extraLarge: return "160% of standard portion"
            }
        }
    }
    
    // Auto-detect meal type based on current time
    private var autoDetectedMealType: Meal.MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: return .breakfast
        case 11..<16: return .lunch
        case 16..<22: return .dinner
        default: return .snack
        }
    }
    
    // Calculate adjusted nutrition based on portion size
    private var adjustedNutrition: NutritionData {
        guard let analysis = analysis else {
            return NutritionData(
                calories: Int(Double(estimatedCalories) * selectedPortionSize.multiplier),
                protein: 0,
                fat: 0,
                carbs: 0
            )
        }
        
        let multiplier = selectedPortionSize.multiplier
        return NutritionData(
            calories: Int(Double(analysis.calories) * multiplier),
            protein: analysis.protein * multiplier,
            fat: analysis.fat * multiplier,
            carbs: analysis.carbs * multiplier,
            fiber: analysis.fiber * multiplier,
            sugars: analysis.sugars * multiplier,
            sodium: analysis.sodium * multiplier
        )
    }
    
    init(detectedFood: String, estimatedCalories: Int, analysis: MealAnalysis? = nil, onDismiss: @escaping () -> Void, onSave: @escaping () -> Void = {}) {
        self.detectedFood = detectedFood
        self.estimatedCalories = estimatedCalories
        self.analysis = analysis
        self.onDismiss = onDismiss
        self.onSave = onSave
        
        // Auto-select meal type based on current time
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: 
            self._selectedMealType = State(initialValue: .breakfast)
        case 11..<16: 
            self._selectedMealType = State(initialValue: .lunch)
        case 16..<22: 
            self._selectedMealType = State(initialValue: .dinner)
        default: 
            self._selectedMealType = State(initialValue: .snack)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.Colors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with detected food
                        headerView
                        
                        // Meal type selection
                        mealTypeSection
                        
                        // Portion size selection
                        portionSizeSection
                        
                        // Nutrition preview
                        nutritionPreviewSection
                        
                        // Save button
                        saveButtonSection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Success overlay
                if showSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(Constants.Colors.textSecondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Food emoji/icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "3CD76B"), Color(hex: "26C6DA")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(getFoodEmoji(for: detectedFood))
                    .font(.system(size: 40))
            }
            
            VStack(spacing: 4) {
                Text(detectedFood.isEmpty ? "Detected Meal" : detectedFood)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Ready to log this meal to your diary")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Meal Type Section
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal Type")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Auto-detected")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "3CD76B"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: "3CD76B").opacity(0.2))
                    )
            }
            
            HStack(spacing: 8) {
                ForEach(Meal.MealType.allCases, id: \.self) { mealType in
                    Button {
                        selectedMealType = mealType
                    } label: {
                        Text(mealType.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedMealType == mealType ? .white : .gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedMealType == mealType ?
                                        LinearGradient(
                                            colors: [Color(hex: "3CD76B"), Color(hex: "26C6DA")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.clear, Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    // MARK: - Portion Size Section
    private var portionSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portion Size")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(PortionSize.allCases, id: \.self) { size in
                    Button {
                        selectedPortionSize = size
                    } label: {
                        HStack(spacing: 16) {
                            // Size indicator circles
                            HStack(spacing: 4) {
                                ForEach(0..<4) { index in
                                    Circle()
                                        .fill(index < getCircleCount(for: size) ? Color(hex: "3CD76B") : Color.gray.opacity(0.3))
                                        .frame(width: getCircleSize(for: size, index: index), height: getCircleSize(for: size, index: index))
                                }
                            }
                            .frame(width: 60, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(size.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(size.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(adjustedNutrition.calories)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(hex: "3CD76B"))
                                
                                Text("kcal")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            // Selection indicator
                            Circle()
                                .fill(selectedPortionSize == size ? Color(hex: "3CD76B") : Color.clear)
                                .overlay(
                                    Circle()
                                        .stroke(.gray.opacity(0.3), lineWidth: 2)
                                )
                                .frame(width: 20, height: 20)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPortionSize == size ? Constants.Colors.cardBackground : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedPortionSize == size ? 
                                            Color(hex: "3CD76B").opacity(0.5) : 
                                            Color.gray.opacity(0.2), 
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    // MARK: - Nutrition Preview Section
    private var nutritionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            
            LazyVGrid(columns: columns, spacing: 12) {
                NutritionPreviewCard(
                    icon: "flame.fill",
                    label: "Calories",
                    value: "\(adjustedNutrition.calories)",
                    unit: "kcal",
                    color: Color(hex: "FF8E3C")
                )
                
                NutritionPreviewCard(
                    icon: "bolt.fill",
                    label: "Protein",
                    value: String(format: "%.1f", adjustedNutrition.protein),
                    unit: "g",
                    color: Color(hex: "3CD76B")
                )
                
                NutritionPreviewCard(
                    icon: "drop.fill",
                    label: "Fat",
                    value: String(format: "%.1f", adjustedNutrition.fat),
                    unit: "g",
                    color: Color(hex: "FFD700")
                )
                
                NutritionPreviewCard(
                    icon: "leaf.arrow.triangle.circlepath",
                    label: "Carbs",
                    value: String(format: "%.1f", adjustedNutrition.carbs),
                    unit: "g",
                    color: Color(hex: "3C9CFF")
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        Button {
            saveMeal()
        } label: {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isSaving ? "Saving..." : "Log Meal")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "3CD76B"), Color(hex: "26C6DA")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color(hex: "3CD76B").opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.8 : 1.0)
    }
    
    // MARK: - Success Overlay
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3CD76B"))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Meal Logged!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Successfully added to your food diary")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Constants.Colors.cardBackground)
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }
    
    // MARK: - Helper Methods
    private func saveMeal() {
        isSaving = true
        
        Task {
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "LogMealSheet", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                let mealEntry = MealEntry(
                    mealName: detectedFood.isEmpty ? "Scanned Meal" : detectedFood,
                    mealType: selectedMealType.rawValue,
                    nutrition: adjustedNutrition,
                    timestamp: Date(),
                    userId: userId
                )
                
                try await mealService.saveMealEntry(mealEntry)
                
                await MainActor.run {
                    isSaving = false
                    
                    // Show success animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSuccess = true
                    }
                    
                    // Success feedback
                    let impactFeedback = UINotificationFeedbackGenerator()
                    impactFeedback.notificationOccurred(.success)
                    
                    // Dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onSave()
                        onDismiss()
                    }
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to save meal. Please try again."
                    showError = true
                    
                    let impactFeedback = UINotificationFeedbackGenerator()
                    impactFeedback.notificationOccurred(.error)
                }
            }
        }
    }
    
    private func getFoodEmoji(for foodName: String) -> String {
        let name = foodName.lowercased()
        
        if name.contains("pizza") { return "🍕" }
        if name.contains("burger") { return "🍔" }
        if name.contains("sandwich") { return "🥪" }
        if name.contains("salad") { return "🥗" }
        if name.contains("pasta") { return "🍝" }
        if name.contains("rice") { return "🍚" }
        if name.contains("chicken") { return "🍗" }
        if name.contains("fish") { return "🐟" }
        if name.contains("apple") { return "🍎" }
        if name.contains("banana") { return "🍌" }
        if name.contains("egg") { return "🥚" }
        if name.contains("bread") { return "🍞" }
        if name.contains("soup") { return "🍲" }
        if name.contains("cake") { return "🍰" }
        
        return "🍽️"
    }
    
    private func getCircleCount(for size: PortionSize) -> Int {
        switch size {
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        case .extraLarge: return 4
        }
    }
    
    private func getCircleSize(for size: PortionSize, index: Int) -> CGFloat {
        switch size {
        case .small: return index == 0 ? 8 : 6
        case .medium: return index < 2 ? 8 : 6
        case .large: return index < 3 ? 8 : 6
        case .extraLarge: return 8
        }
    }
}

// MARK: - Nutrition Preview Card
struct NutritionPreviewCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct LogMealSheetView_Previews: PreviewProvider {
    static var previews: some View {
        LogMealSheetView(
            detectedFood: "Pizza",
            estimatedCalories: 450,
            analysis: MealAnalysis(calories: 450, protein: 25.0, fat: 15.0, carbs: 55.0, fiber: 5.0, sugars: 8.0, sodium: 800, confidence: 0.87),
            onDismiss: { }
        )
        .preferredColorScheme(.dark)
    }
}
#endif