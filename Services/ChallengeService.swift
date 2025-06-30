import Foundation
import FirebaseFirestore
import FirebaseAuth
import HealthKit
import UserNotifications

@MainActor
class ChallengeService: ObservableObject {
    private let db = Firestore.firestore()
    private let healthStore = HKHealthStore()
    
    @Published var availableChallenges: [Challenge] = []
    @Published var activeChallenges: [UserChallenge] = []
    @Published var completedChallenges: [UserChallenge] = []
    @Published var leaderboards: [String: [LeaderboardEntry]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var challengeListeners: [ListenerRegistration] = []
    
    static let shared = ChallengeService()
    
    private init() {
        Task {
            await setupHealthKitObservation()
        }
    }
    
    // MARK: - Public Interface
    
    func startService(for userId: String) {
        removeAllListeners()
        fetchAvailableChallenges()
        fetchUserChallenges(userId: userId)
        setupRealtimeListeners(userId: userId)
    }
    
    func stopService() {
        removeAllListeners()
        availableChallenges.removeAll()
        activeChallenges.removeAll()
        completedChallenges.removeAll()
        leaderboards.removeAll()
    }
    
    // MARK: - Challenge Management
    
    func joinChallenge(_ challenge: Challenge, userId: String) async throws {
        guard let challengeId = challenge.id else {
            throw ChallengeError.invalidChallengeId
        }
        
        let userChallenge = UserChallenge(
            challengeId: challengeId,
            userId: userId,
            progressValue: 0.0,
            isCompleted: false,
            completedDate: nil,
            joinedDate: Timestamp(date: Date()),
            lastUpdated: Timestamp(date: Date()),
            challengeTitle: challenge.title,
            challengeDescription: challenge.description,
            challengeTargetValue: challenge.targetValue,
            challengeUnit: challenge.unit.rawValue
        )
        
        try await db.collection("userChallenges")
            .document(userId)
            .collection("challenges")
            .document(challengeId)
            .setData(from: userChallenge)
        
        // Update challenge participant count
        try await db.collection("challenges")
            .document(challengeId)
            .updateData([
                "participantCount": FieldValue.increment(Int64(1)),
                "lastUpdated": Timestamp(date: Date())
            ])
        
        // Award XP for joining
        try await awardXP(userId: userId, amount: 10, source: "challenge_joined")
        
        // Schedule notification
        scheduleProgressReminder(for: challenge, userId: userId)
        
        print("[ChallengeService] Successfully joined challenge: \(challenge.title)")
    }
    
    func leaveChallenge(_ challengeId: String, userId: String) async throws {
        try await db.collection("userChallenges")
            .document(userId)
            .collection("challenges")
            .document(challengeId)
            .delete()
        
        // Update challenge participant count
        try await db.collection("challenges")
            .document(challengeId)
            .updateData([
                "participantCount": FieldValue.increment(Int64(-1)),
                "lastUpdated": Timestamp(date: Date())
            ])
        
        // Cancel notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["challenge_\(challengeId)"])
        
        print("[ChallengeService] Successfully left challenge: \(challengeId)")
    }
    
    func updateProgress(_ challengeId: String, userId: String, newProgress: Double) async throws {
        let challengeRef = db.collection("userChallenges")
            .document(userId)
            .collection("challenges")
            .document(challengeId)
        
        // Get current challenge data
        let snapshot = try await challengeRef.getDocument()
        var userChallenge = try snapshot.data(as: UserChallenge.self)
        
        let oldProgress = userChallenge.progressValue
        userChallenge.progressValue = newProgress
        userChallenge.lastUpdated = Timestamp(date: Date())
        
        // Check if challenge is completed
        let targetValue = userChallenge.challengeTargetValue ?? 0
        if newProgress >= targetValue && !userChallenge.isCompleted {
            userChallenge.isCompleted = true
            userChallenge.completedDate = Timestamp(date: Date())
            
            // Award completion XP
            try await awardXP(userId: userId, amount: 100, source: "challenge_completed")
            
            // Create achievement badge
            try await createCompletionBadge(userId: userId, challenge: userChallenge)
            
            // Send completion notification
            sendCompletionNotification(for: userChallenge)
        }
        
        // Update progress
        try challengeRef.setData(from: userChallenge)
        
        // Update leaderboard
        try await updateLeaderboard(challengeId: challengeId, userId: userId, progress: newProgress)
        
        print("[ChallengeService] Updated progress for \(challengeId): \(oldProgress) -> \(newProgress)")
    }
    
    // MARK: - Data Fetching
    
    private func fetchAvailableChallenges() {
        isLoading = true
        print("[ChallengeService] 🔍 Starting to fetch available challenges...")
        
        db.collection("challenges")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("[ChallengeService] ❌ Error fetching challenges: \(error.localizedDescription)")
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[ChallengeService] ⚠️ No documents in snapshot")
                        self.availableChallenges = []
                        self.isLoading = false
                        return
                    }
                    
                    print("[ChallengeService] 📄 Found \(documents.count) documents in challenges collection")
                    
                    // Debug: Print all document IDs and basic data
                    for (index, document) in documents.enumerated() {
                        print("[ChallengeService] Document \(index + 1): ID = \(document.documentID)")
                        let data = document.data()
                        print("  - title: \(data["title"] as? String ?? "N/A")")
                        print("  - isActive: \(data["isActive"] as? Bool ?? false)")
                        print("  - category: \(data["category"] as? String ?? "N/A")")
                        
                        print("  - category field exists: \(data["category"] != nil)")
                        print("  - category key: '\(data.keys.first(where: { $0.contains("category") }) ?? "none")'")
                        print("  - unit field exists: \(data["unit"] != nil)")
                        print("  - unit key: '\(data.keys.first(where: { $0.contains("unit") }) ?? "none")'")
                        print("  - participantCount field exists: \(data["participantCount"] != nil)")
                        print("  - participantCount key: '\(data.keys.first(where: { $0.contains("participant") }) ?? "none")'")
                    }
                    
                    self.availableChallenges = documents.compactMap { document in
                        do {
                            var challenge = try document.data(as: Challenge.self)
                            challenge.id = document.documentID
                            print("[ChallengeService] ✅ Successfully decoded challenge: \(challenge.title)")
                            return challenge
                        } catch {
                            print("[ChallengeService] ❌ Error decoding challenge \(document.documentID): \(error)")
                            let data = document.data()
                            print("  Raw data keys: \(Array(data.keys).sorted())")
                            return nil
                        }
                    }.sorted { $0.createdAt?.dateValue() ?? Date() > $1.createdAt?.dateValue() ?? Date() }
                    
                    self.isLoading = false
                    print("[ChallengeService] 🎯 Final result: Loaded \(self.availableChallenges.count) available challenges")
                    
                    // Print final challenge titles
                    for (index, challenge) in self.availableChallenges.enumerated() {
                        print("  \(index + 1). \(challenge.title) (\(challenge.category.title))")
                    }
                }
            }
    }
    
    private func fetchUserChallenges(userId: String) {
        let userChallengesRef = db.collection("userChallenges")
            .document(userId)
            .collection("challenges")
        
        // Fetch active challenges
        userChallengesRef
            .whereField("isCompleted", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("[ChallengeService] Error fetching active challenges: \(error)")
                        return
                    }
                    
                    self.activeChallenges = snapshot?.documents.compactMap { document in
                        do {
                            return try document.data(as: UserChallenge.self)
                        } catch {
                            print("[ChallengeService] Error decoding active challenge: \(error)")
                            return nil
                        }
                    } ?? []
                    
                    print("[ChallengeService] Loaded \(self.activeChallenges.count) active challenges")
                }
            }
        
        // Fetch completed challenges
        userChallengesRef
            .whereField("isCompleted", isEqualTo: true)
            .order(by: "completedDate", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("[ChallengeService] Error fetching completed challenges: \(error)")
                        return
                    }
                    
                    self.completedChallenges = snapshot?.documents.compactMap { document in
                        do {
                            return try document.data(as: UserChallenge.self)
                        } catch {
                            print("[ChallengeService] Error decoding completed challenge: \(error)")
                            return nil
                        }
                    } ?? []
                    
                    print("[ChallengeService] Loaded \(self.completedChallenges.count) completed challenges")
                }
            }
    }
    
    // MARK: - Leaderboards
    
    func fetchLeaderboard(for challengeId: String) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection("leaderboards")
            .document(challengeId)
            .collection("entries")
            .order(by: "progress", descending: true)
            .limit(to: 100)
            .getDocuments()
        
        let entries = snapshot.documents.compactMap { document -> LeaderboardEntry? in
            do {
                return try document.data(as: LeaderboardEntry.self)
            } catch {
                print("[ChallengeService] Error decoding leaderboard entry: \(error)")
                return nil
            }
        }
        
        self.leaderboards[challengeId] = entries
        return entries
    }
    
    private func updateLeaderboard(challengeId: String, userId: String, progress: Double) async throws {
        // Get user info for leaderboard
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let userData = userDoc.data() ?? [:]
        let userName = userData["fullName"] as? String ?? "Anonymous"
        let userAvatar = userData["profileImageURL"] as? String
        
        let leaderboardEntry = LeaderboardEntry(
            userId: userId,
            userName: userName,
            userAvatar: userAvatar,
            progress: progress,
            lastUpdated: Timestamp(date: Date())
        )
        
        try await db.collection("leaderboards")
            .document(challengeId)
            .collection("entries")
            .document(userId)
            .setData(from: leaderboardEntry)
    }
    
    // MARK: - HealthKit Integration
    
    private func setupHealthKitObservation() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        
        await setupHealthKitObserver(for: stepType, unit: .count()) { steps in
            Task {
                await self.updateChallengeProgress(for: .steps, value: steps)
            }
        }
        
        await setupHealthKitObserver(for: waterType, unit: .liter()) { liters in
            Task {
                await self.updateChallengeProgress(for: .water, value: liters)
            }
        }
        
        await setupHealthKitObserver(for: activeEnergyType, unit: .kilocalorie()) { calories in
            Task {
                await self.updateChallengeProgress(for: .calories, value: calories)
            }
        }
        
        await setupHealthKitObserver(for: exerciseTimeType, unit: .minute()) { minutes in
            Task {
                await self.updateChallengeProgress(for: .minutes, value: minutes)
            }
        }
        
        await setupHealthKitObserver(for: distanceType, unit: .meterUnit(with: .kilo)) { kilometers in
            Task {
                await self.updateChallengeProgress(for: .kilometers, value: kilometers)
            }
        }
    }
    
    private func setupHealthKitObserver(for type: HKQuantityType, unit: HKUnit, completion: @escaping (Double) -> Void) async {
        let query = HKObserverQuery(sampleType: type, predicate: nil) { _, _, error in
            if let error = error {
                print("[ChallengeService] HealthKit observer error: \(error)")
                return
            }
            
            // Get today's data
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            
            let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
            
            let statisticsQuery = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    print("[ChallengeService] HealthKit statistics error: \(error)")
                    return
                }
                
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0.0
                completion(value)
            }
            
            self.healthStore.execute(statisticsQuery)
        }
        
        healthStore.execute(query)
    }
    
    private func updateChallengeProgress(for unit: ChallengeUnit, value: Double) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let matchingChallenges = activeChallenges.filter { $0.challengeUnit == unit.rawValue }
        
        for challenge in matchingChallenges {
            let challengeId = challenge.challengeId
            
            do {
                try await updateProgress(challengeId, userId: userId, newProgress: value)
            } catch {
                print("[ChallengeService] Error updating challenge progress: \(error)")
            }
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleProgressReminder(for challenge: Challenge, userId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Challenge Progress"
        content.body = "Don't forget to work towards your \(challenge.title) challenge!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "challenge_\(challenge.id ?? "")", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[ChallengeService] Error scheduling notification: \(error)")
            }
        }
    }
    
    private func sendCompletionNotification(for challenge: UserChallenge) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Challenge Completed!"
        content.body = "Congratulations! You've completed the \(challenge.challengeTitle ?? "challenge")!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "completion_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[ChallengeService] Error sending completion notification: \(error)")
            }
        }
    }
    
    // MARK: - Rewards & XP
    
    private func awardXP(userId: String, amount: Int, source: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "xp": FieldValue.increment(Int64(amount)),
            "lastXPUpdate": Timestamp(date: Date()),
            "xpSource": source
        ])
        
        print("[ChallengeService] Awarded \(amount) XP to user \(userId) for \(source)")
    }
    
    private func createCompletionBadge(userId: String, challenge: UserChallenge) async throws {
        let badge = Badge(
            badgeName: "\(challenge.challengeTitle ?? "Challenge") Champion",
            description: "Completed the \(challenge.challengeTitle ?? "challenge") challenge",
            iconName: "trophy.fill",
            earnedAt: Timestamp(date: Date()),
            userId: userId
        )
        
        try await db.collection("users")
            .document(userId)
            .collection("badges")
            .addDocument(from: badge)
        
        print("[ChallengeService] Created completion badge for challenge: \(challenge.challengeTitle ?? "Unknown")")
    }
    
    // MARK: - Listeners Management
    
    private func setupRealtimeListeners(userId: String) {
        // Listen to challenge updates for automatic progress sync
        let userChallengesRef = db.collection("userChallenges")
            .document(userId)
            .collection("challenges")
        
        let listener = userChallengesRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("[ChallengeService] Real-time listener error: \(error)")
                return
            }
            
            // Handle real-time updates
            snapshot?.documentChanges.forEach { change in
                switch change.type {
                case .added:
                    print("[ChallengeService] Challenge added: \(change.document.documentID)")
                case .modified:
                    print("[ChallengeService] Challenge modified: \(change.document.documentID)")
                case .removed:
                    print("[ChallengeService] Challenge removed: \(change.document.documentID)")
                }
            }
        }
        
        challengeListeners.append(listener)
    }
    
    private func removeAllListeners() {
        challengeListeners.forEach { $0.remove() }
        challengeListeners.removeAll()
    }
}

