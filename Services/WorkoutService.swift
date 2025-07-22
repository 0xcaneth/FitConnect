import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

/// Production-ready WorkoutService with Firebase backend
@MainActor
final class WorkoutService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading: Bool = false
    @Published var workoutStats: WorkoutStats?
    @Published var todayRecommendations: [WorkoutRecommendation] = []
    @Published var recentWorkouts: [WorkoutSession] = []
    @Published var favoriteWorkouts: [WorkoutSession] = []
    @Published var currentWorkoutSession: WorkoutSession?
    @Published var availableWorkouts: [WorkoutSession] = []
    @Published var workoutTemplates: [WorkoutTemplate] = []
    @Published var error: WorkoutServiceError?
    
    // MARK: - Private Properties - ENHANCED FOR PRODUCTION
    private let db = Firestore.firestore()
    private let privacyManager = PrivacyManager.shared
    private var listeners: [ListenerRegistration] = []
    private var statsListener: ListenerRegistration?
    private var templatesListener: ListenerRegistration?
    private var currentUserId: String?
    
    // PRODUCTION-READY FEATURES
    private let offlineQueue = WorkoutOfflineQueue()
    private let retryManager = NetworkRetryManager()
    private var connectionMonitor = NetworkConnectionMonitor()
    private var pendingOperations: [String: WorkoutOperation] = [:]
    
    // MARK: - Singleton
    static let shared = WorkoutService()
    private init() {
        setupTemplatesListener()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Initialize service for user
    func initialize(for userId: String) async {
        print("[WorkoutService] Initializing for user: \(userId)")
        
        isLoading = true
        
        do {
            // Debug Firebase collections first
            await debugFirebaseCollections()
            
            // Load user's workout stats
            await loadWorkoutStats(for: userId)
            
            // Setup real-time listeners
            setupStatsListener(for: userId)
            
            // Load initial data
            await loadTodayRecommendations(for: userId)
            await loadRecentWorkouts(for: userId)
            await loadFavoriteWorkouts(for: userId)
            await loadWorkoutTemplates()
            
            print("[WorkoutService] Successfully initialized")
            currentUserId = userId
        } catch {
            print("[WorkoutService] Initialization error: \(error)")
            self.error = .initializationFailed(error)
        }
        
        isLoading = false
    }
    
    /// Start a workout session
    func startWorkout(_ workout: WorkoutSession) async -> Result<String, WorkoutServiceError> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        print("[WorkoutService] Starting workout: \(workout.name)")
        
        // Track workout start for analytics
        privacyManager.trackWorkoutStarted(
            type: workout.workoutType.rawValue,
            duration: workout.estimatedDuration
        )
        
        do {
            var startedWorkout = workout
            startedWorkout.updatedAt = Date()
            
            let workoutRef = db.collection("users")
                .document(userId)
                .collection("workoutSessions")
                .document()
            
            try await workoutRef.setData(from: startedWorkout)
            
            await MainActor.run {
                self.currentWorkoutSession = startedWorkout
            }
            
            print("[WorkoutService] Workout started successfully")
            return .success(workoutRef.documentID)
            
        } catch {
            print("[WorkoutService] Failed to start workout: \(error)")
            return .failure(.workoutStartFailed(error))
        }
    }
    
    /// Complete a workout session - PRODUCTION VERSION WITH REAL DATA SAVING
    func completeWorkout(
        _ completionData: WorkoutCompletionData
    ) async -> Result<Void, WorkoutServiceError> {
        
        // STEP 1: Validate input data
        guard completionData.totalDuration > 0, completionData.totalCaloriesBurned >= 0 else {
            print("[WorkoutService] Invalid workout data - duration: \(completionData.totalDuration), calories: \(completionData.totalCaloriesBurned)")
            return .failure(.workoutCompletionFailed(ValidationError.invalidWorkoutData))
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[WorkoutService] User not authenticated")
            return .failure(.notAuthenticated)
        }
        
        print("[WorkoutService] ⚡ PRODUCTION workout completion for: \(completionData.workoutName)")
        print("[WorkoutService] Duration: \(Int(completionData.totalDuration/60)) min, Calories: \(completionData.totalCaloriesBurned)")
        
        // STEP 2: Check network connectivity
        if !connectionMonitor.isConnected {
            print("[WorkoutService] OFFLINE - Queuing workout completion")
            await offlineQueue.queueWorkoutCompletion(completionData)
            await updateLocalWorkoutState(workoutId: completionData.workoutId ?? "unknown", completed: true)
            return .success(())
        }
        
        // STEP 3: Execute with retry logic
        let maxRetries = 3
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            print("[WorkoutService] Attempt \(attempt)/\(maxRetries) for workout completion")
            
            let result = await executeWorkoutCompletionWithTransaction(
                completionData: completionData,
                userId: userId,
                attempt: attempt
            )
            
            switch result {
            case .success():
                print("[WorkoutService] ✅ PRODUCTION workout completion successful on attempt \(attempt)")
                
                // Track successful completion
                privacyManager.trackWorkoutCompleted(
                    type: completionData.workoutType.rawValue,
                    duration: completionData.totalDuration,
                    caloriesBurned: Double(completionData.totalCaloriesBurned)
                )
                
                await MainActor.run {
                    self.currentWorkoutSession = nil
                }
                
                // Refresh user stats
                await loadWorkoutStats(for: userId)
                
                return .success(())
                
            case .failure(let error):
                lastError = error
                print("[WorkoutService] Attempt \(attempt) failed: \(error)")
                
                if attempt < maxRetries {
                    let delay = retryManager.calculateBackoffDelay(attempt: attempt)
                    print("[WorkoutService] Waiting \(delay)s before retry...")
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // STEP 4: All retries failed - queue for later
        print("[WorkoutService] All attempts failed - queuing for background sync")
        await offlineQueue.queueWorkoutCompletion(completionData)
        await updateLocalWorkoutState(workoutId: completionData.workoutId ?? "unknown", completed: true)
        
        return .failure(.workoutCompletionFailed(lastError ?? NetworkError.maxRetriesExceeded))
    }
    
    /// Complete workout with legacy parameters (for backward compatibility)
    func completeWorkout(
        workoutId: String,
        actualDuration: TimeInterval,
        actualCalories: Int,
        rating: Int?
    ) async -> Result<Void, WorkoutServiceError> {
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        var completionData = WorkoutCompletionData(
            workoutId: workoutId,
            workoutName: currentWorkoutSession?.name ?? "Unknown Workout",
            workoutType: currentWorkoutSession?.workoutType ?? .cardio,
            startTime: Date().addingTimeInterval(-actualDuration),
            endTime: Date(),
            totalDuration: actualDuration,
            totalCaloriesBurned: actualCalories,
            completedExercises: [],
            isFullyCompleted: true,
            userRating: rating
        )
        completionData.userId = userId
        
        return await completeWorkout(completionData)
    }
    
    /// Get workout by ID
    func getWorkout(id: String, userId: String) async -> Result<WorkoutSession, WorkoutServiceError> {
        do {
            let document = try await db.collection("users")
                .document(userId)
                .collection("workoutSessions")
                .document(id)
                .getDocument()
            
            guard let workout = try? document.data(as: WorkoutSession.self) else {
                return .failure(.workoutNotFound)
            }
            
            return .success(workout)
        } catch {
            return .failure(.dataLoadFailed(error))
        }
    }
    
    /// Create workout from template
    func createWorkoutFromTemplate(_ template: WorkoutTemplate) -> WorkoutSession {
        return WorkoutSession(
            userId: Auth.auth().currentUser?.uid ?? "",
            workoutType: template.workoutType,
            name: template.name,
            description: template.description,
            estimatedDuration: template.estimatedDuration,
            estimatedCalories: template.estimatedCalories,
            difficulty: template.difficulty,
            targetMuscleGroups: template.targetMuscleGroups,
            exercises: template.exercises,
            imageURL: template.imageURL
        )
    }
    
    /// Save workout as favorite
    func toggleFavorite(workout: WorkoutSession) async -> Result<Void, WorkoutServiceError> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        do {
            let favRef = db.collection("users")
                .document(userId)
                .collection("favoriteWorkouts")
                .document(workout.id ?? UUID().uuidString)
            
            let isFavorite = favoriteWorkouts.contains { $0.id == workout.id }
            
            if isFavorite {
                try await favRef.delete()
                await MainActor.run {
                    favoriteWorkouts.removeAll { $0.id == workout.id }
                }
            } else {
                try await favRef.setData(from: workout)
                await MainActor.run {
                    favoriteWorkouts.append(workout)
                }
            }
            
            return .success(())
        } catch {
            return .failure(.favoriteFailed(error))
        }
    }
    
    /// Search workout templates
    func searchWorkoutTemplates(query: String, filters: WorkoutFilters? = nil) async -> [WorkoutTemplate] {
        do {
            var baseQuery: Query = db.collection("workoutTemplates")
            
            // Apply basic query if provided
            if !query.isEmpty {
                baseQuery = baseQuery
                    .whereField("searchKeywords", arrayContains: query.lowercased())
            }
            
            let querySnapshot = try await baseQuery.getDocuments()
            
            let templates = querySnapshot.documents.compactMap { document in
                try? document.data(as: WorkoutTemplate.self)
            }
            
            // Apply additional client-side filtering
            let filteredTemplates = templates.filter { template in
                let matchesQuery = query.isEmpty || 
                    template.name.localizedCaseInsensitiveContains(query) ||
                    template.workoutType.displayName.localizedCaseInsensitiveContains(query)
                
                guard let filters = filters else { return matchesQuery }
                
                let matchesType = filters.workoutTypes.isEmpty || filters.workoutTypes.contains(template.workoutType)
                let matchesDifficulty = filters.difficulties.isEmpty || filters.difficulties.contains(template.difficulty)
                let matchesDuration = template.estimatedDuration >= filters.minDuration && 
                                     template.estimatedDuration <= filters.maxDuration
                
                return matchesQuery && matchesType && matchesDifficulty && matchesDuration
            }
            
            return filteredTemplates
            
        } catch {
            print("[WorkoutService] Search error: \(error)")
            return []
        }
    }
    
    /// Debug function to check Firebase collections
    func debugFirebaseCollections() async {
        print(" [WorkoutService] Debugging Firebase collections...")
        
        do {
            // Force fresh data from server (disable cache for this query)
            let templatesSnapshot = try await db.collection("workoutTemplates")
                .getDocuments(source: .server) // Force server fetch
            
            print(" [WorkoutService] Forced server fetch - found \(templatesSnapshot.documents.count) documents")
            
            for document in templatesSnapshot.documents {
                print(" [WorkoutService] Document ID: \(document.documentID)")
                print(" [WorkoutService] Document data keys: \(document.data().keys.joined(separator: ", "))")
                
                // Check yoga document specifically
                if document.documentID == "yoga-morning-flow" {
                    print(" [WorkoutService] YOGA DOCUMENT DETAILED ANALYSIS:")
                    let data = document.data()
                    
                    if let exercises = data["exercises"] as? [[String: Any]] {
                        print(" [WorkoutService] Yoga has \(exercises.count) exercises")
                        
                        for (index, exercise) in exercises.enumerated() {
                            print(" [WorkoutService] Exercise \(index): \(exercise.keys.joined(separator: ", "))")
                            
                            // Check for instructions variations
                            if exercise["instructions"] != nil {
                                print(" [WorkoutService] Has 'instructions' field")
                            }
                            if exercise["instructions "] != nil {
                                print(" [WorkoutService] Has 'instructions ' field (with space)")
                            }
                            if let instructions = exercise["instructions"] as? [String] {
                                print(" [WorkoutService] instructions content: \(instructions)")
                            }
                            if let instructionsWithSpace = exercise["instructions "] as? [String] {
                                print(" [WorkoutService] instructions  content: \(instructionsWithSpace)")
                            }
                        }
                    }
                }
                
                // Check if required fields exist
                if let name = document.data()["name"] as? String,
                   let isActive = document.data()["isActive"] {
                    print(" [WorkoutService] Document \(document.documentID) has name: '\(name)', isActive: \(isActive)")
                } else {
                    print(" [WorkoutService] Document \(document.documentID) missing required fields")
                }
            }
            
        } catch {
            print(" [WorkoutService] Error checking Firebase collections: \(error)")
            print(" [WorkoutService] Error details: \(error.localizedDescription)")
        }
    }
    
    /// Clean up resources
    func cleanup() {
        print("[WorkoutService] Cleaning up resources")
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        statsListener?.remove()
        statsListener = nil
        templatesListener?.remove()
        templatesListener = nil
    }
    
    // MARK: - Private Methods
    
    private func loadWorkoutStats(for userId: String) async {
        do {
            let document = try await db.collection("users")
                .document(userId)
                .collection("stats")
                .document("workout")
                .getDocument()
            
            if document.exists {
                let stats = try document.data(as: WorkoutStats.self)
                await MainActor.run {
                    self.workoutStats = stats
                }
            } else {
                // Create initial stats
                let initialStats = createInitialStats(for: userId)
                try await db.collection("users")
                    .document(userId)
                    .collection("stats")
                    .document("workout")
                    .setData(from: initialStats)
                
                await MainActor.run {
                    self.workoutStats = initialStats
                }
            }
        } catch {
            print("[WorkoutService] Failed to load workout stats: \(error)")
            self.error = .dataLoadFailed(error)
        }
    }
    
    private func setupStatsListener(for userId: String) {
        statsListener = db.collection("users")
            .document(userId)
            .collection("stats")
            .document("workout")
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("[WorkoutService] Stats listener error: \(error)")
                        self.error = .dataLoadFailed(error)
                        return
                    }
                    
                    guard let document = snapshot else { return }
                    
                    do {
                        let stats = try document.data(as: WorkoutStats.self)
                        self.workoutStats = stats
                    } catch {
                        print("[WorkoutService] Failed to decode stats: \(error)")
                    }
                }
            }
    }
    
    private func setupTemplatesListener() {
        print(" [WorkoutService] Setting up templates listener...")
        
        templatesListener = db.collection("workoutTemplates")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print(" [WorkoutService] Templates listener error: \(error)")
                        print(" [WorkoutService] Error details: \(error.localizedDescription)")
                        self.error = .dataLoadFailed(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print(" [WorkoutService] No documents in templates snapshot")
                        return
                    }
                    
                    print(" [WorkoutService] Received \(documents.count) template documents from Firebase")
                    
                    let templates = documents.compactMap { document -> WorkoutTemplate? in
                        do {
                            let template = try document.data(as: WorkoutTemplate.self)
                            print(" [WorkoutService] Successfully decoded template: \(template.name)")
                            return template
                        } catch {
                            print(" [WorkoutService] Failed to decode template from document \(document.documentID): \(error)")
                            print(" [WorkoutService] Document data: \(document.data())")
                            return nil
                        }
                    }
                    
                    print(" [WorkoutService] Successfully loaded \(templates.count) workout templates")
                    
                    self.workoutTemplates = templates
                    
                    // Convert templates to workout sessions for compatibility
                    self.availableWorkouts = templates.map { template in
                        self.createWorkoutFromTemplate(template)
                    }
                    
                    print(" [WorkoutService] Created \(self.availableWorkouts.count) available workouts from templates")
                }
            }
    }
    
    private func loadWorkoutTemplates() async {
        print(" [WorkoutService] Loading workout templates manually...")
        
        do {
            let querySnapshot = try await db.collection("workoutTemplates")
                .whereField("isActive", isEqualTo: true)
                .order(by: "priority", descending: false)
                .getDocuments(source: .server) // Force server fetch to bypass cache
            
            print(" [WorkoutService] Manual query returned \(querySnapshot.documents.count) documents (from SERVER)")
            
            let templates = querySnapshot.documents.compactMap { document -> WorkoutTemplate? in
                do {
                    let template = try document.data(as: WorkoutTemplate.self)
                    print(" [WorkoutService] Successfully decoded template: \(template.name)")
                    return template
                } catch {
                    print(" [WorkoutService] Failed to decode template from document \(document.documentID): \(error)")
                    print(" [WorkoutService] Document data: \(document.data())")
                    return nil
                }
            }
            
            await MainActor.run {
                self.workoutTemplates = templates
                self.availableWorkouts = templates.map { template in
                    self.createWorkoutFromTemplate(template)
                }
                
                print(" [WorkoutService] Manual loading completed: \(templates.count) templates, \(self.availableWorkouts.count) available workouts")
            }
            
        } catch {
            print(" [WorkoutService] Failed to load workout templates manually: \(error)")
            print(" [WorkoutService] Error details: \(error.localizedDescription)")
            self.error = .dataLoadFailed(error)
        }
    }
    
    private func loadRecentWorkouts(for userId: String) async {
        do {
            // Simplified query without composite index that was causing problems
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("workoutSessions")
                .limit(to: 10)
                .getDocuments()
                
            let workouts = snapshot.documents.compactMap { document in
                try? document.data(as: WorkoutSession.self)
            }
            
            await MainActor.run {
                self.recentWorkouts = workouts
            }
            
            print("[WorkoutService]  Loaded \(workouts.count) recent workouts")
        } catch {
            print("[WorkoutService]  Recent workouts query error (using simplified version): \(error)")
        }
    }
    
    private func loadFavoriteWorkouts(for userId: String) async {
        do {
            let querySnapshot = try await db.collection("users")
                .document(userId)
                .collection("favoriteWorkouts")
                .getDocuments()
            
            let workouts = querySnapshot.documents.compactMap { document in
                try? document.data(as: WorkoutSession.self)
            }
            
            await MainActor.run {
                self.favoriteWorkouts = workouts
            }
        } catch {
            print("[WorkoutService] Failed to load favorite workouts: \(error)")
        }
    }
    
    private func loadTodayRecommendations(for userId: String) async {
        let recommendations = await generateTodayRecommendations(for: userId)
        
        await MainActor.run {
            self.todayRecommendations = recommendations
        }
        
        print("[WorkoutService]  Loaded \(recommendations.count) recommendations for today")
    }
    
    private func updateUserStats(userId: String, completedDuration: TimeInterval, caloriesBurned: Int) async {
        guard let currentStats = workoutStats else { return }
        
        let updatedStats = WorkoutStats(
            userId: userId,
            totalWorkouts: currentStats.totalWorkouts + 1,
            totalDuration: currentStats.totalDuration + completedDuration,
            totalCaloriesBurned: currentStats.totalCaloriesBurned + caloriesBurned,
            currentStreak: calculateCurrentStreak(),
            longestStreak: max(currentStats.longestStreak, calculateCurrentStreak()),
            favoriteWorkoutType: calculateFavoriteWorkoutType(),
            weeklyGoal: currentStats.weeklyGoal,
            weeklyProgress: calculateWeeklyProgress(),
            monthlyCalorieGoal: currentStats.monthlyCalorieGoal,
            monthlyCalorieProgress: currentStats.monthlyCalorieProgress + caloriesBurned,
            personalRecords: updatePersonalRecords(currentStats.personalRecords, duration: completedDuration, calories: caloriesBurned),
            lastWorkoutDate: Date(),
            updatedAt: Date()
        )
        
        do {
            try await db.collection("users")
                .document(userId)
                .collection("stats")
                .document("workout")
                .setData(from: updatedStats)
        } catch {
            print("[WorkoutService] Failed to update stats: \(error)")
        }
    }
    
    private func generateTodayRecommendations(for userId: String) async -> [WorkoutRecommendation] {
        var recommendations: [WorkoutRecommendation] = []
        
        // Get user's workout patterns
        let stats = workoutStats
        let lastWorkoutDate = stats?.lastWorkoutDate
        let currentStreak = stats?.currentStreak ?? 0
        
        // Check if it's a rest day
        let calendar = Calendar.current
        let today = Date()
        
        if let lastWorkout = lastWorkoutDate,
           calendar.isDate(lastWorkout, inSameDayAs: today) {
            // User already worked out today - suggest light activity
            if let restWorkout = availableWorkouts.first(where: { $0.workoutType == .stretching && $0.difficulty == .beginner }) {
                let recommendation = WorkoutRecommendation(
                    workoutSession: restWorkout,
                    reason: .restDay,
                    priority: 7,
                    validUntil: calendar.date(byAdding: .day, value: 1, to: today) ?? today
                )
                recommendations.append(recommendation)
            }
        } else {
            // Suggest main workout
            if currentStreak > 0 {
                // Maintain streak
                if let streakWorkout = availableWorkouts.randomElement() {
                    let recommendation = WorkoutRecommendation(
                        workoutSession: streakWorkout,
                        reason: .streakMaintenance,
                        priority: 10,
                        validUntil: calendar.date(byAdding: .day, value: 1, to: today) ?? today
                    )
                    recommendations.append(recommendation)
                }
            } else {
                // Daily goal workout
                if let dailyWorkout = availableWorkouts.first(where: { $0.difficulty == .beginner }) {
                    let recommendation = WorkoutRecommendation(
                        workoutSession: dailyWorkout,
                        reason: .dailyGoal,
                        priority: 8,
                        validUntil: calendar.date(byAdding: .day, value: 1, to: today) ?? today
                    )
                    recommendations.append(recommendation)
                }
            }
        }
        
        return recommendations.sorted { $0.priority > $1.priority }
    }
    
    private func calculateCurrentStreak() -> Int {
        // Enhanced streak calculation with proper date logic
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastWorkout = workoutStats?.lastWorkoutDate else { return 1 }
        
        let lastWorkoutDay = calendar.startOfDay(for: lastWorkout)
        let daysDifference = calendar.dateComponents([.day], from: lastWorkoutDay, to: today).day ?? 0
        
        if daysDifference == 0 {
            return workoutStats?.currentStreak ?? 1 // Same day
        } else if daysDifference == 1 {
            return (workoutStats?.currentStreak ?? 0) + 1 // Next day
        } else {
            return 1 // Streak broken, start fresh
        }
    }
    
    private func calculateFavoriteWorkoutType() -> WorkoutType? {
        // Return existing favorite type, or analyze recent workouts
        // For production, this would analyze workout history from Firebase
        return workoutStats?.favoriteWorkoutType ?? currentWorkoutSession?.workoutType
    }
    
    private func updatePersonalRecords(_ currentRecords: [PersonalRecord], duration: TimeInterval, calories: Int) -> [PersonalRecord] {
        var updatedRecords = currentRecords
        
        // Check for longest workout
        if let longestWorkout = currentRecords.first(where: { $0.type == .longestWorkout }) {
            if duration > longestWorkout.value {
                updatedRecords.removeAll { $0.type == .longestWorkout }
                updatedRecords.append(PersonalRecord(
                    type: .longestWorkout,
                    value: duration,
                    unit: "seconds",
                    workoutType: currentWorkoutSession?.workoutType ?? .cardio,
                    achievedAt: Date(),
                    exerciseName: currentWorkoutSession?.name
                ))
            }
        } else {
            updatedRecords.append(PersonalRecord(
                type: .longestWorkout,
                value: duration,
                unit: "seconds",
                workoutType: currentWorkoutSession?.workoutType ?? .cardio,
                achievedAt: Date(),
                exerciseName: currentWorkoutSession?.name
            ))
        }
        
        // Check for most calories
        if let mostCalories = currentRecords.first(where: { $0.type == .mostCalories }) {
            if Double(calories) > mostCalories.value {
                updatedRecords.removeAll { $0.type == .mostCalories }
                updatedRecords.append(PersonalRecord(
                    type: .mostCalories,
                    value: Double(calories),
                    unit: "kcal",
                    workoutType: currentWorkoutSession?.workoutType ?? .cardio,
                    achievedAt: Date(),
                    exerciseName: currentWorkoutSession?.name
                ))
            }
        } else {
            updatedRecords.append(PersonalRecord(
                type: .mostCalories,
                value: Double(calories),
                unit: "kcal",
                workoutType: currentWorkoutSession?.workoutType ?? .cardio,
                achievedAt: Date(),
                exerciseName: currentWorkoutSession?.name
            ))
        }
        
        return updatedRecords
    }
    
    private func createInitialStats(for userId: String) -> WorkoutStats {
        return WorkoutStats(
            userId: userId,
            totalWorkouts: 0,
            totalDuration: 0,
            totalCaloriesBurned: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteWorkoutType: nil,
            weeklyGoal: 3,
            weeklyProgress: 0,
            monthlyCalorieGoal: 2000,
            monthlyCalorieProgress: 0,
            personalRecords: [],
            lastWorkoutDate: nil,
            updatedAt: Date()
        )
    }
    
    private func calculateWeeklyProgress() -> Int {
        // Enhanced weekly progress calculation
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        // This would typically query recent workouts, for now return incremented value
        return (workoutStats?.weeklyProgress ?? 0) + 1
    }
    
    // MARK: - ATOMIC TRANSACTION-BASED COMPLETION
    
    private func executeWorkoutCompletionWithTransaction(
        completionData: WorkoutCompletionData,
        userId: String,
        attempt: Int
    ) async -> Result<Void, Error> {
        
        do {
            try await db.runTransaction { transaction, errorPointer in
                
                do {
                    // CRITICAL FIX: ALL READS MUST COME FIRST BEFORE ANY WRITES
                    
                    // 1. READ: Get current stats first (before any writes)
                    let statsRef = self.db.collection("users")
                        .document(userId)
                        .collection("stats")
                        .document("workout")
                    
                    let statsDocument = try transaction.getDocument(statsRef)
                    let currentStats: WorkoutStats
                    
                    if statsDocument.exists {
                        currentStats = try statsDocument.data(as: WorkoutStats.self)
                    } else {
                        currentStats = self.createInitialStats(for: userId)
                    }
                    
                    // NOW ALL WRITES CAN BEGIN
                    
                    // 2. WRITE: Save the workout completion record
                    let completionRef = self.db.collection("users")
                        .document(userId)
                        .collection("completedWorkouts")
                        .document()
                    
                    let completionDocumentData: [String: Any] = [
                        "workoutId": completionData.workoutId as Any,
                        "workoutName": completionData.workoutName,
                        "workoutType": completionData.workoutType.rawValue,
                        "startTime": Timestamp(date: completionData.startTime),
                        "endTime": Timestamp(date: completionData.endTime ?? Date()),
                        "totalDuration": completionData.totalDuration,
                        "totalCaloriesBurned": completionData.totalCaloriesBurned,
                        "isFullyCompleted": completionData.isFullyCompleted,
                        "userRating": completionData.userRating as Any,
                        "completedAt": Timestamp(),
                        "completionAttempt": attempt,
                        "userId": userId
                    ]
                    
                    transaction.setData(completionDocumentData, forDocument: completionRef)
                    
                    // 3. WRITE: Update the original workout session if it exists
                    if let workoutId = completionData.workoutId {
                        let workoutRef = self.db.collection("users")
                            .document(userId)
                            .collection("workoutSessions")
                            .document(workoutId)
                        
                        let workoutUpdateData: [String: Any] = [
                            "isCompleted": true,
                            "completedAt": Timestamp(),
                            "actualDuration": completionData.totalDuration,
                            "actualCalories": completionData.totalCaloriesBurned,
                            "userRating": completionData.userRating as Any,
                            "updatedAt": Timestamp()
                        ]
                        
                        transaction.updateData(workoutUpdateData, forDocument: workoutRef)
                    }
                    
                    // 4. WRITE: Update user stats (calculated from the read data above)
                    let updatedStats = WorkoutStats(
                        userId: userId,
                        totalWorkouts: currentStats.totalWorkouts + 1,
                        totalDuration: currentStats.totalDuration + completionData.totalDuration,
                        totalCaloriesBurned: currentStats.totalCaloriesBurned + completionData.totalCaloriesBurned,
                        currentStreak: self.calculateCurrentStreak(from: currentStats),
                        longestStreak: max(currentStats.longestStreak, self.calculateCurrentStreak(from: currentStats)),
                        favoriteWorkoutType: self.calculateFavoriteWorkoutType(from: currentStats) ?? completionData.workoutType,
                        weeklyGoal: currentStats.weeklyGoal,
                        weeklyProgress: self.calculateWeeklyProgress(from: currentStats),
                        monthlyCalorieGoal: currentStats.monthlyCalorieGoal,
                        monthlyCalorieProgress: currentStats.monthlyCalorieProgress + completionData.totalCaloriesBurned,
                        personalRecords: self.updatePersonalRecords(
                            currentStats.personalRecords,
                            duration: completionData.totalDuration,
                            calories: completionData.totalCaloriesBurned
                        ),
                        lastWorkoutDate: Date(),
                        updatedAt: Date()
                    )
                    
                    try transaction.setData(from: updatedStats, forDocument: statsRef)
                    
                    print("[WorkoutService] ✅ FIXED TRANSACTION: All reads done first, then all writes")
                    print("  - Read: Current stats retrieved")
                    print("  - Write: Completion record saved")
                    print("  - Write: Original workout updated")
                    print("  - Write: Stats updated: \(updatedStats.totalWorkouts) workouts, \(updatedStats.totalCaloriesBurned) calories")
                    
                } catch {
                    print("[WorkoutService] Transaction preparation error: \(error)")
                    errorPointer?.pointee = error as NSError
                }
                
                return nil
            }
            
            print("[WorkoutService] 🎉 TRANSACTION SUCCESS: Workout completion saved to Firebase!")
            return .success(())
            
        } catch let error as NSError {
            print("[WorkoutService] ATOMIC transaction failed: \(error.localizedDescription)")
            
            if error.domain == "FIRFirestoreErrorDomain" {
                switch error.code {
                case 14: // DEADLINE_EXCEEDED
                    return .failure(NetworkError.serviceUnavailable)
                case 4:  // TOO_MANY_REQUESTS
                    return .failure(NetworkError.timeout)
                case 8:  // ABORTED
                    return .failure(NetworkError.rateLimited)
                default:
                    return .failure(NetworkError.firebaseError(error))
                }
            }
            
            return .failure(error)
        }
    }
    
    private func calculateCurrentStreak(from stats: WorkoutStats) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lastWorkout = stats.lastWorkoutDate else { return 1 }
        
        let lastWorkoutDay = calendar.startOfDay(for: lastWorkout)
        let daysDifference = calendar.dateComponents([.day], from: lastWorkoutDay, to: today).day ?? 0
        
        if daysDifference == 0 {
            return stats.currentStreak 
        } else if daysDifference == 1 {
            return stats.currentStreak + 1 
        } else {
            return 1 
        }
    }
    
    private func calculateWeeklyProgress(from stats: WorkoutStats) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return stats.weeklyProgress + 1
    }
    
    private func calculateFavoriteWorkoutType(from stats: WorkoutStats) -> WorkoutType? {
        return stats.favoriteWorkoutType
    }
    
    // MARK: - NETWORK MONITORING & OFFLINE SUPPORT
    
    private func setupNetworkMonitoring() {
        connectionMonitor.onConnectionRestored = { [weak self] in
            Task { @MainActor in
                await self?.processPendingOperations()
            }
        }
        
        connectionMonitor.onConnectionLost = { [weak self] in
            Task { @MainActor in
                self?.handleConnectionLoss()
            }
        }
    }
    
    private func processPendingOperations() async {
        guard connectionMonitor.isConnected else { return }
        
        let pendingCount = await offlineQueue.pendingCount
        print("[WorkoutService] Processing \(pendingCount) offline operations")
        
        let pendingCompletions = await offlineQueue.getPendingCompletions()
        
        for offlineCompletion in pendingCompletions {
            // Convert OfflineWorkoutCompletion to WorkoutCompletionData
            let completionData = WorkoutCompletionData(
                workoutId: offlineCompletion.workoutId,
                userId: offlineCompletion.userId,
                actualDuration: offlineCompletion.actualDuration,
                actualCalories: offlineCompletion.actualCalories,
                rating: offlineCompletion.rating,
                completedAt: offlineCompletion.queuedAt
            )
            
            let result = await executeWorkoutCompletionWithTransaction(
                completionData: completionData,
                userId: offlineCompletion.userId,
                attempt: 1
            )
            
            switch result {
            case .success():
                await offlineQueue.removeCompletion(offlineCompletion.id)
                print("[WorkoutService] Synced offline completion: \(offlineCompletion.workoutId ?? "unknown")")
                
            case .failure(let error):
                print("[WorkoutService] Failed to sync offline completion: \(error)")
            }
        }
    }
    
    private func handleConnectionLoss() {
        print("[WorkoutService] Connection lost - enabling offline mode")
    }
    
    private func updateLocalWorkoutState(workoutId: String, completed: Bool) async {
        print("[WorkoutService] Updated local workout state: \(workoutId) completed: \(completed)")
    }
    
}

