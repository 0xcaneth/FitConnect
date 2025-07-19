import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

/// ViewModel for UserAnalysisView to handle data fetching and processing
@MainActor
final class UserAnalysisViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    @Published var errorMessage: String?
    
    // Summary metrics
    @Published var averageSteps: Int = 0
    @Published var averageCaloriesBurned: Double = 0
    @Published var waterGoalAchievement: Double = 0
    @Published var averageSleepHours: Double = 0
    @Published var averageCaloriesConsumed: Int = 0
    
    // Chart data
    @Published var dailyActivityData: [DailyActivityData] = []
    @Published var dailyNutritionData: [DailyNutritionData] = []
    @Published var macronutrientData: [MacronutrientData] = []
    @Published var bodyCompositionData: [BodyCompositionData] = []
    @Published var healthTrendsData: [HealthTrendsData] = []
    
    // MARK: - Private Properties
    private let userId: String
    private let db = Firestore.firestore()
    private let dateRange: Int = 30 // Days to analyze
    
    // MARK: - Initialization
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Public Methods
    
    /// Load all analytics data
    func loadData() async {
        isLoading = true
        hasError = false
        errorMessage = nil
        
        do {
            async let healthData = fetchHealthKitData()
            async let mealData = fetchMealData()
            
            let (healthResults, mealResults) = await (healthData, mealData)
            
            await processData(healthData: healthResults, mealData: mealResults)
            
        } catch {
            hasError = true
            errorMessage = error.localizedDescription
            print("Error loading analytics data: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    /// Fetch HealthKit data from Firestore
    private func fetchHealthKitData() async -> [HealthKitDataPoint] {
        var healthDataPoints: [HealthKitDataPoint] = []
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange, to: endDate) ?? endDate
        
        do {
            // Fetch data for each day in range
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var currentDate = startDate
            while currentDate <= endDate {
                let dateString = dateFormatter.string(from: currentDate)
                
                let snapshot = try await db
                    .collection("users")
                    .document(userId)
                    .collection("healthData")
                    .document(dateString)
                    .collection("healthkit")
                    .getDocuments()
                
                let dayData = processHealthKitDocuments(snapshot.documents, for: currentDate)
                if let dayData = dayData {
                    healthDataPoints.append(dayData)
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
        } catch {
            print("Error fetching HealthKit data: \(error)")
        }
        
        return healthDataPoints
    }
    
    /// Process HealthKit documents for a specific day
    private func processHealthKitDocuments(_ documents: [QueryDocumentSnapshot], for date: Date) -> HealthKitDataPoint? {
        var steps: Int = 0
        var activeEnergyBurned: Double = 0
        var waterIntake: Double = 0
        var weight: Double?
        var height: Double?
        var bodyFatPercentage: Double?
        var restingHeartRate: Int?
        var bloodPressureSystolic: Int?
        var bloodPressureDiastolic: Int?
        var sleepHours: Double?
        
        for document in documents {
            let data = document.data()
            
            guard let type = data["type"] as? String,
                  let value = data["value"] as? Double else { continue }
            
            switch type {
            case "steps":
                steps = max(steps, Int(value))
            case "activeEnergyBurned":
                activeEnergyBurned = max(activeEnergyBurned, value)
            case "waterIntake":
                waterIntake += value
            case "weight":
                weight = value
            case "height":
                height = value
            case "bodyFatPercentage":
                bodyFatPercentage = value
            case "restingHeartRate":
                restingHeartRate = Int(value)
            case "bloodPressureSystolic":
                bloodPressureSystolic = Int(value)
            case "bloodPressureDiastolic":
                bloodPressureDiastolic = Int(value)
            case "sleepHours":
                sleepHours = value
            default:
                break
            }
        }
        
        // Only return data point if we have some meaningful data
        if steps > 0 || activeEnergyBurned > 0 || waterIntake > 0 || weight != nil {
            return HealthKitDataPoint(
                date: date,
                steps: steps,
                activeEnergyBurned: activeEnergyBurned,
                waterIntake: waterIntake,
                weight: weight,
                height: height,
                bodyFatPercentage: bodyFatPercentage,
                restingHeartRate: restingHeartRate,
                bloodPressureSystolic: bloodPressureSystolic,
                bloodPressureDiastolic: bloodPressureDiastolic,
                sleepHours: sleepHours
            )
        }
        
        return nil
    }
    
    /// Fetch meal data from Firestore
    private func fetchMealData() async -> [MealDataPoint] {
        var mealDataPoints: [MealDataPoint] = []
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -dateRange, to: endDate) ?? endDate
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            var currentDate = startDate
            while currentDate <= endDate {
                let dateString = dateFormatter.string(from: currentDate)
                
                let snapshot = try await db
                    .collection("users")
                    .document(userId)
                    .collection("healthData")
                    .document(dateString)
                    .collection("meals")
                    .getDocuments()
                
                let dayMealData = processMealDocuments(snapshot.documents, for: currentDate)
                if let dayMealData = dayMealData {
                    mealDataPoints.append(dayMealData)
                }
                
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
        } catch {
            print("Error fetching meal data: \(error)")
        }
        
        return mealDataPoints
    }
    
    /// Process meal documents for a specific day
    private func processMealDocuments(_ documents: [QueryDocumentSnapshot], for date: Date) -> MealDataPoint? {
        var totalCalories: Int = 0
        var totalProtein: Double = 0
        var totalFat: Double = 0
        var totalCarbs: Double = 0
        var totalFiber: Double = 0
        var totalSugars: Double = 0
        var totalSodium: Double = 0
        
        for document in documents {
            let data = document.data()
            
            // Handle nested nutrition structure
            if let nutrition = data["nutrition"] as? [String: Any] {
                totalCalories += nutrition["calories"] as? Int ?? 0
                totalProtein += nutrition["protein"] as? Double ?? 0
                totalFat += nutrition["fat"] as? Double ?? 0
                totalCarbs += nutrition["carbs"] as? Double ?? 0
                totalFiber += nutrition["fiber"] as? Double ?? 0
                totalSugars += nutrition["sugars"] as? Double ?? 0
                totalSodium += nutrition["sodium"] as? Double ?? 0
            } else {
                // Handle flat structure for backwards compatibility
                totalCalories += data["calories"] as? Int ?? 0
                totalProtein += data["protein"] as? Double ?? 0
                totalFat += data["fat"] as? Double ?? 0
                totalCarbs += data["carbs"] as? Double ?? 0
                totalFiber += data["fiber"] as? Double ?? 0
                totalSugars += data["sugars"] as? Double ?? 0
                totalSodium += data["sodium"] as? Double ?? 0
            }
        }
        
        if totalCalories > 0 {
            return MealDataPoint(
                date: date,
                totalCalories: totalCalories,
                totalProtein: totalProtein,
                totalFat: totalFat,
                totalCarbs: totalCarbs,
                totalFiber: totalFiber,
                totalSugars: totalSugars,
                totalSodium: totalSodium
            )
        }
        
        return nil
    }
    
    /// Process and analyze all fetched data
    private func processData(healthData: [HealthKitDataPoint], mealData: [MealDataPoint]) async {
        // Calculate summary metrics
        calculateSummaryMetrics(healthData: healthData, mealData: mealData)
        
        // Prepare chart data
        prepareDailyActivityData(healthData: healthData)
        prepareDailyNutritionData(healthData: healthData, mealData: mealData)
        prepareMacronutrientData(mealData: mealData)
        prepareBodyCompositionData(healthData: healthData)
        prepareHealthTrendsData(healthData: healthData)
    }
    
    /// Calculate summary metrics
    private func calculateSummaryMetrics(healthData: [HealthKitDataPoint], mealData: [MealDataPoint]) {
        // Average steps
        let totalSteps = healthData.reduce(0) { $0 + $1.steps }
        averageSteps = healthData.isEmpty ? 0 : totalSteps / healthData.count
        
        // Average calories burned
        let totalCaloriesBurned = healthData.reduce(0) { $0 + $1.activeEnergyBurned }
        averageCaloriesBurned = healthData.isEmpty ? 0 : totalCaloriesBurned / Double(healthData.count)
        
        // Average calories consumed
        let totalCaloriesConsumed = mealData.reduce(0) { $0 + $1.totalCalories }
        averageCaloriesConsumed = mealData.isEmpty ? 0 : totalCaloriesConsumed / mealData.count
        
        // Water goal achievement (assuming 2000ml goal)
        let waterGoal: Double = 2000
        let totalWaterDays = healthData.filter { $0.waterIntake > 0 }.count
        let waterAchievements = healthData.filter { $0.waterIntake >= waterGoal }.count
        waterGoalAchievement = totalWaterDays > 0 ? (Double(waterAchievements) / Double(totalWaterDays)) * 100 : 0
        
        // Average sleep hours
        let totalSleepHours = healthData.compactMap { $0.sleepHours }.reduce(0, +)
        let sleepDaysCount = healthData.compactMap { $0.sleepHours }.count
        averageSleepHours = sleepDaysCount > 0 ? totalSleepHours / Double(sleepDaysCount) : 0
    }
    
    /// Prepare daily activity data for charts
    private func prepareDailyActivityData(healthData: [HealthKitDataPoint]) {
        dailyActivityData = healthData.map { dataPoint in
            DailyActivityData(
                id: UUID(),
                date: dataPoint.date,
                steps: dataPoint.steps,
                activeCalories: dataPoint.activeEnergyBurned
            )
        }
    }
    
    /// Prepare daily nutrition data combining meals and burned calories
    private func prepareDailyNutritionData(healthData: [HealthKitDataPoint], mealData: [MealDataPoint]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create a dictionary for quick lookup
        let mealsByDate = Dictionary(uniqueKeysWithValues: mealData.map { (dateFormatter.string(from: $0.date), $0) })
        let healthByDate = Dictionary(uniqueKeysWithValues: healthData.map { (dateFormatter.string(from: $0.date), $0) })
        
        // Get all unique dates
        let allDates = Set(healthData.map { dateFormatter.string(from: $0.date) })
            .union(Set(mealData.map { dateFormatter.string(from: $0.date) }))
            .sorted()
        
        dailyNutritionData = allDates.compactMap { dateString in
            guard let date = dateFormatter.date(from: dateString) else { return nil }
            
            let caloriesConsumed = mealsByDate[dateString]?.totalCalories ?? 0
            let caloriesBurned = Int(healthByDate[dateString]?.activeEnergyBurned ?? 0)
            
            return DailyNutritionData(
                id: UUID(),
                date: date,
                caloriesConsumed: caloriesConsumed,
                caloriesBurned: caloriesBurned
            )
        }
    }
    
    /// Prepare macronutrient breakdown data
    private func prepareMacronutrientData(mealData: [MealDataPoint]) {
        let totalProtein = mealData.reduce(0) { $0 + $1.totalProtein }
        let totalFat = mealData.reduce(0) { $0 + $1.totalFat }
        let totalCarbs = mealData.reduce(0) { $0 + $1.totalCarbs }
        
        let total = totalProtein + totalFat + totalCarbs
        
        if total > 0 {
            macronutrientData = [
                MacronutrientData(
                    id: UUID(),
                    name: "Protein",
                    percentage: (totalProtein / total) * 100,
                    color: Color(red: 1.0, green: 0.42, blue: 0.42)
                ),
                MacronutrientData(
                    id: UUID(),
                    name: "Fat",
                    percentage: (totalFat / total) * 100,
                    color: Color(red: 0.306, green: 0.804, blue: 0.769)
                ),
                MacronutrientData(
                    id: UUID(),
                    name: "Carbs",
                    percentage: (totalCarbs / total) * 100,
                    color: Color(red: 0.271, green: 0.718, blue: 0.82)
                )
            ]
        } else {
            // Default values if no meal data
            macronutrientData = [
                MacronutrientData(
                    id: UUID(), 
                    name: "Protein", 
                    percentage: 30, 
                    color: Color(red: 1.0, green: 0.42, blue: 0.42)
                ),
                MacronutrientData(
                    id: UUID(), 
                    name: "Fat", 
                    percentage: 30, 
                    color: Color(red: 0.306, green: 0.804, blue: 0.769)
                ),
                MacronutrientData(
                    id: UUID(), 
                    name: "Carbs", 
                    percentage: 40, 
                    color: Color(red: 0.271, green: 0.718, blue: 0.82)
                )
            ]
        }
    }
    
    /// Prepare body composition data
    private func prepareBodyCompositionData(healthData: [HealthKitDataPoint]) {
        bodyCompositionData = healthData.compactMap { dataPoint in
            guard let weight = dataPoint.weight else { return nil }
            
            let bmi: Double?
            if let height = dataPoint.height, height > 0 {
                let heightInMeters = height / 100
                bmi = weight / (heightInMeters * heightInMeters)
            } else {
                bmi = nil
            }
            
            return BodyCompositionData(
                id: UUID(),
                date: dataPoint.date,
                weight: weight,
                bmi: bmi,
                bodyFatPercentage: dataPoint.bodyFatPercentage
            )
        }
    }
    
    /// Prepare health trends data
    private func prepareHealthTrendsData(healthData: [HealthKitDataPoint]) {
        healthTrendsData = healthData.compactMap { dataPoint in
            guard let restingHeartRate = dataPoint.restingHeartRate,
                  let sleepHours = dataPoint.sleepHours else { return nil }
            
            return HealthTrendsData(
                id: UUID(),
                date: dataPoint.date,
                restingHeartRate: restingHeartRate,
                sleepHours: sleepHours,
                bloodPressureSystolic: dataPoint.bloodPressureSystolic,
                bloodPressureDiastolic: dataPoint.bloodPressureDiastolic
            )
        }
    }
}

// MARK: - Data Models

struct HealthKitDataPoint {
    let date: Date
    let steps: Int
    let activeEnergyBurned: Double
    let waterIntake: Double
    let weight: Double?
    let height: Double?
    let bodyFatPercentage: Double?
    let restingHeartRate: Int?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let sleepHours: Double?
}

struct MealDataPoint {
    let date: Date
    let totalCalories: Int
    let totalProtein: Double
    let totalFat: Double
    let totalCarbs: Double
    let totalFiber: Double
    let totalSugars: Double
    let totalSodium: Double
}

struct DailyActivityData: Identifiable {
    let id: UUID
    let date: Date
    let steps: Int
    let activeCalories: Double
}

struct DailyNutritionData: Identifiable {
    let id: UUID
    let date: Date
    let caloriesConsumed: Int
    let caloriesBurned: Int
}

struct MacronutrientData: Identifiable {
    let id: UUID
    let name: String
    let percentage: Double
    let color: Color
}

struct BodyCompositionData: Identifiable {
    let id: UUID
    let date: Date
    let weight: Double
    let bmi: Double?
    let bodyFatPercentage: Double?
}

struct HealthTrendsData: Identifiable {
    let id: UUID
    let date: Date
    let restingHeartRate: Int
    let sleepHours: Double
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
}