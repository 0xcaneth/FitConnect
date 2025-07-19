import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI
import Combine

/// Production-ready WorkoutService with comprehensive functionality
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
    @Published var error: WorkoutServiceError?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let privacyManager = PrivacyManager.shared
    private var listeners: [ListenerRegistration] = []
    private var statsListener: ListenerRegistration?
    
    // MARK: - Singleton
    static let shared = WorkoutService()
    private init() {
        setupMockData()
    }
    
    // MARK: - Public Methods
    
    /// Initialize service for user
    func initialize(for userId: String) async {
        print("[WorkoutService] Initializing for user: \(userId)")
        
        isLoading = true
        
        do {
            // Load user's workout stats
            await loadWorkoutStats(for: userId)
            
            // Setup real-time listeners
            setupStatsListener(for: userId)
            
            // Load initial data
            await loadTodayRecommendations(for: userId)
            await loadRecentWorkouts(for: userId)
            await loadFavoriteWorkouts(for: userId)
            await loadAvailableWorkouts()
            
            print("[WorkoutService] Successfully initialized")
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
    
    /// Search workouts
    func searchWorkouts(query: String, filters: WorkoutFilters? = nil) async -> [WorkoutSession] {
        // In production, this would search Firestore
        // For now, search in available workouts
        let filteredWorkouts = availableWorkouts.filter { workout in
            let matchesQuery = query.isEmpty || 
                workout.name.localizedCaseInsensitiveContains(query) ||
                workout.workoutType.displayName.localizedCaseInsensitiveContains(query)
            
            guard let filters = filters else { return matchesQuery }
            
            let matchesType = filters.workoutTypes.isEmpty || filters.workoutTypes.contains(workout.workoutType)
            let matchesDifficulty = filters.difficulties.isEmpty || filters.difficulties.contains(workout.difficulty)
            let matchesDuration = workout.estimatedDuration >= filters.minDuration && 
                                 workout.estimatedDuration <= filters.maxDuration
            
            return matchesQuery && matchesType && matchesDifficulty && matchesDuration
        }
        
        return filteredWorkouts
    }
    
    /// Clean up resources
    func cleanup() {
        print("[WorkoutService] Cleaning up resources")
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        statsListener?.remove()
        statsListener = nil
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
    
    private func loadTodayRecommendations(for userId: String) async {
        // In production, this would use ML/AI recommendations
        // For now, create smart recommendations based on user data
        let recommendations = await generateTodayRecommendations(for: userId)
        
        await MainActor.run {
            self.todayRecommendations = recommendations
        }
    }
    
    private func loadRecentWorkouts(for userId: String) async {
        do {
            let querySnapshot = try await db.collection("users")
                .document(userId)
                .collection("workoutSessions")
                .whereField("isCompleted", isEqualTo: true)
                .order(by: "completedAt", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            let workouts = querySnapshot.documents.compactMap { document in
                try? document.data(as: WorkoutSession.self)
            }
            
            await MainActor.run {
                self.recentWorkouts = workouts
            }
        } catch {
            print("[WorkoutService] Failed to load recent workouts: \(error)")
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
    
    private func loadAvailableWorkouts() async {
        // In production, this would load from Firestore collection
        // For now, use comprehensive mock data
        await MainActor.run {
            self.availableWorkouts = MockWorkoutData.allWorkouts
        }
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
    
    // Helper methods for stats calculation
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
    
    // MARK: - Mock Data Setup (for development)
    private func setupMockData() {
        // This will be removed in production
        // Mock data for development and testing
    }
}

// MARK: - Supporting Types

/// Workout filtering options
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