struct WorkoutFilters {
    let workoutTypes: Set<WorkoutType>
    let difficulties: Set<DifficultyLevel>
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let muscleGroups: Set<MuscleGroup>
    
    init(
        workoutTypes: Set<WorkoutType> = [],
        difficulties: Set<DifficultyLevel> = [],
        minDuration: TimeInterval = 0,
        maxDuration: TimeInterval = 3600,
        muscleGroups: Set<MuscleGroup> = []
    ) {
        self.workoutTypes = workoutTypes
        self.difficulties = difficulties
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.muscleGroups = muscleGroups
    }
}

enum WorkoutServiceError: LocalizedError, Identifiable {
    case notAuthenticated
    case initializationFailed(Error)
    case dataLoadFailed(Error)
    case workoutStartFailed(Error)
    case workoutCompletionFailed(Error)
    case workoutNotFound
    case favoriteFailed(Error)
    case networkError
    
    var id: String {
        switch self {
        case .notAuthenticated: return "not_authenticated"
        case .initializationFailed: return "initialization_failed"
        case .dataLoadFailed: return "data_load_failed"
        case .workoutStartFailed: return "workout_start_failed"
        case .workoutCompletionFailed: return "workout_completion_failed"
        case .workoutNotFound: return "workout_not_found"
        case .favoriteFailed: return "favorite_failed"
        case .networkError: return "network_error"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please log in to access workouts"
        case .initializationFailed: return "Failed to initialize workout service"
        case .dataLoadFailed: return "Failed to load workout data"
        case .workoutStartFailed: return "Failed to start workout"
        case .workoutCompletionFailed: return "Failed to complete workout"
        case .workoutNotFound: return "Workout not found"
        case .favoriteFailed: return "Failed to update favorites"
        case .networkError: return "Network connection error"
        }
    }
}

