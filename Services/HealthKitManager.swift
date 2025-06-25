import Foundation
import HealthKit
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Enhanced HealthKitManager with comprehensive data capture and Firestore integration
@MainActor
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    // MARK: - Published Properties
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Current day metrics
    @Published var stepCount: Int = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var waterIntake: Double = 0
    @Published var weight: Double = 0
    @Published var height: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var restingHeartRate: Int = 0
    @Published var bloodPressureSystolic: Int = 0
    @Published var bloodPressureDiastolic: Int = 0
    @Published var sleepHours: Double = 0
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var observers: [HKObserverQuery] = []
    private var sessionStore: SessionStore?
    
    // Data types we want to read
    private let typesToRead: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .dietaryWater)!,
        HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
        HKQuantityType.quantityType(forIdentifier: .height)!,
        HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
        HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
        HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
    ]
    
    // MARK: - Initialization
    init(sessionStore: SessionStore? = nil) {
        self.sessionStore = sessionStore
        checkInitialAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request HealthKit authorization for all data types
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await setError("HealthKit is not available on this device")
            return
        }
        
        isLoading = true
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await updateAuthorizationStatus()
            
            if isAuthorized {
                await startDataCollection()
                UserDefaults.standard.set(true, forKey: "healthKitEnabled")
            }
        } catch {
            await setError("Failed to request HealthKit authorization: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Check if we should show the HealthKit banner
    var shouldShowHealthKitBanner: Bool {
        !UserDefaults.standard.bool(forKey: "healthKitEnabled") && authorizationStatus != .sharingAuthorized
    }
    
    /// Get current step count
    func getStepCount() -> Int {
        return stepCount
    }
    
    // MARK: - Private Methods
    
    private func checkInitialAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        if let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
            isAuthorized = authorizationStatus == .sharingAuthorized
            
            if isAuthorized {
                Task {
                    await startDataCollection()
                }
            }
        }
    }
    
    private func updateAuthorizationStatus() async {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        authorizationStatus = healthStore.authorizationStatus(for: stepCountType)
        isAuthorized = authorizationStatus == .sharingAuthorized
    }
    
    private func startDataCollection() async {
        await fetchCurrentDayData()
        await setupObservers()
    }
    
    private func fetchCurrentDayData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchStepCount() }
            group.addTask { await self.fetchActiveEnergyBurned() }
            group.addTask { await self.fetchWaterIntake() }
            group.addTask { await self.fetchLatestWeight() }
            group.addTask { await self.fetchLatestHeight() }
            group.addTask { await self.fetchLatestBodyFatPercentage() }
            group.addTask { await self.fetchLatestRestingHeartRate() }
            group.addTask { await self.fetchLatestBloodPressure() }
            group.addTask { await self.fetchSleepData() }
        }
    }
    
    // MARK: - Data Fetching Methods
    
    private func fetchStepCount() async {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching step count: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume()
                        return
                    }
                    
                    let steps = Int(sum.doubleValue(for: HKUnit.count()))
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self?.stepCount = steps
                    }
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "steps", value: Double(steps), unit: "count")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchActiveEnergyBurned() async {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching active energy: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume()
                        return
                    }
                    
                    let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self?.activeEnergyBurned = calories
                    }
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "activeEnergyBurned", value: calories, unit: "kcal")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchWaterIntake() async {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: waterType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching water intake: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let result = result, let sum = result.sumQuantity() else {
                        continuation.resume()
                        return
                    }
                    
                    let water = sum.doubleValue(for: HKUnit.literUnit(with: .milli))
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self?.waterIntake = water
                    }
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "waterIntake", value: water, unit: "ml")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestWeight() async {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching weight: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume()
                        return
                    }
                    
                    let weightValue = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                    self?.weight = weightValue
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "weight", value: weightValue, unit: "kg", timestamp: sample.startDate)
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestHeight() async {
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching height: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume()
                        return
                    }
                    
                    let heightValue = sample.quantity.doubleValue(for: HKUnit.meterUnit(with: .centi))
                    self?.height = heightValue
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "height", value: heightValue, unit: "cm", timestamp: sample.startDate)
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestBodyFatPercentage() async {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyFatType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching body fat percentage: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume()
                        return
                    }
                    
                    let bodyFatValue = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
                    self?.bodyFatPercentage = bodyFatValue
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "bodyFatPercentage", value: bodyFatValue, unit: "percent", timestamp: sample.startDate)
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestRestingHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching resting heart rate: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume()
                        return
                    }
                    
                    let heartRateValue = Int(sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                    self?.restingHeartRate = heartRateValue
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "restingHeartRate", value: Double(heartRateValue), unit: "bpm", timestamp: sample.startDate)
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchLatestBloodPressure() async {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: systolicType,
                        predicate: nil,
                        limit: 1,
                        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                    ) { [weak self] _, samples, error in
                        Task { @MainActor in
                            if let error = error {
                                print("Error fetching systolic blood pressure: \(error)")
                                continuation.resume()
                                return
                            }
                            
                            guard let sample = samples?.first as? HKQuantitySample else {
                                continuation.resume()
                                return
                            }
                            
                            let systolicValue = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                            self?.bloodPressureSystolic = systolicValue
                            
                            // Save to Firestore
                            await self?.saveHealthDataToFirestore(type: "bloodPressureSystolic", value: Double(systolicValue), unit: "mmHg", timestamp: sample.startDate)
                            continuation.resume()
                        }
                    }
                    
                    self.healthStore.execute(query)
                }
            }
            
            group.addTask {
                await withCheckedContinuation { continuation in
                    let query = HKSampleQuery(
                        sampleType: diastolicType,
                        predicate: nil,
                        limit: 1,
                        sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                    ) { [weak self] _, samples, error in
                        Task { @MainActor in
                            if let error = error {
                                print("Error fetching diastolic blood pressure: \(error)")
                                continuation.resume()
                                return
                            }
                            
                            guard let sample = samples?.first as? HKQuantitySample else {
                                continuation.resume()
                                return
                            }
                            
                            let diastolicValue = Int(sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury()))
                            self?.bloodPressureDiastolic = diastolicValue
                            
                            // Save to Firestore
                            await self?.saveHealthDataToFirestore(type: "bloodPressureDiastolic", value: Double(diastolicValue), unit: "mmHg", timestamp: sample.startDate)
                            continuation.resume()
                        }
                    }
                    
                    self.healthStore.execute(query)
                }
            }
        }
    }
    
    private func fetchSleepData() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            end: Date(),
            options: .strictStartDate
        )
        
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, error in
                Task { @MainActor in
                    if let error = error {
                        print("Error fetching sleep data: \(error)")
                        continuation.resume()
                        return
                    }
                    
                    guard let samples = samples as? [HKCategorySample] else {
                        continuation.resume()
                        return
                    }
                    
                    let sleepSamples = samples.filter { sample in
                        sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                    }
                    
                    let totalSleepTime = sleepSamples.reduce(0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    
                    let sleepHours = totalSleepTime / 3600 // Convert seconds to hours
                    self?.sleepHours = sleepHours
                    
                    // Save to Firestore
                    await self?.saveHealthDataToFirestore(type: "sleepHours", value: sleepHours, unit: "hours")
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Observer Setup
    
    private func setupObservers() async {
        // Clear existing observers
        observers.forEach { healthStore.stop($0) }
        observers.removeAll()
        
        let identifiers: [HKQuantityTypeIdentifier] = [
            .stepCount, .activeEnergyBurned, .dietaryWater, .bodyMass, .height,
            .bodyFatPercentage, .restingHeartRate, .bloodPressureSystolic, .bloodPressureDiastolic
        ]
        
        for identifier in identifiers {
            await setupObserver(for: identifier)
        }
        
        // Setup sleep observer
        await setupSleepObserver()
    }
    
    private func setupObserver(for identifier: HKQuantityTypeIdentifier) async {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        
        let query = HKObserverQuery(sampleType: quantityType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Observer query error for \(identifier): \(error)")
                return
            }
            
            Task { @MainActor in
                // Fetch updated data based on type
                switch identifier {
                case .stepCount:
                    await self?.fetchStepCount()
                case .activeEnergyBurned:
                    await self?.fetchActiveEnergyBurned()
                case .dietaryWater:
                    await self?.fetchWaterIntake()
                case .bodyMass:
                    await self?.fetchLatestWeight()
                case .height:
                    await self?.fetchLatestHeight()
                case .bodyFatPercentage:
                    await self?.fetchLatestBodyFatPercentage()
                case .restingHeartRate:
                    await self?.fetchLatestRestingHeartRate()
                case .bloodPressureSystolic, .bloodPressureDiastolic:
                    await self?.fetchLatestBloodPressure()
                default:
                    break
                }
            }
        }
        
        observers.append(query)
        healthStore.execute(query)
        
        // Enable background delivery
        do {
            try await healthStore.enableBackgroundDelivery(for: quantityType, frequency: .immediate)
        } catch {
            print("Error enabling background delivery for \(identifier): \(error)")
        }
    }
    
    private func setupSleepObserver() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Sleep observer query error: \(error)")
                return
            }
            
            Task { @MainActor in
                await self?.fetchSleepData()
            }
        }
        
        observers.append(query)
        healthStore.execute(query)
        
        // Enable background delivery
        do {
            try await healthStore.enableBackgroundDelivery(for: sleepType, frequency: .immediate)
        } catch {
            print("Error enabling background delivery for sleep: \(error)")
        }
    }
    
    // MARK: - Firestore Integration
    
    /// Save health data to Firestore with proper structure
    private func saveHealthDataToFirestore(type: String, value: Double, unit: String, timestamp: Date = Date()) async {
        guard let userId = getCurrentUserId() else {
            print("No user ID available for saving health data")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: timestamp)
        
        let healthDataDocument: [String: Any] = [
            "type": type,
            "value": value,
            "unit": unit,
            "timestamp": Timestamp(date: timestamp),
            "source": "HealthKit",
            "uuid": UUID().uuidString
        ]
        
        do {
            try await db
                .collection("users")
                .document(userId)
                .collection("healthData")
                .document(dateString)
                .collection("healthkit")
                .document(UUID().uuidString)
                .setData(healthDataDocument)
            
            print("Successfully saved \(type): \(value) \(unit) to Firestore")
        } catch {
            print("Error saving \(type) to Firestore: \(error)")
        }
    }
    
    private func getCurrentUserId() -> String? {
        if let sessionStore = sessionStore {
            return sessionStore.currentUserId
        }
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Error Handling
    
    private func setError(_ message: String) async {
        error = message
        print("HealthKitManager Error: \(message)")
    }
    
    /// Clear any errors
    func clearError() {
        error = nil
    }
    
    // MARK: - Public Data Access
    
    /// Get current health data snapshot
    func getCurrentHealthDataSnapshot() -> HealthDataSnapshot {
        return HealthDataSnapshot(
            stepCount: stepCount,
            activeEnergyBurned: activeEnergyBurned,
            waterIntake: waterIntake,
            weight: weight > 0 ? weight : nil,
            height: height > 0 ? height : nil,
            bodyFatPercentage: bodyFatPercentage > 0 ? bodyFatPercentage : nil,
            restingHeartRate: restingHeartRate > 0 ? restingHeartRate : nil,
            bloodPressureSystolic: bloodPressureSystolic > 0 ? bloodPressureSystolic : nil,
            bloodPressureDiastolic: bloodPressureDiastolic > 0 ? bloodPressureDiastolic : nil,
            sleepHours: sleepHours > 0 ? sleepHours : nil
        )
    }
    
    deinit {
        // Clean up observers
        observers.forEach { healthStore.stop($0) }
    }
}

// MARK: - Supporting Types

/// Snapshot of current health data
struct HealthDataSnapshot {
    let stepCount: Int
    let activeEnergyBurned: Double
    let waterIntake: Double
    let weight: Double?
    let height: Double?
    let bodyFatPercentage: Double?
    let restingHeartRate: Int?
    let bloodPressureSystolic: Int?
    let bloodPressureDiastolic: Int?
    let sleepHours: Double?
    
    /// Calculate BMI if height and weight are available
    var bmi: Double? {
        guard let weight = weight, let height = height, height > 0 else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
}
