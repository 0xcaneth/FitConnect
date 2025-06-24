import Foundation
import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todaySteps: Int = 0
    @Published var todayCalories: Int = 0
    @Published var todayWaterMl: Int = 0
    @Published var isLoadingHealthData: Bool = false
    @Published var healthDataError: String?
    @Published var showHealthDataBanner: Bool = false
    @Published var userSettings: UserSettings = .default
    
    var healthKitManager: HealthKitManager?
    private let hydrationService: HydrationService
    private let userSettingsService: UserSettingsService
    private let preferenceService: PreferenceService
    private var cancellables = Set<AnyCancellable>()
    
    init(healthKitManager: HealthKitManager,
         hydrationService: HydrationService = .shared,
         userSettingsService: UserSettingsService = .shared,
         preferenceService: PreferenceService = .shared) {
        self.healthKitManager = healthKitManager
        self.hydrationService = hydrationService
        self.userSettingsService = userSettingsService
        self.preferenceService = preferenceService
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        userSettingsService.$userSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.userSettings = settings
            }
            .store(in: &cancellables)
        
        // Subscribe to HealthKit manager updates
        healthKitManager?.$stepCount
            .map { Int($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$todaySteps)

        healthKitManager?.$activeEnergyBurned
            .map { Int($0) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$todayCalories)

        healthKitManager?.$waterIntake
            .map { Int($0 * 1000) }
            .receive(on: DispatchQueue.main)
            .assign(to: &$todayWaterMl)
            
        // Check authorization status
        if let healthKitManager = healthKitManager {
            healthKitManager.$authorizationStatus
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self = self else { return }
                    if status == .notDetermined {
                        self.showHealthDataBanner = true
                        self.healthDataError = "Tap to allow HealthKit access."
                    } else if status == .sharingDenied {
                        self.showHealthDataBanner = true
                        self.healthDataError = "HealthKit access is required. Please enable it in Settings > Health."
                    } else if status == .sharingAuthorized {
                        self.showHealthDataBanner = false
                        self.healthDataError = nil
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    func loadTodayData(for userId: String) async {
        isLoadingHealthData = true 
        healthDataError = nil
        
        await userSettingsService.fetchSettings(for: userId)
            
        if let healthKit = healthKitManager, healthKit.authorizationStatus == .sharingAuthorized {
            print("[HomeViewModel] HealthKit is authorized. Fetching data.")
            // Data will be automatically updated via publishers
        } else if let healthKit = healthKitManager, healthKit.authorizationStatus == .sharingDenied {
            print("[HomeViewModel] HealthKit permission previously denied.")
            await hydrationService.fetchTodayEntries(for: userId)
            if self.todayWaterMl == 0 { 
                 self.todayWaterMl = hydrationService.todayTotal
            }
        } else {
            print("[HomeViewModel] HealthKit permission not yet determined. Banner should be showing.")
            await hydrationService.fetchTodayEntries(for: userId)
            if self.todayWaterMl == 0 {
                 self.todayWaterMl = hydrationService.todayTotal
            }
        }
        
        isLoadingHealthData = false
    }
    
    func requestHealthKitPermission() {
        print("[HomeViewModel] Requesting HealthKit permission...")
        Task {
            await healthKitManager?.requestAuthorization()
            if healthKitManager?.authorizationStatus == .sharingAuthorized {
                print("[HomeViewModel] HealthKit permission granted!")
                showHealthDataBanner = false
                if let userId = getCurrentUserId() {
                    await loadTodayData(for: userId)
                }
            } else {
                print("[HomeViewModel] HealthKit permission denied.")
                healthDataError = "HealthKit access is required to display your health data. Please enable it in Settings > Health > Data Access & Devices > FitConnect"
                showHealthDataBanner = true
            }
        }
    }
    
    private func getCurrentUserId() -> String? {
        return nil 
    }
    
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning!"
        case 12..<17:
            return "Good Afternoon!"
        case 17..<22:
            return "Good Evening!"
        default:
            return "Good Night!"
        }
    }
}
