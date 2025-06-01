import Foundation
import HealthKit
import FirebaseFirestore
import FirebaseAuth

class HealthKitManager: ObservableObject {
    let healthStore = HKHealthStore()

    // Define the data types we want to read from HealthKit
    let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .dietaryWater)!
    ]

    @Published var stepCount: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var waterIntake: Double = 0
    @Published var isAuthorized: Bool = false
    @Published var permissionStatusDetermined: Bool = false // To track if user has made a choice

    init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            self.permissionStatusDetermined = true // No HealthKit, so consider it determined
            self.isAuthorized = false
            return
        }

        healthStore.getRequestStatusForAuthorization(toShare: [], read: readTypes) { [weak self] (status, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print("Error checking HealthKit authorization status: \(error.localizedDescription)")
                    self.permissionStatusDetermined = true // Error occurred, treat as determined for UI
                    self.isAuthorized = false
                    return
                }

                switch status {
                case .unnecessary:
                    // Permissions already granted or not required for some types (shouldn't happen for read types)
                    print("HealthKit authorization unnecessary (already granted or not required).")
                    self.isAuthorized = true
                    self.permissionStatusDetermined = true
                    self.fetchAllTodayData()
                case .shouldRequest:
                    print("HealthKit authorization should be requested.")
                    self.isAuthorized = false
                    self.permissionStatusDetermined = false // Will be determined after request
                case .unknown:
                    print("HealthKit authorization status unknown.")
                    self.isAuthorized = false
                    self.permissionStatusDetermined = false // Will be determined after request
                @unknown default:
                    print("HealthKit authorization status is an unknown new case.")
                    self.isAuthorized = false
                    self.permissionStatusDetermined = false
                }
            }
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device.")
            DispatchQueue.main.async {
                self.permissionStatusDetermined = true
                self.isAuthorized = false
            }
            completion(false, NSError(domain: "com.fitconnect.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] (success, error) in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(false, error)
                    return
                }
                self.permissionStatusDetermined = true
                self.isAuthorized = success
                if success {
                    print("HealthKit authorization granted.")
                    self.fetchAllTodayData()
                } else {
                    print("HealthKit authorization denied or error: \(error?.localizedDescription ?? "Unknown error")")
                }
                completion(success, error)
            }
        }
    }

    func fetchAllTodayData() {
        if isAuthorized {
            fetchTodayStepCount()
            fetchTodayActiveEnergy()
            fetchTodayWaterIntake()
        }
    }

    private func fetchQuantityData(for typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, completion: @escaping (Double) -> Void) {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: typeIdentifier) else {
            print("Unable to create quantity type for \(typeIdentifier.rawValue)")
            completion(0)
            return
        }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            DispatchQueue.main.async {
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error = error {
                        print("Failed to fetch \(typeIdentifier.rawValue): \(error.localizedDescription)")
                    } else {
                        print("No data for \(typeIdentifier.rawValue) today.")
                    }
                    completion(0)
                    return
                }
                completion(sum.doubleValue(for: unit))
            }
        }
        healthStore.execute(query)
    }

    func fetchTodayStepCount() {
        fetchQuantityData(for: .stepCount, unit: .count()) { [weak self] steps in
            self?.stepCount = steps
            print("Fetched steps: \(steps)")
            self?.saveHealthDataToFirestore(dataType: "steps", value: steps)
        }
    }

    func fetchTodayActiveEnergy() {
        fetchQuantityData(for: .activeEnergyBurned, unit: .kilocalorie()) { [weak self] energy in
            self?.activeEnergyBurned = energy
            print("Fetched active energy: \(energy) kcal")
            self?.saveHealthDataToFirestore(dataType: "activeEnergy", value: energy)
        }
    }

    func fetchTodayWaterIntake() {
        fetchQuantityData(for: .dietaryWater, unit: .liter()) { [weak self] water in
            // Convert Liters to Milliliters if your UI/backend expects mL, or keep as L
            // For this example, keeping as Liters.
            self?.waterIntake = water
            print("Fetched water intake: \(water) L")
            self?.saveHealthDataToFirestore(dataType: "water", value: water)
        }
    }
    
    func saveHealthDataToFirestore(dataType: String, value: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User not logged in, cannot save health data.")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let db = Firestore.firestore()
        let healthDataRef = db.collection("users").document(userId).collection("healthData").document(dateString)
        
        // Use serverTimestamp for consistent timing if needed, or just update the specific field
        // Using merge to avoid overwriting other fields for the same day
        healthDataRef.setData([dataType: value, "lastUpdated": FieldValue.serverTimestamp()], merge: true) { error in
            if let error = error {
                print("Error saving \(dataType) to Firestore: \(error.localizedDescription)")
            } else {
                print("\(dataType) successfully saved to Firestore for \(dateString).")
            }
        }
    }
}