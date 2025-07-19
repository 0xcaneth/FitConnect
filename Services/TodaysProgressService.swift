import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

/// Service to fetch and manage today's progress data from Firestore
@MainActor
final class TodaysProgressService: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var stepData: ProgressMetric = ProgressMetric(current: 0, goal: 10000, unit: "steps")
    @Published var caloriesData: ProgressMetric = ProgressMetric(current: 0, goal: 500, unit: "kcal")
    @Published var waterData: ProgressMetric = ProgressMetric(current: 0, goal: 2000, unit: "mL")
    @Published var sleepData: ProgressMetric = ProgressMetric(current: 0, goal: 8, unit: "hours")
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    // MARK: - Public Methods
    
    /// Start listening to today's progress data
    func startListening(for userId: String) {
        guard !userId.isEmpty else {
            print("[TodaysProgressService] Invalid user ID")
            return
        }
        
        stopListening()
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        listener = db.collection("users")
            .document(userId)
            .collection("healthData")
            .document(todayString)
            .collection("healthkit")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[TodaysProgressService] Error listening to health data: \(error)")
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.isLoading = false
                        return
                    }
                    
                    self.processHealthKitData(documents)
                    self.isLoading = false
                }
            }
        
        // Also fetch meal data for calorie intake
        fetchMealData(for: userId, date: todayString)
    }
    
    /// Stop listening to data updates
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// Get all progress metrics as an array
    var allMetrics: [ProgressMetric] {
        [stepData, caloriesData, waterData, sleepData]
    }
    
    // MARK: - Private Methods
    
    private func processHealthKitData(_ documents: [QueryDocumentSnapshot]) {
        var steps = 0
        var activeEnergy: Double = 0
        var water: Double = 0
        var sleep: Double = 0
        
        // Find the latest value for each metric
        var latestSteps: (value: Int, timestamp: Date) = (0, Date.distantPast)
        var latestEnergy: (value: Double, timestamp: Date) = (0, Date.distantPast)
        var latestWater: (value: Double, timestamp: Date) = (0, Date.distantPast)
        var latestSleep: (value: Double, timestamp: Date) = (0, Date.distantPast)
        
        for document in documents {
            let data = document.data()
            
            guard let type = data["type"] as? String,
                  let value = data["value"] as? Double,
                  let timestamp = data["timestamp"] as? Timestamp else { continue }
            
            let date = timestamp.dateValue()
            
            switch type {
            case "steps":
                if date > latestSteps.timestamp {
                    latestSteps = (Int(value), date)
                }
            case "activeEnergyBurned":
                if date > latestEnergy.timestamp {
                    latestEnergy = (value, date)
                }
            case "waterIntake":
                // For water, we want to sum all intake throughout the day
                latestWater.value += value
            case "sleepHours":
                if date > latestSleep.timestamp {
                    latestSleep = (value, date)
                }
            default:
                break
            }
        }
        
        // Update published properties with animation
        withAnimation(.easeInOut(duration: 0.5)) {
            stepData = ProgressMetric(
                current: latestSteps.value,
                goal: 10000,
                unit: "steps",
                icon: "figure.walk",
                color: Color(hex: "3CD76B")
            )
            
            caloriesData = ProgressMetric(
                current: Int(latestEnergy.value),
                goal: 500,
                unit: "kcal",
                icon: "flame.fill",
                color: Color(hex: "FF8E3C")
            )
            
            waterData = ProgressMetric(
                current: Int(latestWater.value),
                goal: 2000,
                unit: "mL",
                icon: "drop.fill",
                color: Color(hex: "3C9CFF")
            )
            
            sleepData = ProgressMetric(
                current: Int(latestSleep.value * 10) / 10, // Round to 1 decimal
                goal: 8,
                unit: "hours",
                icon: "bed.double.fill",
                color: Color(hex: "8B5FBF")
            )
        }
    }
    
    private func fetchMealData(for userId: String, date: String) {
        db.collection("users")
            .document(userId)
            .collection("healthData")
            .document(date)
            .collection("meals")
            .getDocuments { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[TodaysProgressService] Error fetching meal data: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    var totalCalories = 0
                    
                    for document in documents {
                        let data = document.data()
                        
                        // Handle nested nutrition structure
                        if let nutrition = data["nutrition"] as? [String: Any] {
                            totalCalories += nutrition["calories"] as? Int ?? 0
                        } else {
                            // Handle flat structure for backwards compatibility
                            totalCalories += data["calories"] as? Int ?? 0
                        }
                    }
                    
                    // Update calories data to include consumed calories
                    withAnimation(.easeInOut(duration: 0.5)) {
                        // Create a new metric that shows calories consumed vs goal
                        self.caloriesData = ProgressMetric(
                            current: totalCalories,
                            goal: 2000, // Daily calorie goal
                            unit: "kcal",
                            icon: "fork.knife",
                            color: Color(hex: "26C6DA"),
                            subtitle: "consumed"
                        )
                    }
                }
            }
    }
    
    deinit {
        print("[TodaysProgressService] Deinitializing...")
        listener?.remove()
        listener = nil
    }
}

// MARK: - Supporting Types

/// Progress metric data structure
struct ProgressMetric: Identifiable {
    let id = UUID()
    let current: Int
    let goal: Int
    let unit: String
    let icon: String
    let color: Color
    let subtitle: String?
    
    init(current: Int, goal: Int, unit: String, icon: String = "circle.fill", color: Color = .blue, subtitle: String? = nil) {
        self.current = current
        self.goal = goal
        self.unit = unit
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }
    
    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var isGoalAchieved: Bool {
        current >= goal
    }
}