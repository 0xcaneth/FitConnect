import SwiftUI
import CoreML
import Vision
import AVFoundation

// MARK: - Enhanced Scan Results View
/// Redesigned scan results with modern UI, animated confidence indicators, and seamless log meal integration
@available(iOS 16.0, *)
struct ScanResultView: View {
    let image: UIImage?
    let analysis: MealAnalysis?
    let detectedFoodName: String 
    let onSave: (Meal.MealType) -> Void
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @State private var selectedMealType: Meal.MealType = .breakfast
    @State private var showingLogMealSheet = false
    @State private var confidenceRingProgress: Double = 0.0
    @State private var showingResults = false
    @State private var predictedLabel: String = ""
    @State private var confidence: Double = 0.0
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            FitConnectColors.backgroundDark.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header with close and refresh buttons
                    headerView
                    
                    // Captured image with overlay
                    if let image = image {
                        capturedImageView(image)
                    }
                    
                    // Main analysis content
                    if isProcessing {
                        processingView
                    } else if showingResults {
                        resultsContentView
                    } else {
                        emptyStateView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .onAppear {
            initializeAnalysis()
        }
        .sheet(isPresented: $showingLogMealSheet) {
            LogMealSheetView(
                detectedFood: detectedFoodName.isEmpty ? predictedLabel : detectedFoodName, 
                estimatedCalories: analysis?.calories ?? 0,
                onDismiss: { showingLogMealSheet = false }
            )
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
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
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(FitConnectColors.cardBackground)
                    )
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
                    .foregroundColor(FitConnectColors.accentPurple)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(FitConnectColors.cardBackground)
                    )
            }
        }
    }
    
    // MARK: - Captured Image with Overlay
    private func capturedImageView(_ image: UIImage) -> some View {
        ZStack(alignment: .top) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 320, height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
            
            // Overlay label at top
            if showingResults && !detectedFoodName.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(FitConnectColors.accentGreen)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Meal analyzed: \(detectedFoodName), \(analysis?.calories ?? 0) kcal") 
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                        )
                )
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 20) {
            // Animated processing indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isProcessing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isProcessing)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(FitConnectColors.accentCyan)
            }
            
            Text("Analyzing your meal...")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Text("Our AI is identifying the food and calculating nutrition")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FitConnectColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .transition(.opacity)
    }
    
    // MARK: - Results Content View
    private var resultsContentView: some View {
        VStack(spacing: 24) {
            // Confidence indicator with animated ring
            confidenceIndicatorView
            
            // Nutrition summary cards
            if let analysis = analysis {
                nutritionSummaryView(analysis)
            }
            
            // Action button
            actionButtonView
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Confidence Indicator
    private var confidenceIndicatorView: some View {
        VStack(spacing: 16) {
            // Animated confidence ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: confidenceRingProgress)
                    .stroke(
                        LinearGradient(
                            colors: confidence >= 0.8 ? 
                                [FitConnectColors.accentGreen, FitConnectColors.accentCyan] :
                                [FitConnectColors.accentOrange, FitConnectColors.accentPink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.5), value: confidenceRingProgress)
                
                VStack(spacing: 4) {
                    if confidence >= 0.8 {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FitConnectColors.accentGreen)
                    } else {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(FitConnectColors.accentOrange)
                    }
                    
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(FitConnectColors.textPrimary)
                }
            }
            
            // Food name and confidence label
            VStack(spacing: 4) {
                Text(detectedFoodName.isEmpty ? "Unknown Food" : detectedFoodName) 
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FitConnectColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Confidence: \(Int(confidence * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
        }
        .padding(.vertical, 16)
        .onAppear {
            // Animate confidence ring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confidenceRingProgress = confidence
            }
        }
    }
    
    // MARK: - Nutrition Summary
    private func nutritionSummaryView(_ analysis: MealAnalysis) -> some View {
        VStack(spacing: 16) {
            // Large calorie display
            VStack(spacing: 8) {
                Text("\(analysis.calories)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(FitConnectColors.accentCyan)
                
                Text("Calories")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            .padding(.bottom, 8)
            
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ScanNutritionCard(
                    icon: "flame.fill",
                    label: "Calories",
                    value: "\(analysis.calories) kcal",
                    color: FitConnectColors.accentOrange
                )
                
                ScanNutritionCard(
                    icon: "bolt.fill",
                    label: "Protein",
                    value: "\(Int(analysis.protein)) g",
                    color: FitConnectColors.accentPink
                )
                
                ScanNutritionCard(
                    icon: "drop.fill",
                    label: "Fat",
                    value: "\(Int(analysis.fat)) g",
                    color: FitConnectColors.accentOrange
                )
                
                ScanNutritionCard(
                    icon: "leaf.arrow.triangle.circlepath",
                    label: "Carbs",
                    value: "\(Int(analysis.carbs)) g",
                    color: FitConnectColors.accentBlue
                )
                
                ScanNutritionCard(
                    icon: "leaf.fill",
                    label: "Fiber",
                    value: "\(Int(analysis.fiber)) g",
                    color: FitConnectColors.accentGreen
                )
                
                ScanNutritionCard(
                    icon: "circle.grid.hex.fill",
                    label: "Sugars",
                    value: "\(Int(analysis.sugars)) g",
                    color: FitConnectColors.accentPink
                )
                
                ScanNutritionCard(
                    icon: "speedometer",
                    label: "Sodium",
                    value: "\(Int(analysis.sodium)) mg",
                    color: FitConnectColors.accentPurple
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Action Button
    private var actionButtonView: some View {
        Button {
            if confidence >= 0.8 {
                showingLogMealSheet = true
            } else {
                retryAnalysis()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: confidence >= 0.8 ? "plus.circle.fill" : "arrow.clockwise")
                    .font(.system(size: 18, weight: .semibold))
                
                Text(confidence >= 0.8 ? "Log This Meal" : "Try Again")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: confidence >= 0.8 ? 
                        [FitConnectColors.accentCyan, FitConnectColors.accentBlue] :
                        [FitConnectColors.accentOrange, FitConnectColors.accentPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: (confidence >= 0.8 ? FitConnectColors.accentCyan : FitConnectColors.accentOrange).opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(FitConnectColors.accentPurple)
            
            Text("Ready to analyze")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Text("Tap the button to start analyzing your meal")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FitConnectColors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                startAnalysis()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Analyze Food")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Analysis Methods
    private func initializeAnalysis() {
        // Auto-start analysis if we have analysis data
        if let analysis = analysis {
            predictedLabel = detectedFoodName.isEmpty ? "Detected Food" : detectedFoodName 
            confidence = analysis.confidence
            showingResults = true
            
            // Animate confidence ring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confidenceRingProgress = confidence
            }
        }
    }
    
    private func startAnalysis() {
        isProcessing = true
        showingResults = false
        
        // Simulate analysis process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Mock analysis completion
            predictedLabel = detectedFoodName.isEmpty ? "Pizza" : detectedFoodName 
            confidence = 0.87 
            
            isProcessing = false
            showingResults = true
            
            // Animate confidence ring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confidenceRingProgress = confidence
            }
        }
    }
    
    private func retryAnalysis() {
        startAnalysis()
    }
}

// MARK: - Scan Nutrition Card Component
struct ScanNutritionCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
                    .lineLimit(1)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FitConnectColors.textPrimary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FitConnectColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Previews
#if DEBUG
@available(iOS 16.0, *)
struct ScanResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // High confidence state
            ScanResultView(
                image: UIImage(systemName: "photo"),
                analysis: MealAnalysis(calories: 450, protein: 25.0, fat: 15.0, carbs: 55.0, fiber: 5.0, sugars: 8.0, sodium: 800, confidence: 0.87),
                detectedFoodName: "Pizza", 
                onSave: { _ in },
                onRetry: { },
                onDismiss: { }
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("High Confidence")
            
            // Low confidence state
            ScanResultView(
                image: UIImage(systemName: "photo"),
                analysis: MealAnalysis(calories: 320, protein: 18.0, fat: 12.0, carbs: 42.0, fiber: 3.0, sugars: 6.0, sodium: 600, confidence: 0.45),
                detectedFoodName: "Pasta", 
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