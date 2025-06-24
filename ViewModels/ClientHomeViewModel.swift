import Foundation
import SwiftUI
import Combine

@MainActor
class ClientHomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var todaysGoals: [HealthGoal] = []
    @Published var recentActivities: [UserActivity] = []
    
    private let sessionStore: SessionStore
    private var cancellables = Set<AnyCancellable>()
    
    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        loadDashboardData()
    }
    
    func loadDashboardData() {
        isLoading = true
        
        // Load dashboard data
        loadTodaysGoals()
        loadRecentActivities()
        
        isLoading = false
    }
    
    private func loadTodaysGoals() {
        // Mock data for now
        todaysGoals = [
            HealthGoal(id: "1", title: "Steps", target: 10000, current: 6500, unit: "steps"),
            HealthGoal(id: "2", title: "Water", target: 2000, current: 1200, unit: "ml"),
            HealthGoal(id: "3", title: "Calories", target: 2000, current: 1650, unit: "cal")
        ]
    }
    
    private func loadRecentActivities() {
        // Mock data for now
        recentActivities = []
    }
    
    func refreshData() {
        loadDashboardData()
    }
}

struct HealthGoal: Identifiable {
    let id: String
    let title: String
    let target: Double
    let current: Double
    let unit: String
    
    var progress: Double {
        return current / target
    }
    
    var isCompleted: Bool {
        return current >= target
    }
}