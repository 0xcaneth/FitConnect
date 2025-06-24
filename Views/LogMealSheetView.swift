import SwiftUI
import FirebaseFirestore
///can
/// Modern pull-up sheet for logging meals with enhanced UX, CSV-based nutrition lookup, and improved data flow
/// What changed: Complete redesign with pull-up sheet UI, portion slider, nutrition card display, and CSV integration
@available(iOS 16.0, *)
struct LogMealSheetView: View {
    let detectedFood: String
    let estimatedCalories: Int
    let onDismiss: () -> Void
    
    @EnvironmentObject var session: SessionStore
    @StateObject private var nutritionManager = NutritionDataManager.shared
    
    // MARK: - State Properties
    @State private var selectedFood: FoodItem?
    @State private var searchText: String = ""
    @State private var portionSlider: Double = 2.0 // Default to middle portion (Size 3 of 5)
    @State private var selectedMealType: Meal.MealType = .breakfast
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    @State private var showingFoodPicker = false
    @State private var showingSuccessToast = false
    @State private var isLoading = false
    
    // MARK: - Computed Properties
    private var currentPortionIndex: Int {
        Int(portionSlider.rounded())
    }
    
    private var currentNutrition: NutritionEntry? {
        guard let food = selectedFood else { return nil }
        return nutritionManager.getNutrition(for: food.label, portionIndex: currentPortionIndex)
    }
    
    private var canSave: Bool {
        selectedFood != nil && currentNutrition != nil
    }
    
    private var portionText: String {
        guard let food = selectedFood, currentPortionIndex < food.portions.count else {
            return "Size 1 of 5"
        }
        return "Size \(currentPortionIndex + 1) of \(food.portions.count)"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Grabber bar
                    grabberBar
                    
                    // Content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Header
                            headerSection
                            
                            // Food selection
                            foodSelectionSection
                            
                            // Portion slider (shown when food is selected)
                            if selectedFood != nil {
                                portionSliderSection
                            }
                            
                            // Meal type selection
                            mealTypeSection
                            
                            // Nutrition information cards
                            if let nutrition = currentNutrition {
                                nutritionInfoSection(nutrition)
                            }
                            
                            // Date selection
                            dateSelectionSection
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Bottom save button
                    bottomActionSection
                }
                
