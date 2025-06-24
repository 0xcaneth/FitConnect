import SwiftUI

@available(iOS 16.0, *)
struct LogMealView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @StateObject private var nutritionManager = NutritionDataManager.shared
    
    @State private var selectedFood: FoodItem?
    @State private var searchText: String = ""
    @State private var showingFoodPicker = false
    @State private var selectedPortionIndex: Int = 2 // Default to middle portion (index 2)
    
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    
    enum MealType: String, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
    
    private var currentNutrition: NutritionEntry? {
        guard let food = selectedFood else { return nil }
        return nutritionManager.getNutrition(for: food.label, portionIndex: selectedPortionIndex)
    }
    
    private var canSave: Bool {
        selectedFood != nil && currentNutrition != nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        foodSelectionSection
                        
                        if selectedFood != nil {
                            portionSizeSection
                        }
                        
                        // Meal Type Selection
                        mealTypeSection
                        
                        if let nutrition = currentNutrition {
                            nutritionDisplaySection(nutrition: nutrition)
                        }
                        
                        // Date Selection
                        dateSelectionSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                
                // Toast notification
                if showingToast {
                    VStack {
                        Spacer()
                        
                        Text(toastMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "3CD76B"))
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Log Meal")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMeal()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(canSave ? Color(hex: "3CD76B") : .gray)
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(WheelDatePickerStyle())
                        .background(Color.backgroundDark)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingDatePicker = false
                                }
                                .foregroundColor(Color(hex: "3CD76B"))
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showingFoodPicker) {
                foodPickerSheet
            }
        }
    }
    
    // MARK: - Food Selection Section
    private var foodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Food")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Button {
                showingFoodPicker = true
            } label: {
                HStack {
                    if let selectedFood = selectedFood {
                        Text(selectedFood.displayName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    } else {
                        Text("Choose a food item")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Food Picker Sheet
    private var foodPickerSheet: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search foods...", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Food list
                List {
                    ForEach(nutritionManager.searchFoods(searchText)) { food in
                        Button {
                            selectedFood = food
                            selectedPortionIndex = min(2, food.portions.count - 1) // Default to middle or last available
                            showingFoodPicker = false
                            print("[LogMealView] Selected food: \(food.displayName)")
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Text("\(food.portions.count) portion sizes available")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                if selectedFood?.id == food.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color(hex: "3CD76B"))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.backgroundDark)
            }
            .background(Color.backgroundDark)
            .navigationTitle("Choose Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingFoodPicker = false
                    }
                    .foregroundColor(Color(hex: "FF5C9C"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Portion Size Section
    private var portionSizeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portion Size")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let food = selectedFood {
                    Text("Size \(selectedPortionIndex + 1)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "8F3FFF"))
                }
            }
            
            if let food = selectedFood {
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Double(selectedPortionIndex) },
                            set: { newValue in
                                selectedPortionIndex = Int(newValue.rounded())
                                print("[LogMealView] Portion changed to index: \(selectedPortionIndex)")
                            }
                        ),
                        in: 0...Double(food.portions.count - 1),
                        step: 1
                    )
                    .accentColor(Color(hex: "8F3FFF"))
                    
                    HStack {
                        Text("Small")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if let nutrition = currentNutrition {
                            Text("\(nutrition.weight)g")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Large")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Meal Type Section
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal Type")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                ForEach(MealType.allCases, id: \.self) { mealType in
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
                                            colors: [Color(hex: "FF5C9C"), Color(hex: "8F3FFF")],
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
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Nutrition Display Section
    private func nutritionDisplaySection(nutrition: NutritionEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    nutritionDisplayField(
                        title: "Calories",
                        value: "\(nutrition.calories)",
                        unit: "kcal",
                        icon: "flame.fill",
                        iconColor: Color(hex: "FF8E3C")
                    )
                    
                    nutritionDisplayField(
                        title: "Protein",
                        value: String(format: "%.1f", nutrition.protein),
                        unit: "g",
                        icon: "p.circle.fill",
                        iconColor: Color(hex: "3CD76B")
                    )
                }
                
                HStack(spacing: 12) {
                    nutritionDisplayField(
                        title: "Fats",
                        value: String(format: "%.1f", nutrition.fats),
                        unit: "g",
                        icon: "f.circle.fill",
                        iconColor: Color(hex: "FFD700")
                    )
                    
                    nutritionDisplayField(
                        title: "Carbs",
                        value: String(format: "%.1f", nutrition.carbohydrates),
                        unit: "g",
                        icon: "c.circle.fill",
                        iconColor: Color(hex: "3C9CFF")
                    )
                }
                
                HStack(spacing: 12) {
                    nutritionDisplayField(
                        title: "Fiber",
                        value: String(format: "%.1f", nutrition.fiber),
                        unit: "g",
                        icon: "leaf.fill",
                        iconColor: Color(hex: "4CAF50")
                    )
                    
                    nutritionDisplayField(
                        title: "Sugars",
                        value: String(format: "%.1f", nutrition.sugars),
                        unit: "g",
                        icon: "s.circle.fill",
                        iconColor: Color(hex: "E91E63")
                    )
                }
                
                nutritionDisplayField(
                    title: "Sodium",
                    value: String(format: "%.0f", nutrition.sodium),
                    unit: "mg",
                    icon: "n.circle.fill",
                    iconColor: Color(hex: "9C27B0")
                )
            }
        }
    }
    
    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When Did You Eat This?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Button {
                showingDatePicker = true
            } label: {
                HStack {
                    Text(formatDate(selectedDate))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color(hex: "1E1E1E"))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Views
    private func nutritionDisplayField(title: String, value: String, unit: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(12)
            .background(Color(hex: "1E1E1E"))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if NSCalendar.current.isDateInToday(date) {
            return "Recently"
        } else if NSCalendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func saveMeal() {
        guard let userId = session.currentUserId,
              let food = selectedFood,
              let nutrition = currentNutrition else {
            print("[LogMealView] Cannot save meal - missing required data")
            return
        }
        
        print("[LogMealView] Saving meal: \(food.displayName), Portion: \(selectedPortionIndex + 1), Calories: \(nutrition.calories)")
        
        let nutritionData = NutritionData(
            calories: nutrition.calories,
            protein: nutrition.protein,
            fat: nutrition.fats,
            carbs: nutrition.carbohydrates,
            fiber: nutrition.fiber,
            sugars: nutrition.sugars,
            sodium: nutrition.sodium
        )
        
        let mealEntry = MealEntry(
            mealName: food.displayName,
            foodLabel: food.label,
            mealType: selectedMealType.rawValue,
            portionIndex: selectedPortionIndex,
            portionWeight: Double(nutrition.weight),
            nutrition: nutritionData,
            timestamp: selectedDate,
            userId: userId
        )
        
        Task {
            do {
                try await MealService.shared.saveMealEntry(mealEntry)
                DispatchQueue.main.async {
                    print("[LogMealView] Meal saved successfully")
                    self.showToast("Meal logged successfully")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("[LogMealView] Error saving meal: \(error)")
                    self.showToast("Error saving meal")
                }
            }
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation(.easeInOut(duration: 0.3)) {
            showingToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingToast = false
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct LogMealView_Previews: PreviewProvider {
    static var previews: some View {
        LogMealView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "client"))
            .preferredColorScheme(.dark)
    }
}
#endif