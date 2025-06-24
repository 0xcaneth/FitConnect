import SwiftUI
import CoreML
import Vision
import AVFoundation

// MARK: - Main View
@available(iOS 16.0, *)
struct MealScanResultView: View {
    let image: UIImage?
    let analysis: MealAnalysis?
    let onSave: (Meal.MealType) -> Void
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @State private var selectedMealType: Meal.MealType = .snack
    @State private var isAnalyzing = false
    @State private var showingResults = false
    @State private var predictedLabel: String = ""
    @State private var confidence: Double = 0.0
    @State private var isRunningPrediction = false
    @State private var showingDetailSheet = false
    @State private var alternativePredictions: [String] = []
    @State private var showingNutritionFacts = false
    @State private var pulseAnimation = false
    @State private var shimmerAnimation = false
    @State private var confidenceBarAnimation = false
    @State private var cardBackgroundAnimation = false
    @State private var actionButtonsFadeIn = false
    
    // Card background colors based on confidence
    private var confidenceCardColor: Color {
        if confidence >= 0.8 {
            return Color.green.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }
    
    private var confidenceProgressColor: Color {
        if confidence >= 0.8 {
            return Color(hex: "#4CAF50") ?? .green
        } else {
            return Color(hex: "#F44336") ?? .red
        }
    }
    
    var body: some View {
        ZStack {
            FitConnectColors.backgroundDark.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerView
                    
                    // Captured Image
                    if let image = image {
                        capturedImageView(image)
                    }
                    
                    // Analysis State Content
                    if isAnalyzing || isRunningPrediction {
                        analyzingPlaceholderView
                    } else if showingResults {
                        resultCardView
                    } else {
                        initialStateView
                    }
                    
                    // Meal Type Selection (only shown for high confidence)
                    if showingResults && confidence >= 0.8 {
                        mealTypeSelectionView
                    }
                    
                    // Action Buttons (only shown for high confidence)
                    if showingResults && confidence >= 0.8 {
                        actionButtonsView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            // Auto-run prediction when view appears
            startAnalysis()
        }
        .sheet(isPresented: $showingDetailSheet) {
            detailSheetView
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingNutritionFacts) {
            nutritionFactsView
                .presentationDetents([.medium])
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            
            Spacer()
            
            Text("Scan Results")
                .font(.title2.bold())
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
            
            Button {
                retryAnalysis()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Color(hex: "#6E56E9"))
            }
        }
    }
    
    // MARK: - Captured Image View
    private func capturedImageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Initial State View
    private var initialStateView: some View {
        VStack(spacing: 16) {
            Button {
                startAnalysis()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Analyze Food")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#6E56E9") ?? .purple, Color(hex: "#9C88FF") ?? .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: (Color(hex: "#6E56E9") ?? .purple).opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Analyzing Placeholder View
    private var analyzingPlaceholderView: some View {
        VStack(spacing: 20) {
            // Shimmer placeholder card
            RoundedRectangle(cornerRadius: 16)
                .fill(FitConnectColors.cardBackground)
                .frame(width: 300, height: 200)
                .overlay(
                    // Shimmer effect
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [Color.clear, Color.black, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                    .offset(x: shimmerAnimation ? 300 : -300)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: shimmerAnimation)
                )
                .overlay(
                    VStack(spacing: 16) {
                        // Pulsing icon
                        Image(systemName: "fork.knife")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(Color(hex: "#6E56E9"))
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
                        
                        Text("Scanning...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(FitConnectColors.textPrimary)
                    }
                )
            
            Text("Our AI is analyzing your food...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FitConnectColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .transition(.slide)
        .onAppear {
            shimmerAnimation = true
            pulseAnimation = true
        }
    }
    
    // MARK: - Result Card View
    private var resultCardView: some View {
        VStack(spacing: 20) {
            // Main result card
            VStack(spacing: 16) {
                // Success checkmark or warning (appears after analysis)
                if confidence >= 0.8 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color(hex: "#4CAF50"))
                        .scaleEffect(showingResults ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingResults)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.orange)
                        .scaleEffect(showingResults ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingResults)
                }
                
                // Food name
                Text(predictedLabel.isEmpty ? "Unknown Food" : predictedLabel)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(FitConnectColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Confidence subtitle
                Text(String(format: "Confidence: %.0f%%", confidence * 100))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
                
                // Animated confidence progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: confidenceBarAnimation ? confidence : 0)
                        .stroke(
                            confidenceProgressColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.2).delay(0.3), value: confidenceBarAnimation)
                    
                    Text(String(format: "%.0f%%", confidence * 100))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(confidenceProgressColor)
                }
                
                // Low confidence warning with retry suggestion
                if confidence < 0.8 {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Not sure? Try again")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        Button {
                            retryAnalysis()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12, weight: .medium))
                                
                                Text("Rescan")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.orange, lineWidth: 1)
                            )
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        confidence >= 0.8 
                        ? FitConnectColors.cardBackground
                        : Color.orange.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                confidence >= 0.8 
                                ? Color.white.opacity(0.2) 
                                : Color.orange.opacity(0.5),
                                lineWidth: confidence >= 0.8 ? 1 : 2
                            )
                    )
            )
            .onTapGesture {
                showingDetailSheet = true
            }
            
            // Analysis results from external service (only shown for high confidence)
            if let analysis = analysis, confidence >= 0.8 {
                nutritionalSummaryView(analysis)
            }
        }
        .transition(.slide)
        .onAppear {
            // Trigger animations after card appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                confidenceBarAnimation = true
                cardBackgroundAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                actionButtonsFadeIn = true
            }
            
            // Trigger haptic feedback based on confidence
            if confidence >= 0.8 {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            } else {
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
            }
        }
    }
    
    // MARK: - Nutritional Summary View
    private func nutritionalSummaryView(_ analysis: MealAnalysis) -> some View {
        VStack(spacing: 16) {
            // Calories headline
            VStack(spacing: 8) {
                Text("\(analysis.calories)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: "#6E56E9"))
                
                Text("Calories")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            
            // Macros grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MacroCard(
                    icon: "flame.fill",
                    title: "Protein",
                    value: "\(Int(analysis.protein))g",
                    color: Color(hex: "#FF6B6B") ?? .red
                )
                
                MacroCard(
                    icon: "drop.fill",
                    title: "Fat",
                    value: "\(Int(analysis.fat))g",
                    color: Color(hex: "#4ECDC4") ?? .cyan
                )
                
                MacroCard(
                    icon: "leaf.fill",
                    title: "Carbs",
                    value: "\(Int(analysis.carbs))g",
                    color: Color(hex: "#45B7D1") ?? .blue
                )
            }
        }
        .opacity(actionButtonsFadeIn ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.4), value: actionButtonsFadeIn)
    }
        
    // MARK: - Meal Type Selection View (only shown for high confidence)
    private var mealTypeSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Type")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Meal.MealType.allCases, id: \.self) { mealType in
                    MealTypeButton(
                        mealType: mealType,
                        isSelected: selectedMealType == mealType
                    ) {
                        selectedMealType = mealType
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
            }
        }
        .opacity(actionButtonsFadeIn ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.4).delay(0.2), value: actionButtonsFadeIn)
    }
    
    // MARK: - Action Buttons View (only shown for high confidence)
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // View Nutritional Facts Button
                Button {
                    showingNutritionFacts = true
                } label: {
                    Text("View Nutrition")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Save Meal Button
                Button {
                    onSave(selectedMealType)
                    
                    // Success haptic
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } label: {
                    Text("Save Meal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF6D00") ?? .orange, Color(hex: "#FF4081") ?? .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: (Color(hex: "#FF6D00") ?? .orange).opacity(0.4), radius: 12, x: 0, y: 6)
                }
            }
        }
        .opacity(actionButtonsFadeIn ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.4).delay(0.4), value: actionButtonsFadeIn)
    }
    
    // MARK: - Detail Sheet View
    private var detailSheetView: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Analysis Details")
                        .font(.title2.bold())
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingDetailSheet = false
                    }
                    .foregroundColor(Color(hex: "#6E56E9"))
                }
                .padding(.horizontal)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Primary prediction
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Prediction")
                                .font(.headline)
                                .foregroundColor(FitConnectColors.textPrimary)
                            
                            Text(predictedLabel)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(Color(hex: "#6E56E9"))
                        }
                        
                        Divider()
                        
                        // Alternative predictions
                        if !alternativePredictions.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alternative Predictions")
                                    .font(.headline)
                                    .foregroundColor(FitConnectColors.textPrimary)
                                
                                ForEach(alternativePredictions.prefix(3), id: \.self) { prediction in
                                    Text("• \(prediction)")
                                        .foregroundColor(FitConnectColors.textSecondary)
                                }
                            }
                            
                            Divider()
                        }
                        
                        // Confidence explanation
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confidence Level")
                                .font(.headline)
                                .foregroundColor(FitConnectColors.textPrimary)
                            
                            Text(String(format: "%.1f%% confident", confidence * 100))
                                .font(.title3.weight(.semibold))
                                .foregroundColor(confidenceProgressColor)
                            
                            if confidence < 0.8 {
                                Text("Possible reasons for low confidence:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(FitConnectColors.textSecondary)
                                    .padding(.top, 8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Image quality or lighting conditions")
                                    Text("• Food item not clearly visible")
                                    Text("• Mixed or complex food combinations")
                                    Text("• Uncommon or regional food items")
                                }
                                .font(.footnote)
                                .foregroundColor(FitConnectColors.textTertiary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .background(FitConnectColors.backgroundDark)
        }
    }
    
    // MARK: - Nutrition Facts View
    private var nutritionFactsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Nutrition Facts")
                        .font(.title2.bold())
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Done") {
                        showingNutritionFacts = false
                    }
                    .foregroundColor(Color(hex: "#6E56E9"))
                }
                .padding(.horizontal)
                
                if let analysis = analysis {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Main nutrition label style
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nutrition Facts")
                                    .font(.title3.bold())
                                    .foregroundColor(FitConnectColors.textPrimary)
                                
                                Divider()
                                
                                NutritionRow(label: "Calories", value: "\(analysis.calories)", unit: "")
                                NutritionRow(label: "Protein", value: String(format: "%.1f", analysis.protein), unit: "g")
                                NutritionRow(label: "Total Fat", value: String(format: "%.1f", analysis.fat), unit: "g")
                                NutritionRow(label: "Total Carbohydrates", value: String(format: "%.1f", analysis.carbs), unit: "g")
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(FitConnectColors.cardBackground)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .background(FitConnectColors.backgroundDark)
        }
    }
    
    // MARK: - Analysis Methods
    private func startAnalysis() {
        guard let image = image else { return }
        
        isAnalyzing = true
        isRunningPrediction = true
        showingResults = false
        confidence = 0.0
        predictedLabel = ""
        
        // Reset animations
        confidenceBarAnimation = false
        cardBackgroundAnimation = false
        actionButtonsFadeIn = false
        
        runPrediction(on: image)
    }
    
    private func retryAnalysis() {
        // Auto-dismiss after 2 seconds if low confidence persists  
        onRetry()
        
        // Show banner message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if self.confidence < 0.8 {
                // Auto-dismiss with banner
                self.onDismiss()
            }
        }
    }
    
    private func runPrediction(on uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else {
            print("❌ Failed to convert UIImage to CGImage")
            isAnalyzing = false
            isRunningPrediction = false
            predictedLabel = "Image processing failed"
            return
        }
        
        Task {
            do {
                // Create classifier instance
                let classifier = CoreMLFoodClassifier()
                
                // Run classification
                let prediction = try await withCheckedThrowingContinuation { continuation in
                    classifier.classifyFood(image: uiImage) { result in
                        continuation.resume(with: result)
                    }
                }
                
                await MainActor.run {
                    self.isAnalyzing = false
                    self.isRunningPrediction = false
                    self.predictedLabel = prediction.label
                    self.confidence = prediction.confidence
                    
                    // Show results with animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.showingResults = true
                    }
                    
                    print("✅ Food classified as: \(prediction.label) with \(String(format: "%.0f%%", prediction.confidence * 100)) confidence")
                }
                
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.isRunningPrediction = false
                    self.predictedLabel = "Classification failed"
                    self.confidence = 0.0
                    
                    // Show error banner for 2 seconds then auto-dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.onDismiss()
                    }
                    
                    print("❌ Core ML model error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MacroCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FitConnectColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct MealTypeButton: View {
    let mealType: Meal.MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mealTypeIcon(mealType))
                    .font(.system(size: 14, weight: .medium))
                
                Text(mealType.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#6E56E9"))
                }
            }
            .foregroundColor(isSelected ? FitConnectColors.textPrimary : FitConnectColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? FitConnectColors.cardBackground : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? (Color(hex: "#6E56E9") ?? .blue) : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func mealTypeIcon(_ mealType: Meal.MealType) -> String {
        switch mealType {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.fill"
        case .snack:
            return "star.fill"
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
            
            HStack(spacing: 2) {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundColor(FitConnectColors.textPrimary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .foregroundColor(FitConnectColors.textSecondary)
                }
            }
        }
        .font(.system(size: 16))
    }
}

// MARK: - View Extensions
extension View {
    func flipFromTop() -> some View {
        self.transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        ))
    }
}

// MARK: - Previews
#if DEBUG
@available(iOS 16.0, *)
struct MealScanResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // High confidence state
            MealScanResultView(
                image: UIImage(systemName: "camera.fill"),
                analysis: MealAnalysis(calories: 350, protein: 25.0, fat: 12.0, carbs: 45.0, confidence: 0.87),
                onSave: { _ in },
                onRetry: { },
                onDismiss: { }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("High Confidence")
            
            // Low confidence state
            MealScanResultView(
                image: UIImage(systemName: "camera.fill"),
                analysis: MealAnalysis(calories: 280, protein: 15.0, fat: 8.0, carbs: 35.0, confidence: 0.42),
                onSave: { _ in },
                onRetry: { },
                onDismiss: { }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Low Confidence")
        }
    }
}
#endif

// MARK: - Legacy Compatibility
@available(iOS 16.0, *)
typealias ScanResultView = MealScanResultView