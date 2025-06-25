import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Comprehensive analytics view for user health data
@available(iOS 16.0, *)
struct UserAnalysisView: View {
    let userId: String
    let isCurrentUser: Bool
    
    @StateObject private var viewModel: UserAnalysisViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(userId: String, isCurrentUser: Bool = false) {
        self.userId = userId
        self.isCurrentUser = isCurrentUser
        self._viewModel = StateObject(wrappedValue: UserAnalysisViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.hasError {
                    errorView
                } else {
                    analyticsContent
                }
            }
            .navigationTitle(isCurrentUser ? "My Analytics" : "Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#8F3FFF"))
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#8F3FFF")))
                .scaleEffect(1.5)
            
            Text("Loading analytics...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to Load Data")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(viewModel.errorMessage ?? "An unexpected error occurred")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Retry") {
                Task {
                    await viewModel.loadData()
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color(hex: "#8F3FFF"))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Analytics Content
    
    private var analyticsContent: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Cards
                summarySection
                
                // Activity Overview
                activityOverviewSection
                
                // Nutrition Overview
                nutritionOverviewSection
                
                // Body Composition
                bodyCompositionSection
                
                // Health Trends
                healthTrendsSection
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                summaryCard(
                    title: "Avg Steps",
                    value: "\(viewModel.averageSteps)",
                    subtitle: "per day",
                    color: Color(hex: "#3CD76B"),
                    icon: "figure.walk"
                )
                
                summaryCard(
                    title: "Avg Calories",
                    value: "\(Int(viewModel.averageCaloriesBurned))",
                    subtitle: "burned/day",
                    color: Color(hex: "#FF8E3C"),
                    icon: "flame.fill"
                )
            }
            
            HStack(spacing: 12) {
                summaryCard(
                    title: "Water Goal",
                    value: "\(Int(viewModel.waterGoalAchievement))%",
                    subtitle: "achievement",
                    color: Color(hex: "#3C9CFF"),
                    icon: "drop.fill"
                )
                
                summaryCard(
                    title: "Sleep Avg",
                    value: String(format: "%.1f", viewModel.averageSleepHours),
                    subtitle: "hours",
                    color: Color(hex: "#8B5FBF"),
                    icon: "bed.double.fill"
                )
            }
        }
    }
    
    private func summaryCard(title: String, value: String, subtitle: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Activity Overview Section
    
    private var activityOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Steps trend
                trendCard(
                    title: "Steps Trend",
                    data: viewModel.dailyActivityData.map { Double($0.steps) },
                    color: Color(hex: "#3CD76B"),
                    average: Double(viewModel.averageSteps),
                    unit: "steps"
                )
                
                // Calories trend
                trendCard(
                    title: "Calories Burned Trend",
                    data: viewModel.dailyActivityData.map { $0.activeCalories },
                    color: Color(hex: "#FF8E3C"),
                    average: viewModel.averageCaloriesBurned,
                    unit: "kcal"
                )
            }
        }
    }
    
    // MARK: - Nutrition Overview Section
    
    private var nutritionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Overview")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Calories balance
                calorieBalanceCard()
                
                // Macronutrient breakdown
                macronutrientBreakdownCard()
            }
        }
    }
    
    // MARK: - Body Composition Section
    
    private var bodyCompositionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Body Composition")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if !viewModel.bodyCompositionData.isEmpty {
                    bodyMetricsCard()
                } else {
                    emptyDataCard(title: "Body Composition", message: "No body composition data available")
                }
            }
        }
    }
    
    // MARK: - Health Trends Section
    
    private var healthTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Trends")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                if !viewModel.healthTrendsData.isEmpty {
                    healthMetricsCard()
                } else {
                    emptyDataCard(title: "Health Trends", message: "No health trends data available")
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func trendCard(title: String, data: [Double], color: Color, average: Double, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Avg: \(Int(average)) \(unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Simple line chart representation
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let maxValue = data.max() ?? 1
                        let height = CGFloat((value / maxValue) * 50)
                        
                        Rectangle()
                            .fill(color)
                            .frame(width: 4, height: max(height, 2))
                            .cornerRadius(2)
                    }
                }
                .frame(height: 50)
                
                Text("Last 30 days")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func calorieBalanceCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calorie Balance")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Consumed")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(viewModel.averageCaloriesConsumed) kcal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#26C6DA"))
                }
                
                VStack(alignment: .leading) {
                    Text("Burned")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(viewModel.averageCaloriesBurned)) kcal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#FF5722"))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Balance")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    let balance = viewModel.averageCaloriesConsumed - Int(viewModel.averageCaloriesBurned)
                    Text("\(balance > 0 ? "+" : "")\(balance) kcal")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(balance > 0 ? .orange : Color(hex: "#3CD76B"))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func macronutrientBreakdownCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macronutrient Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                ForEach(viewModel.macronutrientData) { macro in
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 4)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .trim(from: 0, to: macro.percentage / 100)
                                .stroke(macro.color, lineWidth: 4)
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(macro.percentage))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text(macro.name)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func bodyMetricsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Metrics")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if let latestData = viewModel.bodyCompositionData.last {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Weight")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(String(format: "%.1f kg", latestData.weight))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#42A5F5"))
                    }
                    
                    if let bmi = latestData.bmi {
                        VStack(alignment: .leading) {
                            Text("BMI")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(String(format: "%.1f", bmi))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#8E24AA"))
                        }
                    }
                    
                    if let bodyFat = latestData.bodyFatPercentage {
                        VStack(alignment: .leading) {
                            Text("Body Fat")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(String(format: "%.1f%%", bodyFat))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FFA726"))
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func healthMetricsCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Metrics")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            if let latestData = viewModel.healthTrendsData.last {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Resting HR")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(latestData.restingHeartRate) bpm")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#F44336"))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Sleep")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(String(format: "%.1f hrs", latestData.sleepHours))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#9C27B0"))
                    }
                    
                    if let systolic = latestData.bloodPressureSystolic,
                       let diastolic = latestData.bloodPressureDiastolic {
                        VStack(alignment: .leading) {
                            Text("Blood Pressure")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("\(systolic)/\(diastolic)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FF9800"))
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private func emptyDataCard(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, *)
struct UserAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        UserAnalysisView(userId: "preview-user", isCurrentUser: true)
            .preferredColorScheme(.dark)
    }
}
#endif
