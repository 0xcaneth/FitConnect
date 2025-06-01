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

    @Published var stepCount: Double = 0 {
        didSet {
            print("[HealthKitManager] stepCount didSet: \(stepCount)")
            updateUserChallengeProgress(for: .steps, value: stepCount)
            checkAndAwardTenKStepsBadge(steps: stepCount)
        }
    }
    @Published var activeEnergyBurned: Double = 0 {
        didSet {
            print("[HealthKitManager] activeEnergyBurned didSet: \(activeEnergyBurned)")
            updateUserChallengeProgress(for: .count, value: activeEnergyBurned)
            checkAndAward500KcalBadge(kcal: activeEnergyBurned)
        }
    }
    @Published var waterIntake: Double = 0 { // Liters
        didSet {
            print("[HealthKitManager] waterIntake didSet: \(waterIntake)")
            updateUserChallengeProgress(for: .water, value: waterIntake)
            checkAndAward2LWaterBadge(liters: waterIntake)
        }
    }
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

    private func updateUserChallengeProgress(for challengeUnitType: ChallengeUnit, value: Double) {
        guard let userId = Auth.auth().currentUser?.uid, !userId.isEmpty else {
            print("[ChallengeUpdate] User not logged in, cannot update challenge progress.")
            return
        }
        print("[ChallengeUpdate] Attempting to update challenges for userId: \(userId), unit: \(challengeUnitType.rawValue), value: \(value)")

        let db = Firestore.firestore()
        let userChallengesRef = db.collection("userChallenges").document(userId).collection("challenges")
        
        userChallengesRef
            .whereField("challengeUnit", isEqualTo: challengeUnitType.rawValue)
            .whereField("isCompleted", isEqualTo: false)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("[ChallengeUpdate][Error] Error fetching user challenges for unit \(challengeUnitType.rawValue): \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    print("[ChallengeUpdate] No active, non-completed user challenges found for unit \(challengeUnitType.rawValue).")
                    return
                }
                
                print("[ChallengeUpdate] Found \(documents.count) challenges to update for unit \(challengeUnitType.rawValue).")

                for document in documents {
                    let data = document.data()
                    print("[ChallengeUpdate] Raw data for doc \(document.documentID) in HKM: \(data)")

                    // Attempt to decode directly using Codable, which is simpler
                    // Firestore's `data(as:)` method will use the Codable conformance.
                    var userChallenge: UserChallenge
                    do {
                        userChallenge = try document.data(as: UserChallenge.self)
                        // Ensure the id from @DocumentID is populated if it wasn't already by data(as:)
                        // For safety, though usually data(as:) populates it when @DocumentID is present.
                        if userChallenge.id == nil {
                             userChallenge.id = document.documentID
                        }
                    } catch {
                        print("[ChallengeUpdate][Error] Failed to decode UserChallenge for document \(document.documentID) using data(as:): \(error.localizedDescription). Data: \(data)")
                        // Fallback to manual parsing if direct decoding fails, though this shouldn't be necessary
                        // with a correctly conformed Codable struct. For now, let's log and continue.
                        continue
                    }
                    
                    // Ensure we have an ID for the challenge document
                    guard let challengeDocId = userChallenge.id, !challengeDocId.isEmpty else {
                        print("[ChallengeUpdate][Error] Decoded UserChallenge for \(document.documentID) is missing its 'id'. Skipping.")
                        continue
                    }
                                        
                    let newProgress = value 
                    let target = userChallenge.challengeTargetValue ?? Double.infinity

                    print("[ChallengeUpdate] For challenge '\(userChallenge.challengeTitle ?? challengeDocId)', current progress: \(userChallenge.progressValue), new HealthKit value: \(newProgress), target: \(target)")

                    if newProgress != userChallenge.progressValue || (newProgress >= target && !userChallenge.isCompleted) {
                        userChallenge.progressValue = newProgress
                        userChallenge.lastUpdated = Timestamp(date: Date())

                        if newProgress >= target && !userChallenge.isCompleted {
                            userChallenge.isCompleted = true
                            userChallenge.completedDate = Timestamp(date: Date())
                            print("[ChallengeUpdate] Challenge '\(userChallenge.challengeTitle ?? challengeDocId)' COMPLETED by user \(userId)!")
                            self.awardXP(forUserId: userId, xpAmount: 50) // Assuming xpAmount is an Int
                        }
                        
                        do {
                            try userChallengesRef.document(challengeDocId).setData(from: userChallenge, merge: true) { err in
                                if let err = err {
                                    print("[ChallengeUpdate][Error] Error updating user challenge \(challengeDocId): \(err.localizedDescription)")
                                } else {
                                    print("[ChallengeUpdate] User challenge \(challengeDocId) progress updated to \(newProgress). IsCompleted: \(userChallenge.isCompleted).")
                                }
                            }
                        } catch {
                             print("[ChallengeUpdate][Error] Error encoding UserChallenge for Firestore update: \(error.localizedDescription)")
                        }
                    } else {
                        print("[ChallengeUpdate] No significant progress change for challenge '\(userChallenge.challengeTitle ?? challengeDocId)'. Current: \(userChallenge.progressValue), New: \(newProgress)")
                    }
                }
            }
    }

    func awardXP(forUserId userId: String, xpAmount: Int) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        // Atomically increment the user's XP
        userRef.updateData([
            "xp": FieldValue.increment(Int64(xpAmount))
        ]) { error in
            if let error = error {
                print("[XP Award][Error] Error awarding \(xpAmount) XP to user \(userId): \(error.localizedDescription)")
            } else {
                print("[XP Award] Successfully awarded \(xpAmount) XP to user \(userId). Their XP will be updated in Firestore.")
            }
        }
    }

    private func checkAndAwardTenKStepsBadge(steps: Double) {
        guard steps >= 10000 else { return }
        awardDailyBadge(
            badgeKey: "10kStepsDaily",
            badgeName: "10k Steps Daily",
            description: "Achieved 10,000 steps today!",
            iconName: "figure.walk.circle.fill",
            xpReward: 25
        )
    }
    
    private func checkAndAward500KcalBadge(kcal: Double) {
        guard kcal >= 500 else { return }
        awardDailyBadge(
            badgeKey: "500KcalDaily",
            badgeName: "500 kcal Burn",
            description: "Burned 500+ calories today!",
            iconName: "flame.circle.fill",
            xpReward: 30
        )
    }
    
    private func checkAndAward2LWaterBadge(liters: Double) {
        guard liters >= 2.0 else { return }
        awardDailyBadge(
            badgeKey: "2LWaterDaily",
            badgeName: "2L Water Hero",
            description: "Drank 2+ liters of water today!",
            iconName: "drop.circle.fill",
            xpReward: 20
        )
    }
    
    private func awardDailyBadge(badgeKey: String, badgeName: String, description: String, iconName: String, xpReward: Int) {
        guard let userId = Auth.auth().currentUser?.uid, !userId.isEmpty else {
            print("[BadgeAward] User not logged in, cannot award badge.")
            return
        }

        let db = Firestore.firestore()
        let today = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: today)
        
        let badgeId = "\(badgeKey)_\(dateString)"
        let badgeRef = db.collection("users").document(userId).collection("badges").document(badgeId)

        badgeRef.getDocument { documentSnapshot, error in
            if let error = error {
                print("[BadgeAward] Error checking for badge \(badgeId): \(error.localizedDescription)")
                return
            }

            if let document = documentSnapshot, document.exists {
                print("[BadgeAward] Badge '\(badgeId)' already awarded to user \(userId) today.")
                return
            } else {
                // Badge not awarded today, let's award it
                let newBadge = Badge(
                    id: badgeId,
                    badgeName: badgeName,
                    description: description,
                    iconName: iconName,
                    earnedAt: Timestamp(date: today),
                    userId: userId
                )

                do {
                    try badgeRef.setData(from: newBadge) { err in
                        if let err = err {
                            print("[BadgeAward][Error] Failed to award badge \(badgeId): \(err.localizedDescription)")
                        } else {
                            print("[BadgeAward] Successfully awarded badge '\(newBadge.badgeName)' (\(badgeId)) to user \(userId).")
                            // TODO: Create a feed post for this badge award (Requirement 5.b)
                            // self.createBadgeFeedPost(userId: userId, badgeName: newBadge.badgeName, badgeIcon: newBadge.iconName)
                            
                            // Award XP for earning a badge
                            self.awardXP(forUserId: userId, xpAmount: xpReward)
                        }
                    }
                } catch {
                    print("[BadgeAward][Error] Could not encode badge \(badgeId) for Firestore: \(error.localizedDescription)")
                }
            }
        }
    }
}
