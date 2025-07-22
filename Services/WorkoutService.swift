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
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let privacyManager = PrivacyManager.shared
    private var listeners: [ListenerRegistration] = []
    private var statsListener: ListenerRegistration?
    private var templatesListener: ListenerRegistration?
    private var currentUserId: String?
    
    // MARK: - Singleton
    static let shared = WorkoutService()
    private init() {
        setupTemplatesListener()
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
    
    /// Complete a workout session
    func completeWorkout(
        workoutId: String,
        actualDuration: TimeInterval,
        actualCalories: Int,
        rating: Int?
    ) async -> Result<Void, WorkoutServiceError> {
        guard let userId = Auth.auth().currentUser?.uid else {
            return .failure(.notAuthenticated)
        }
        
        print("[WorkoutService] Completing workout: \(workoutId)")
        
        do {
            let workoutRef = db.collection("users")
                .document(userId)
                .collection("workoutSessions")
                .document(workoutId)
            
            let updateData: [String: Any] = [
                "isCompleted": true,
                "completedAt": Timestamp(),
                "actualDuration": actualDuration,
                "actualCalories": actualCalories,
                "userRating": rating as Any,
                "updatedAt": Timestamp()
            ]
            
            try await workoutRef.updateData(updateData)
            
            // Update user stats
            await updateUserStats(
                userId: userId,
                completedDuration: actualDuration,
                caloriesBurned: actualCalories
            )
            
            // Track completion for analytics
            if let currentWorkout = currentWorkoutSession {
                privacyManager.trackWorkoutCompleted(
                    type: currentWorkout.workoutType.rawValue,
                    duration: actualDuration,
                    caloriesBurned: Double(actualCalories)
                )
            }
            
            await MainActor.run {
                self.currentWorkoutSession = nil
            }
            
            print("[WorkoutService] Workout completed successfully")
            return .success(())
            
        } catch {
            print("[WorkoutService] Failed to complete workout: \(error)")
            return .failure(.workoutCompletionFailed(error))
        }
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
        // Implementation would check consecutive workout days
        return workoutStats?.currentStreak ?? 0
    }
    
    private func calculateFavoriteWorkoutType() -> WorkoutType? {
        // Implementation would analyze workout history
        return workoutStats?.favoriteWorkoutType
    }
    
    private func calculateWeeklyProgress() -> Int {
        // Implementation would count workouts in current week
        return workoutStats?.weeklyProgress ?? 0
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
    
    /// Add preload method for better UX
    func preloadWorkoutTemplates(for userId: String) async {
        if workoutTemplates.isEmpty {
            await loadWorkoutTemplates()
        }
        print("[WorkoutService]  Preload completed - \(workoutTemplates.count) templates ready")
    }
}

// MARK: - Supporting Types

/// Workout Template for Firebase storage
struct WorkoutTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let workoutType: WorkoutType
    let difficulty: DifficultyLevel
    let estimatedDuration: TimeInterval
    let estimatedCalories: Int
    let targetMuscleGroups: [MuscleGroup]
    let exercises: [WorkoutExercise]
    let imageURL: String?
    let isActive: Bool
    let priority: Int
    let searchKeywords: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Custom Decoding to Handle Firebase Inconsistencies
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case workoutType
        case difficulty
        case estimatedDuration
        case estimatedCalories
        case targetMuscleGroups
        case exercises
        case imageURL
        case isActive
        case priority
        case searchKeywords
        case createdAt
        case updatedAt
        
        // Alternative field names for handling typos
        case estimatedCalroies // Handle typo in Firebase
        case exercise // Handle singular form
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.workoutType = try container.decode(WorkoutType.self, forKey: .workoutType)
        self.difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        self.targetMuscleGroups = try container.decode([MuscleGroup].self, forKey: .targetMuscleGroups)
        
        // Handle estimatedDuration with fallback
        if let duration = try container.decodeIfPresent(TimeInterval.self, forKey: .estimatedDuration) {
            self.estimatedDuration = duration
        } else {
            // Fallback based on workout type
            switch workoutType {
            case .hiit: self.estimatedDuration = 20 * 60 // 20 minutes
            case .yoga: self.estimatedDuration = 45 * 60 // 45 minutes  
            case .strength: self.estimatedDuration = 60 * 60 // 60 minutes
            case .cardio: self.estimatedDuration = 30 * 60 // 30 minutes
            case .pilates: self.estimatedDuration = 40 * 60 // 40 minutes
            case .dance: self.estimatedDuration = 35 * 60 // 35 minutes
            case .stretching: self.estimatedDuration = 25 * 60 // 25 minutes
            case .running: self.estimatedDuration = 45 * 60 // 45 minutes
            }
        }
        
        // Handle estimatedCalories with typo fallback
        if let calories = try container.decodeIfPresent(Int.self, forKey: .estimatedCalories) {
            self.estimatedCalories = calories
        } else if let calories = try container.decodeIfPresent(Int.self, forKey: .estimatedCalroies) {
            // Handle typo in Firebase
            self.estimatedCalories = calories
        } else {
            // Fallback based on workout type and duration
            let durationMinutes = Int(estimatedDuration / 60)
            switch workoutType {
            case .hiit: self.estimatedCalories = durationMinutes * 12
            case .cardio: self.estimatedCalories = durationMinutes * 10
            case .strength: self.estimatedCalories = durationMinutes * 8
            case .yoga: self.estimatedCalories = durationMinutes * 4
            case .pilates: self.estimatedCalories = durationMinutes * 6
            case .dance: self.estimatedCalories = durationMinutes * 9
            case .stretching: self.estimatedCalories = durationMinutes * 3
            case .running: self.estimatedCalories = durationMinutes * 11
            }
        }
        
        // Handle exercises with custom parsing
        let currentWorkoutType = workoutType
        let parsedExercises: [WorkoutExercise]
        
        do {
            // First try to decode as WorkoutExercise array directly
            parsedExercises = try container.decode([WorkoutExercise].self, forKey: .exercises)
        } catch {
            // If that fails, try to decode from Firebase raw data
            if let exercisesData = try? container.decode([FirebaseExerciseData].self, forKey: .exercises) {
                parsedExercises = exercisesData.map { firebaseData in
                    WorkoutTemplate.convertFirebaseExerciseToWorkoutExercise(firebaseData, workoutType: currentWorkoutType)
                }
            } else if let exercisesData = try? container.decode([FirebaseExerciseData].self, forKey: .exercise) {
                // Handle singular form in Firebase
                parsedExercises = exercisesData.map { firebaseData in
                    WorkoutTemplate.convertFirebaseExerciseToWorkoutExercise(firebaseData, workoutType: currentWorkoutType)
                }
            } else {
                parsedExercises = []
            }
        }
        
        // Assign the parsed exercises
        self.exercises = parsedExercises
        
        // Optional fields with fallbacks
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority) ?? 0
        
        // Handle searchKeywords with fallback
        if let keywords = try container.decodeIfPresent([String].self, forKey: .searchKeywords) {
            self.searchKeywords = keywords
        } else {
            // Generate keywords from available data
            self.searchKeywords = WorkoutTemplate.generateSearchKeywords(
                name: name, 
                workoutType: workoutType, 
                muscleGroups: targetMuscleGroups
            )
        }
        
        // Handle dates with fallbacks
        if let createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) {
            self.createdAt = createdAt
        } else {
            self.createdAt = Date()
        }
        
        if let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) {
            self.updatedAt = updatedAt
        } else {
            self.updatedAt = Date()
        }
    }

    // MARK: - Standard Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(workoutType, forKey: .workoutType)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(estimatedDuration, forKey: .estimatedDuration)
        try container.encode(estimatedCalories, forKey: .estimatedCalories)
        try container.encode(targetMuscleGroups, forKey: .targetMuscleGroups)
        try container.encode(exercises, forKey: .exercises)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(priority, forKey: .priority)
        try container.encode(searchKeywords, forKey: .searchKeywords)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    init(
        id: String? = nil,
        name: String,
        description: String,
        workoutType: WorkoutType,
        difficulty: DifficultyLevel,
        estimatedDuration: TimeInterval,
        estimatedCalories: Int,
        targetMuscleGroups: [MuscleGroup],
        exercises: [WorkoutExercise],
        imageURL: String? = nil,
        isActive: Bool = true,
        priority: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.workoutType = workoutType
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.estimatedCalories = estimatedCalories
        self.targetMuscleGroups = targetMuscleGroups
        self.exercises = exercises
        self.imageURL = imageURL
        self.isActive = isActive
        self.priority = priority
        self.searchKeywords = WorkoutTemplate.generateSearchKeywords(name: name, workoutType: workoutType, muscleGroups: targetMuscleGroups)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func generateSearchKeywords(name: String, workoutType: WorkoutType, muscleGroups: [MuscleGroup]) -> [String] {
        var keywords = Set<String>()
        
        // Add name words
        name.lowercased().components(separatedBy: .whitespaces).forEach { word in
            if !word.isEmpty {
                keywords.insert(word)
            }
        }
        
        // Add workout type
        keywords.insert(workoutType.rawValue.lowercased())
        keywords.insert(workoutType.displayName.lowercased())
        
        // Add muscle groups
        muscleGroups.forEach { muscle in
            keywords.insert(muscle.rawValue.lowercased())
            keywords.insert(muscle.displayName.lowercased())
        }
        
        return Array(keywords)
    }
    
    // MARK: - Firebase Exercise Conversion
    
    static func convertFirebaseExerciseToWorkoutExercise(_ firebaseData: FirebaseExerciseData, workoutType: WorkoutType) -> WorkoutExercise {
        let exerciseType = inferExerciseType(name: firebaseData.name, workoutType: workoutType)
        
        // Parse target muscle groups
        let targetMuscleGroups: [MuscleGroup]
        if !firebaseData.targetMuscleGroups.isEmpty {
            targetMuscleGroups = firebaseData.targetMuscleGroups.compactMap { MuscleGroup(rawValue: $0) }
        } else {
            targetMuscleGroups = [.fullBody]
        }
        
        return WorkoutExercise(
            name: firebaseData.name,
            description: firebaseData.description,
            exerciseType: exerciseType,
            targetMuscleGroups: targetMuscleGroups,
            sets: firebaseData.sets,
            reps: firebaseData.reps,
            duration: firebaseData.duration,
            restTime: firebaseData.restTime ?? 30,
            weight: firebaseData.weight,
            distance: firebaseData.distance,
            instructions: firebaseData.instructions.isEmpty ? ["Perform the exercise as demonstrated"] : firebaseData.instructions,
            imageURL: firebaseData.imageURL,
            videoURL: firebaseData.videoURL,
            caloriesPerMinute: firebaseData.caloriesPerMinute ?? 5.0,
            exerciseIcon: firebaseData.exerciseIcon ?? exerciseType.defaultIcon
        )
    }
    
    static func inferExerciseType(name: String, workoutType: WorkoutType) -> ExerciseType {
        let lowercaseName = name.lowercased()
        
        // Name-based inference
        if lowercaseName.contains("squat") || lowercaseName.contains("deadlift") || lowercaseName.contains("bench") || lowercaseName.contains("row") {
            return .strength
        } else if lowercaseName.contains("jump") || lowercaseName.contains("burpee") || lowercaseName.contains("explosive") {
            return .plyometric
        } else if lowercaseName.contains("stretch") || lowercaseName.contains("twist") || lowercaseName.contains("pose") {
            return .flexibility
        } else if lowercaseName.contains("run") || lowercaseName.contains("jog") || lowercaseName.contains("marathon") {
            return .endurance
        }
        
        // Workout type-based inference
        switch workoutType {
        case .cardio: return .cardio
        case .strength: return .strength
        case .yoga: return .flexibility
        case .pilates: return .balance
        case .hiit: return .plyometric
        case .dance: return .cardio
        case .stretching: return .flexibility
        case .running: return .endurance
        }
    }
}

