import Foundation
import HealthKit
import Combine
import SwiftUI

@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var stepCount: Int = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var waterIntake: Double = 0
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    @Published var weight: Double = 0
    @Published var height: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var restingHeartRate: Int = 0
    @Published var bloodPressureSystolic: Int = 0
    @Published var bloodPressureDiastolic: Int = 0
    
    private let healthStore = HKHealthStore()
    private var sessionStore: SessionStore?
    
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKQuantityType.quantityType(forIdentifier: .height)!,
        HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!
    ]
    
    init(sessionStore: SessionStore? = nil) {
        self.sessionStore = sessionStore
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Check authorization for step count as representative
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
            
            if authorizationStatus == .sharingAuthorized {
                fetchTodaysData()
            }
        }
    }
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            
            // Update authorization status
            if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
                authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
                
                if authorizationStatus == .sharingAuthorized {
                    fetchTodaysData()
                    setupBackgroundObservers()
                }
            }
        } catch {
            print("Error requesting HealthKit authorization: \(error)")
        }
    }
    
    func getStepCount() -> Int {
        return stepCount
    }
    
    private func fetchTodaysData() {
        fetchStepCount()
        fetchActiveEnergyBurned()
        fetchWaterIntake()
        fetchLatestWeight()
        fetchLatestHeight()
        fetchLatestBodyFatPercentage()
        fetchLatestRestingHeartRate()
        fetchLatestBloodPressure()
    }
    
    private func fetchStepCount() {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching step count: \(error)")
                }
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            Task { @MainActor in
                SwiftUI.withAnimation(.easeInOut(duration: 1.0)) {
                    self?.stepCount = steps
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveEnergyBurned() {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching active energy: \(error)")
                }
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            
            Task { @MainActor in
                SwiftUI.withAnimation(.easeInOut(duration: 1.0)) {
                    self?.activeEnergyBurned = calories
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWaterIntake() {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: waterType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                if let error = error {
                    print("Error fetching water intake: \(error)")
                }
                return
            }
            
            let water = sum.doubleValue(for: HKUnit.literUnit(with: .milli))
            
            Task { @MainActor in
                SwiftUI.withAnimation(.easeInOut(duration: 1.0)) {
                    self?.waterIntake = water
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestWeight() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching weight: \(error)")
                }
                return
            }
            
            let weightValue = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            
            Task { @MainActor in
                self?.weight = weightValue
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHeight() {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { return }
        
        let query = HKSampleQuery(
            sampleType: heightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching height: \(error)")
                }
                return
            }
            
            let heightValue = sample.quantity.doubleValue(for: HKUnit.meterUnit(with: .centi))
            
            Task { @MainActor in
                self?.height = heightValue
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBodyFatPercentage() {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let query = HKSampleQuery(
            sampleType: bodyFatType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching body fat percentage: \(error)")
                }
                return
            }
            
            let bodyFatValue = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            
            Task { @MainActor in
                self?.bodyFatPercentage = bodyFatValue
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestRestingHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching resting heart rate: \(error)")
                }
                return
            }
            
            let heartRateValue = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            
            Task { @MainActor in
                self?.restingHeartRate = heartRateValue
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBloodPressure() {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        // Fetch systolic
        let systolicQuery = HKSampleQuery(
            sampleType: systolicType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching systolic blood pressure: \(error)")
                }
                return
            }
            
            let systolicValue = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            
            Task { @MainActor in
                self?.bloodPressureSystolic = systolicValue
            }
        }
        
        // Fetch diastolic
        let diastolicQuery = HKSampleQuery(
            sampleType: diastolicType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else {
                if let error = error {
                    print("Error fetching diastolic blood pressure: \(error)")
                }
                return
            }
            
            let diastolicValue = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
            
            Task { @MainActor in
                self?.bloodPressureDiastolic = diastolicValue
            }
        }
        
        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
    }
    
    private func setupBackgroundObservers() {
        // Setup background observers for real-time updates
        setupObserver(for: .stepCount) { [weak self] in
            self?.fetchStepCount()
        }
        
        setupObserver(for: .activeEnergyBurned) { [weak self] in
            self?.fetchActiveEnergyBurned()
        }
        
        setupObserver(for: .dietaryWater) { [weak self] in
            self?.fetchWaterIntake()
        }
        
        setupObserver(for: .bodyMass) { [weak self] in
            self?.fetchLatestWeight()
        }
        
        setupObserver(for: .height) { [weak self] in
            self?.fetchLatestHeight()
        }
        
        setupObserver(for: .bodyFatPercentage) { [weak self] in
            self?.fetchLatestBodyFatPercentage()
        }
        
        setupObserver(for: .restingHeartRate) { [weak self] in
            self?.fetchLatestRestingHeartRate()
        }
        
        setupObserver(for: .bloodPressureSystolic) { [weak self] in
            self?.fetchLatestBloodPressure()
        }
        
        setupObserver(for: .bloodPressureDiastolic) { [weak self] in
            self?.fetchLatestBloodPressure()
        }
    }
    
    private func setupObserver(for identifier: HKQuantityTypeIdentifier, updateHandler: @escaping () -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        
        let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { _, _, error in
            if let error = error {
                print("Observer query error for \(identifier): \(error)")
                return
            }
            
            DispatchQueue.main.async {
                updateHandler()
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate) { success, error in
            if let error = error {
                print("Error enabling background delivery for \(identifier): \(error)")
            }
        }
    }
    
    func getCurrentHealthData() -> (weight: Double?, height: Double?, bodyFat: Double?, heartRate: Int?, systolic: Int?, diastolic: Int?) {
        return (
            weight: weight > 0 ? weight : nil,
            height: height > 0 ? height : nil,
            bodyFat: bodyFatPercentage > 0 ? bodyFatPercentage : nil,
            heartRate: restingHeartRate > 0 ? restingHeartRate : nil,
            systolic: bloodPressureSystolic > 0 ? bloodPressureSystolic : nil,
            diastolic: bloodPressureDiastolic > 0 ? bloodPressureDiastolic : nil
        )
    }
}