// MARK: - Supporting Models

struct LeaderboardEntry: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let userAvatar: String?
    let progress: Double
    let lastUpdated: Timestamp
    
    var rank: Int = 0 // Will be set when fetching leaderboard
}

enum ChallengeError: LocalizedError {
    case invalidChallengeId
    case userNotAuthenticated
    case challengeNotFound
    case alreadyJoined
    case notJoined
    
    var errorDescription: String? {
        switch self {
        case .invalidChallengeId:
            return "Invalid challenge ID"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .challengeNotFound:
            return "Challenge not found"
        case .alreadyJoined:
            return "Already joined this challenge"
        case .notJoined:
            return "Not joined in this challenge"
        }
    }
}

// MARK: - Extensions

extension ChallengeUnit {
    var healthKitType: HKQuantityType? {
        switch self {
        case .steps:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .water:
            return HKQuantityType.quantityType(forIdentifier: .dietaryWater)
        case .count:
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        case .calories:
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        case .minutes:
            return HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
        case .kilometers:
            return HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        }
    }
    
    var healthKitUnit: HKUnit {
        switch self {
        case .steps:
            return .count()
        case .water:
            return .liter()
        case .count:
            return .count()
        case .calories:
            return .kilocalorie()
        case .minutes:
            return .minute()
        case .kilometers:
            return .meterUnit(with: .kilo)
        }
    }
}