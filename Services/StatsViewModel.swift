import Foundation
import SwiftUI
import Combine

struct StatsData {
    var stepCount: Int = 0
    var activeEnergyBurned: Double = 0
    var waterIntake: Double = 0
    
    static let empty = StatsData()
}

@MainActor
class StatsViewModel: ObservableObject {
    @Published var statsData: StatsData = .empty
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var todayMealCalories: Int = 0
    @Published var totalWeeklyMealCalories: Int = 0
    
    private let healthKitManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()
    
    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to HealthKit data updates and create StatsData
        Publishers.CombineLatest3(
            healthKitManager.$stepCount,
            healthKitManager.$activeEnergyBurned,
            healthKitManager.$waterIntake
        )
        .map { stepCount, activeEnergy, waterIntake in
            return StatsData(
                stepCount: stepCount,
                activeEnergyBurned: activeEnergy,
                waterIntake: waterIntake
            )
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] newData in
            print("[StatsViewModel] Received statsData update: \(newData)")
            self?.statsData = newData
        }
        .store(in: &cancellables)
    }
    
    func refreshStats() async {
        print("[StatsViewModel] refreshStats() called")
        guard !isLoading else {
            print("[StatsViewModel] Already loading, skipping")
            return
        }
        
        do {
            isLoading = true
            
            // Fetch meal data
            print("[StatsViewModel] Fetching meal data")
            await fetchMealData()
            
            isLoading = false
        } catch {
            print("[StatsViewModel] Error in refreshStats: \(error)")
            errorMessage = "Failed to refresh stats: \(error.localizedDescription)"
            showError = true
            isLoading = false
        }
    }
    
    private func fetchMealData() async {
        do {
            print("[StatsViewModel] Fetching meal data - placeholder implementation")
            // Placeholder - will implement actual Firestore fetching later
            todayMealCalories = 0
            totalWeeklyMealCalories = 0
        } catch {
            print("[StatsViewModel] Error fetching meal data: \(error)")
            // Don't fail the whole stats screen if meals fail to load
            todayMealCalories = 0
            totalWeeklyMealCalories = 0
        }
    }
}