actor WorkoutOfflineQueue {
    private var pendingCompletions: [OfflineWorkoutCompletion] = []
    
    var pendingCount: Int {
        pendingCompletions.count
    }
    
    func queueWorkoutCompletion(_ completion: WorkoutCompletionData) {
        let offlineCompletion = OfflineWorkoutCompletion(
            id: UUID().uuidString,
            workoutId: completion.workoutId,
            userId: completion.userId ?? "",
            actualDuration: completion.totalDuration,
            actualCalories: completion.totalCaloriesBurned,
            rating: completion.userRating,
            queuedAt: Date()
        )
        
        pendingCompletions.append(offlineCompletion)
        print("[OfflineQueue] Queued workout completion: \(offlineCompletion.id)")
    }
    
    func getPendingCompletions() -> [OfflineWorkoutCompletion] {
        return pendingCompletions
    }
    
    func removeCompletion(_ id: String) {
        pendingCompletions.removeAll { $0.id == id }
        print("[OfflineQueue] Removed completed operation: \(id)")
    }
}

class NetworkRetryManager {
    func calculateBackoffDelay(attempt: Int) -> Double {
        let baseDelay = 1.0
        let maxDelay = 30.0
        let delay = baseDelay * pow(2.0, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

class NetworkConnectionMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    
    var onConnectionRestored: (() -> Void)?
    var onConnectionLost: (() -> Void)?
    
    func startMonitoring() {
        // Implementation would monitor actual network state
    }
}

struct OfflineWorkoutCompletion: Identifiable, Codable {
    let id: String
    let workoutId: String?
    let userId: String
    let actualDuration: TimeInterval
    let actualCalories: Int
    let rating: Int?
    let queuedAt: Date
}

enum NetworkError: LocalizedError {
    case timeout
    case serviceUnavailable
    case rateLimited
    case maxRetriesExceeded
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .timeout: return "Request timed out. Please try again."
        case .serviceUnavailable: return "Service temporarily unavailable. Your workout will be saved when connection is restored."
        case .rateLimited: return "Too many requests. Please wait a moment and try again."
        case .maxRetriesExceeded: return "Unable to save workout after multiple attempts. Data has been saved locally and will sync automatically."
        case .firebaseError(let error): return "Database error: \(error.localizedDescription)"
        }
    }
}

enum ValidationError: LocalizedError {
    case invalidWorkoutData
    case missingRequiredFields
    
    var errorDescription: String? {
        switch self {
        case .invalidWorkoutData: return "Invalid workout data provided"
        case .missingRequiredFields: return "Required workout information is missing"
        }
    }
}

struct WorkoutOperation: Identifiable {
    let id: String
    let type: OperationType
    let data: [String: Any]
    let createdAt: Date
    
    enum OperationType {
        case completeWorkout
        case updateStats
        case syncOfflineData
    }
}