                // Success toast
                if showingSuccessToast {
                    successToastView
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingFoodPicker) {
            foodPickerSheet
        }
        .sheet(isPresented: $showingDatePicker) {
            datePickerSheet
        }
    }
    
    // MARK: - Grabber Bar
    private var grabberBar: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 6)
            .padding(.top, 8)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            
            Spacer()
            
            Text("Log Meal")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
    }
    
    // MARK: - Food Selection Section
    private var foodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Food")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Button {
                showingFoodPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    if let selectedFood = selectedFood {
                        Text(selectedFood.displayName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitConnectColors.textPrimary)
                    } else {
                        Text("Search for food...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitConnectColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FitConnectColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Portion Slider Section
    private var portionSliderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Portion Size")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Spacer()
                
                Text(portionText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitConnectColors.accentPurple)
            }
            
            if let food = selectedFood {
                VStack(spacing: 16) {
                    // Custom slider
                    SliderView(
                        value: $portionSlider,
                        range: 0...Double(food.portions.count - 1),
                        step: 1.0,
                        accentColor: FitConnectColors.accentPurple
                    )
                    
                    // Weight and calorie display
                    HStack {
                        Text("100g")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FitConnectColors.textSecondary)
                        
                        Spacer()
                        
                        if let nutrition = currentNutrition {
                            VStack(spacing: 2) {
                                Text("\(nutrition.weight)g")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(FitConnectColors.textPrimary)
                                
                                Text("\(nutrition.calories) cal")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(FitConnectColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text("300g")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(FitConnectColors.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FitConnectColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Meal Type Section
    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            HStack(spacing: 8) {
                ForEach(Meal.MealType.allCases, id: \.self) { mealType in
                    Button {
                        selectedMealType = mealType
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    } label: {
                        Text(mealType.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedMealType == mealType ? .white : FitConnectColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedMealType == mealType ?
                                        LinearGradient(
                                            colors: [FitConnectColors.accentPink, FitConnectColors.accentPurple],
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
                                            .stroke(selectedMealType == mealType ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Nutrition Information Section
    private func nutritionInfoSection(_ nutrition: NutritionEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                LogMealNutritionCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "\(nutrition.calories)",
                    unit: "kcal",
                    color: FitConnectColors.accentOrange
                )
                
                LogMealNutritionCard(
                    icon: "p.circle.fill",
                    title: "Protein",
                    value: String(format: "%.1f", nutrition.protein),
                    unit: "g", 
                    color: FitConnectColors.accentGreen
                )
                
                LogMealNutritionCard(
                    icon: "f.circle.fill",
                    title: "Fats",
                    value: String(format: "%.1f", nutrition.fats),
                    unit: "g",
                    color: FitConnectColors.accentOrange
                )
                
                LogMealNutritionCard(
                    icon: "c.circle.fill",
                    title: "Carbs",
                    value: String(format: "%.1f", nutrition.carbohydrates),
                    unit: "g",
                    color: FitConnectColors.accentBlue
                )
                
                LogMealNutritionCard(
                    icon: "leaf.fill",
                    title: "Fiber",
                    value: String(format: "%.1f", nutrition.fiber),
                    unit: "g",
                    color: FitConnectColors.accentGreen
                )
                
                LogMealNutritionCard(
                    icon: "s.circle.fill",
                    title: "Sugars",
                    value: String(format: "%.1f", nutrition.sugars),
                    unit: "g",
                    color: FitConnectColors.accentPink
                )
            }
            
            // Sodium (full width)
            LogMealNutritionCard(
                icon: "n.circle.fill",
                title: "Sodium",
                value: String(format: "%.0f", nutrition.sodium),
                unit: "mg",
                color: FitConnectColors.accentPurple
            )
        }
    }
    
    // MARK: - Date Selection Section
    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("When Did You Eat This?")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Button {
                showingDatePicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Text(formatDate(selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FitConnectColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Bottom Action Section
    private var bottomActionSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            Button {
                saveMeal()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Text(isLoading ? "Saving..." : "Save")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: canSave ? 
                            [FitConnectColors.accentGreen, FitConnectColors.accentCyan] :
                            [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: canSave ? FitConnectColors.accentGreen.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canSave || isLoading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(FitConnectColors.backgroundDark)
    }
    
    // MARK: - Success Toast
    private var successToastView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(FitConnectColors.accentGreen)
                
                Text("Meal logged successfully!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.8))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Food Picker Sheet
    private var foodPickerSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    TextField("Search foods...", text: $searchText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textPrimary)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FitConnectColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Food list
                List {
                    ForEach(nutritionManager.searchFoods(searchText)) { food in
                        Button {
                            selectedFood = food
                            portionSlider = min(2.0, Double(food.portions.count - 1))
                            showingFoodPicker = false
                            
                            print(" Selected food: \(food.displayName) with \(food.portions.count) portions")
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(FitConnectColors.textPrimary)
                                    
                                    Text("\(food.portions.count) portion sizes")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(FitConnectColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if selectedFood?.id == food.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(FitConnectColors.accentGreen)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .background(FitConnectColors.backgroundDark)
            }
            .background(FitConnectColors.backgroundDark)
            .navigationTitle("Choose Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingFoodPicker = false
                    }
                    .foregroundColor(FitConnectColors.accentPink)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Date Picker Sheet
    private var datePickerSheet: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .padding()
            .background(FitConnectColors.backgroundDark)
            .navigationTitle("When Did You Eat This?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDatePicker = false
                    }
                    .foregroundColor(FitConnectColors.accentGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Methods
    private func setupInitialState() {
        // Set meal type based on current time
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5...10:
            selectedMealType = .breakfast
        case 11...15:
            selectedMealType = .lunch
        case 16...21:
            selectedMealType = .dinner
        default:
            selectedMealType = .snack
        }
        
        // Pre-populate with detected food if available
        if !detectedFood.isEmpty {
            let searchTerms = detectedFood.lowercased().split(separator: " ")
            let matchingFoods = nutritionManager.searchFoods(detectedFood)
            
            // Try exact match first
            if let exactMatch = matchingFoods.first(where: { 
                $0.displayName.lowercased() == detectedFood.lowercased() 
            }) {
                selectedFood = exactMatch
                portionSlider = min(2.0, Double(exactMatch.portions.count - 1))
                print(" Exact match found: \(exactMatch.displayName)")
            }
            // Try partial match with main search terms
            else if let partialMatch = matchingFoods.first(where: { food in
                searchTerms.contains { term in
                    food.displayName.lowercased().contains(term) || food.label.lowercased().contains(term)
                }
            }) {
                selectedFood = partialMatch
                portionSlider = min(2.0, Double(partialMatch.portions.count - 1))
                print(" Partial match found: \(partialMatch.displayName) for '\(detectedFood)'")
            }
            // Fallback to first result
            else if let firstMatch = matchingFoods.first {
                selectedFood = firstMatch
                portionSlider = min(2.0, Double(firstMatch.portions.count - 1))
                print(" Fallback match: \(firstMatch.displayName) for '\(detectedFood)'")
            }
            else {
                print(" No matching food found for '\(detectedFood)'")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
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
            print(" Cannot save meal - missing required data")
            return
        }
        
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let mealData: [String: Any] = [
            "mealName": food.displayName,
            "foodLabel": food.label,
            "mealType": selectedMealType.rawValue,
            "portionIndex": currentPortionIndex,
            "portionWeight": nutrition.weight,
            "calories": nutrition.calories,
            "protein": nutrition.protein,
            "fat": nutrition.fats,
            "carbs": nutrition.carbohydrates,
            "fiber": nutrition.fiber,
            "sugars": nutrition.sugars,
            "sodium": nutrition.sodium,
            "timestamp": Timestamp(date: selectedDate),
            "dateString": dateString
        ]
        
        print("Logged meal: \(food.displayName), \(nutrition.weight)g → {calories: \(nutrition.calories), protein: \(nutrition.protein), fat: \(nutrition.fats), carbs: \(nutrition.carbohydrates)}")
        
        Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("healthData")
            .document(dateString)
            .collection("meals")
            .addDocument(data: mealData) { error in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if let error = error {
                        print("Error saving meal: \(error)")
                    } else {
                        print("Meal saved successfully")
                        
                        // Show success toast
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingSuccessToast = true
                        }
                        
                        // Haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.success)
                        
                        // Auto-dismiss after success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            onDismiss()
                        }
                    }
                }
            }
    }
}

// MARK: - Nutrition Card Component
struct LogMealNutritionCard: View { 
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text(unit)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FitConnectColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Slider Component
struct SliderView: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let accentColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 4)
                
                // Thumb
                Circle()
                    .fill(accentColor)
                    .frame(width: 20, height: 20)
                    .offset(x: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let percent = gesture.location.x / geometry.size.width
                                let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percent)
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                                
                                // Snap to step
                                value = round(value / step) * step
                            }
                    )
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Previews
#if DEBUG
@available(iOS 16.0, *)
struct LogMealSheetView_Previews: PreviewProvider {
    static var previews: some View {
        LogMealSheetView(
            detectedFood: "Pizza",
            estimatedCalories: 450,
            onDismiss: { }
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "client"))
        .preferredColorScheme(.dark)
    }
}
#endif