// MARK: - Firebase Exercise Data Structure

/// Helper struct for decoding Firebase exercise data
struct FirebaseExerciseData: Codable {
    let name: String
    let description: String?
    let targetMuscleGroups: [String]
    let sets: Int?
    let reps: Int?
    let duration: TimeInterval?
    let restTime: TimeInterval?
    let weight: Double?
    let distance: Double?
    let instructions: [String]
    let imageURL: String?
    let videoURL: String?
    let caloriesPerMinute: Double?
    let exerciseIcon: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.targetMuscleGroups = try container.decodeIfPresent([String].self, forKey: .targetMuscleGroups) ?? []
        self.sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        self.reps = try container.decodeIfPresent(Int.self, forKey: .reps)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.restTime = try container.decodeIfPresent(TimeInterval.self, forKey: .restTime)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        self.instructions = try container.decodeIfPresent([String].self, forKey: .instructions) ?? []
        self.imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        self.videoURL = try container.decodeIfPresent(String.self, forKey: .videoURL)
        self.caloriesPerMinute = try container.decodeIfPresent(Double.self, forKey: .caloriesPerMinute)
        self.exerciseIcon = try container.decodeIfPresent(String.self, forKey: .exerciseIcon)
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, description, targetMuscleGroups, sets, reps, duration, restTime
        case weight, distance, instructions, imageURL, videoURL, caloriesPerMinute, exerciseIcon
    }
}

// ... existing code ...

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
        maxDuration: TimeInterval = 3600, // 1 hour
        muscleGroups: Set<MuscleGroup> = []
    ) {
        self.workoutTypes = workoutTypes
        self.difficulties = difficulties
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.muscleGroups = muscleGroups
    }
}

/// Service-specific errors
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
        case .notAuthenticated:
            return "Please log in to access workouts"
        case .initializationFailed:
            return "Failed to initialize workout service"
        case .dataLoadFailed:
            return "Failed to load workout data"
        case .workoutStartFailed:
            return "Failed to start workout"
        case .workoutCompletionFailed:
            return "Failed to complete workout"
        case .workoutNotFound:
            return "Workout not found"
        case .favoriteFailed:
            return "Failed to update favorites"
        case .networkError:
            return "Network connection error"
        }
    }
}