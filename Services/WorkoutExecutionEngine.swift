import Foundation
import Combine
import AVFoundation
import UIKit

/// Real-time workout execution engine
/// Manages workout state, timers, and progress tracking
@MainActor
final class WorkoutExecutionEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentExercise: WorkoutExercise?
    @Published var currentExerciseIndex: Int = 0
    @Published var currentSet: Int = 1
    @Published var totalSets: Int = 1
    @Published var repsCompleted: Int = 0
    @Published var targetReps: Int = 0
    @Published var exerciseTimeRemaining: TimeInterval = 0
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var isWorkoutActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var isRestTime: Bool = false
    @Published var isCompleted: Bool = false
    @Published var completionData: WorkoutCompletionData = WorkoutCompletionData()
    
    // Computed Properties
    var overallProgress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(exercises.count)
    }
    
    var nextExercise: WorkoutExercise? {
        guard currentExerciseIndex + 1 < exercises.count else { return nil }
        return exercises[currentExerciseIndex + 1]
    }
    
    var hasNextExercise: Bool {
        return currentExerciseIndex + 1 < exercises.count
    }
    
    var isExerciseCompleted: Bool {
        guard let exercise = currentExercise else { return false }
        
        if exercise.isTimeBasedExercise {
            return exerciseTimeRemaining <= 0
        } else {
            return currentSet > (exercise.sets ?? 1)
        }
    }
    
    // MARK: - Private Properties
    private var workout: WorkoutSession?
    private var exercises: [WorkoutExercise] = []
    private var exerciseTimer: Timer?
    private var restTimer: Timer?
    private var workoutStartTime: Date?
    private var exerciseStartTime: Date?
    private var totalWorkoutDuration: TimeInterval = 0
    private var totalCaloriesBurned: Int = 0
    private var completedExercises: [CompletedExercise] = []
    
    // MARK: - Configuration
    private let defaultRestDuration: TimeInterval = 30 // 30 seconds between exercises
    private let setRestDuration: TimeInterval = 15 // 15 seconds between sets
    
    // MARK: - Initialization
    
    func initialize(with workout: WorkoutSession) {
        print("[WorkoutEngine] 🚀 Initializing workout: \(workout.name)")
        
        self.workout = workout
        self.exercises = workout.exercises
        
        if !exercises.isEmpty {
            setupCurrentExercise(at: 0)
        }
        
        // Initialize completion data
        completionData = WorkoutCompletionData(
            workoutId: workout.id,
            workoutName: workout.name,
            workoutType: workout.workoutType,
            startTime: Date(),
            endTime: nil,
            totalDuration: 0,
            totalCaloriesBurned: 0,
            completedExercises: [],
            isFullyCompleted: false,
            userRating: nil
        )
        
        print("[WorkoutEngine] ✅ Workout initialized with \(exercises.count) exercises")
    }
    
    // MARK: - Workout Control
    
    func startWorkout() {
        print("[WorkoutEngine] ▶️ Starting workout")
        
        guard !exercises.isEmpty else {
            print("[WorkoutEngine] ❌ Cannot start workout - no exercises")
            return
        }
        
        isWorkoutActive = true
        isPaused = false
        workoutStartTime = Date()
        completionData.startTime = Date()
        
        startCurrentExercise()
    }
    
    func pauseWorkout() {
        print("[WorkoutEngine] ⏸️ Pausing workout")
        
        isPaused = true
        exerciseTimer?.invalidate()
        restTimer?.invalidate()
        
        // Track pause time for accurate duration calculation
        if let startTime = exerciseStartTime {
            totalWorkoutDuration += Date().timeIntervalSince(startTime)
        }
    }
    
    func resumeWorkout() {
        print("[WorkoutEngine] ▶️ Resuming workout")
        
        isPaused = false
        exerciseStartTime = Date()
        
        if isRestTime {
            startRestTimer()
        } else {
            startExerciseTimer()
        }
    }
    
    func completeWorkout() {
        print("[WorkoutEngine] 🏁 Completing workout")
        
        isWorkoutActive = false
        isCompleted = true
        
        // Calculate final stats
        if let startTime = workoutStartTime {
            totalWorkoutDuration = Date().timeIntervalSince(startTime)
        }
        
        // Finalize completion data
        completionData.endTime = Date()
        completionData.totalDuration = totalWorkoutDuration
        completionData.completedExercises = completedExercises
        completionData.totalCaloriesBurned = totalCaloriesBurned
        completionData.isFullyCompleted = currentExerciseIndex >= exercises.count - 1
        
        // Clean up timers
        exerciseTimer?.invalidate()
        restTimer?.invalidate()
        
        print("[WorkoutEngine] ✅ Workout completed - Duration: \(Int(totalWorkoutDuration/60)) min, Calories: \(totalCaloriesBurned)")
    }
    
    // MARK: - Exercise Control
    
    func startCurrentExercise() {
        guard let exercise = currentExercise else { return }
        
        print("[WorkoutEngine] 🏋️ Starting exercise: \(exercise.name)")
        
        exerciseStartTime = Date()
        isRestTime = false
        
        // Setup exercise parameters
        if exercise.isTimeBasedExercise {
            exerciseTimeRemaining = exercise.duration ?? 30
            startExerciseTimer()
        } else {
            targetReps = exercise.reps ?? 10
            totalSets = exercise.sets ?? 3
            currentSet = 1
            repsCompleted = 0
        }
    }
    
    func completeExercise() {
        guard let exercise = currentExercise else { return }
        
        print("[WorkoutEngine] ✅ Exercise completed: \(exercise.name)")
        
        // Record completed exercise
        let completedExercise = CompletedExercise(
            exercise: exercise,
            setsCompleted: currentSet,
            repsPerSet: exercise.isTimeBasedExercise ? [] : [repsCompleted],
            duration: Date().timeIntervalSince(exerciseStartTime ?? Date()),
            caloriesBurned: calculateExerciseCalories(exercise)
        )
        
        completedExercises.append(completedExercise)
        totalCaloriesBurned += completedExercise.caloriesBurned
        
        exerciseTimer?.invalidate()
    }
    
    func startNextExercise() {
        guard hasNextExercise else {
            completeWorkout()
            return
        }
        
        currentExerciseIndex += 1
        setupCurrentExercise(at: currentExerciseIndex)
        startCurrentExercise()
    }
    
    func skipRest() {
        print("[WorkoutEngine] ⏭️ Skipping rest")
        
        restTimer?.invalidate()
        isRestTime = false
        startNextExercise()
    }
    
    // MARK: - Set/Rep Control
    
    func incrementRep() {
        guard !isPaused, let exercise = currentExercise, !exercise.isTimeBasedExercise else { return }
        
        repsCompleted += 1
        print("[WorkoutEngine] 💪 Rep completed: \(repsCompleted)/\(targetReps)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func completeSet() {
        guard let exercise = currentExercise, !exercise.isTimeBasedExercise else { return }
        
        print("[WorkoutEngine] 📝 Set completed: \(currentSet)/\(totalSets)")
        
        currentSet += 1
        repsCompleted = 0
        
        // Check if this was the last set
        if currentSet > totalSets {
            completeExercise()
        } else {
            // Start short rest between sets
            startSetRestPeriod()
        }
    }
    
    // MARK: - Rest Control
    
    func startRestPeriod() {
        print("[WorkoutEngine] 😴 Starting rest period")
        
        isRestTime = true
        restTimeRemaining = defaultRestDuration
        startRestTimer()
    }
    
    private func startSetRestPeriod() {
        print("[WorkoutEngine] ⏱️ Starting set rest")
        
        isRestTime = true
        restTimeRemaining = setRestDuration
        startRestTimer()
    }
    
    // MARK: - Timer Management
    
    private func startExerciseTimer() {
        guard let exercise = currentExercise, exercise.isTimeBasedExercise else { return }
        
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                
                self.exerciseTimeRemaining -= 1
                
                if self.exerciseTimeRemaining <= 0 {
                    self.exerciseTimer?.invalidate()
                    self.completeExercise()
                    
                    if self.hasNextExercise {
                        self.startRestPeriod()
                    } else {
                        self.completeWorkout()
                    }
                }
            }
        }
    }
    
    private func startRestTimer() {
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                
                self.restTimeRemaining -= 1
                
                if self.restTimeRemaining <= 0 {
                    self.restTimer?.invalidate()
                    self.isRestTime = false
                    
                    if self.currentSet <= self.totalSets {
                        // Continue with next set
                        self.startCurrentExercise()
                    } else {
                        // Move to next exercise
                        self.startNextExercise()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupCurrentExercise(at index: Int) {
        guard index < exercises.count else { return }
        
        currentExercise = exercises[index]
        currentExerciseIndex = index
        
        print("[WorkoutEngine] 📋 Setup exercise \(index + 1)/\(exercises.count): \(exercises[index].name)")
    }
    
    private func calculateExerciseCalories(_ exercise: WorkoutExercise) -> Int {
        // Simplified calorie calculation based on exercise type and duration
        let baseBurnRate: Double = switch exercise.exerciseType {
        case .strength: 8.0 // calories per minute
        case .cardio: 12.0
        case .flexibility: 3.0
        case .balance: 4.0
        case .plyometric: 15.0
        case .endurance: 10.0
        case .warmup: 5.0
        case .cooldown: 4.0
        }
        
        let duration = Date().timeIntervalSince(exerciseStartTime ?? Date()) / 60.0 // minutes
        return Int(baseBurnRate * duration)
    }
    
    func getPartialCompletionData() -> WorkoutCompletionData {
        // Return current completion data for partial saves
        var partialData = completionData
        partialData.endTime = Date()
        partialData.totalDuration = Date().timeIntervalSince(workoutStartTime ?? Date())
        partialData.completedExercises = completedExercises
        partialData.totalCaloriesBurned = totalCaloriesBurned
        partialData.isFullyCompleted = false
        
        return partialData
    }
    
    deinit {
        exerciseTimer?.invalidate()
        restTimer?.invalidate()
    }
}

// MARK: - Workout Completion Data

struct WorkoutCompletionData: Codable {
    var workoutId: String?
    var workoutName: String = ""
    var workoutType: WorkoutType = .cardio
    var startTime: Date = Date()
    var endTime: Date?
    var totalDuration: TimeInterval = 0
    var completedExercises: [CompletedExercise] = []
    var totalCaloriesBurned: Int = 0
    var isFullyCompleted: Bool = false
    var userRating: Int?
    
    var completionPercentage: Double {
        // This would be calculated based on exercises completed vs total
        return isFullyCompleted ? 1.0 : 0.5
    }
    
    // MARK: - Custom Initializers
    init() {
        // Default initializer
    }
    
    init(
        workoutId: String? = nil,
        workoutName: String = "",
        workoutType: WorkoutType = .cardio,
        startTime: Date = Date(),
        endTime: Date? = nil,
        totalDuration: TimeInterval = 0,
        totalCaloriesBurned: Int = 0,
        completedExercises: [CompletedExercise] = [],
        isFullyCompleted: Bool = false,
        userRating: Int? = nil
    ) {
        self.workoutId = workoutId
        self.workoutName = workoutName
        self.workoutType = workoutType
        self.startTime = startTime
        self.endTime = endTime
        self.totalDuration = totalDuration
        self.totalCaloriesBurned = totalCaloriesBurned
        self.completedExercises = completedExercises
        self.isFullyCompleted = isFullyCompleted
        self.userRating = userRating
    }
}

struct CompletedExercise: Codable, Identifiable {
    let id = UUID()
    let exercise: WorkoutExercise
    let setsCompleted: Int
    let repsPerSet: [Int] // For strength exercises
    let duration: TimeInterval
    let caloriesBurned: Int
    let completedAt: Date = Date()
}

// MARK: - Motivation Engine

@MainActor
final class MotivationEngine: ObservableObject {
    
    private var workoutType: WorkoutType = .cardio
    private var motivationLevel: Int = 5 // 1-10 scale
    private var sessionStartTime: Date?
    
    func startSession(workoutType: WorkoutType) {
        self.workoutType = workoutType
        self.sessionStartTime = Date()
        print("[MotivationEngine] 🎯 Started motivation session for \(workoutType.displayName)")
    }
    
    func getExerciseMotivation(exercise: WorkoutExercise?) -> String {
        guard let exercise = exercise else { return "" }
        
        let messages = getMotivationMessages(for: exercise)
        return messages.randomElement() ?? "You've got this! 💪"
    }
    
    func getRestMotivation() -> String {
        let restMessages = [
            "Take your time, you're doing great! 🌟",
            "Perfect form is better than rushed reps! 📐",
            "Breathe deep, recover strong! 🫁",
            "Your body is getting stronger with every rep! 💪",
            "Rest now, dominate the next exercise! 🔥",
            "Quality over quantity, always! ⭐",
            "Feel that burn? That's progress! 🚀",
            "You're tougher than you think! 💎"
        ]
        
        return restMessages.randomElement() ?? "Keep it up!"
    }
    
    func celebrateSetCompletion(set: Int, totalSets: Int) {
        print("[MotivationEngine] 🎉 Set \(set)/\(totalSets) completed!")
        
        // Could trigger confetti animation or other celebration UI
    }
    
    func celebrateExerciseCompletion(exercise: String) {
        print("[MotivationEngine] 🏆 Exercise completed: \(exercise)")
        
        // Could trigger success animation
    }
    
    private func getMotivationMessages(for exercise: WorkoutExercise) -> [String] {
        switch exercise.exerciseType {
        case .strength:
            return [
                "Feel the strength building! 💪",
                "Every rep makes you stronger! 🔥",
                "Power through, champion! ⚡",
                "Your future self thanks you! 🙏",
                "Strength isn't given, it's earned! 💎"
            ]
            
        case .cardio:
            return [
                "Your heart is getting stronger! ❤️",
                "Push through, you're amazing! 🚀",
                "Every beat counts! 💓",
                "Endurance is your superpower! ⚡",
                "Keep that energy flowing! 🌊"
            ]
            
        case .flexibility:
            return [
                "Breathe into the stretch! 🧘‍♀️",
                "Flexibility is freedom! 🕊️",
                "Your body will thank you later! 🙏",
                "Find your flow! 🌊",
                "Gentle progress is still progress! 🌱"
            ]
            
        case .balance:
            return [
                "Find your center! 🎯",
                "Balance builds core strength! 💪",
                "Steady wins the race! 🐢",
                "You're more stable than you know! 🗿"
            ]
            
        case .plyometric:
            return [
                "Explosive power! 💥",
                "Jump higher, land stronger! 🚀",
                "Athletic power building! ⚡",
                "Every jump builds athleticism! 🏃‍♂️"
            ]
            
        case .endurance:
            return [
                "Building unstoppable endurance! 🏃‍♂️",
                "Mile by mile, you're getting stronger! 🛤️",
                "Endurance is mental strength! 🧠",
                "You can go the distance! 🎯"
            ]
            
        case .warmup:
            return [
                "Perfect warm-up sets you up for success! 🌅",
                "Get those muscles ready! 🔥",
                "Smart training starts with warmup! 🧠",
                "Preparing for greatness! ✨"
            ]
            
        case .cooldown:
            return [
                "Great job! Time to recover right! 😌",
                "Cool down helps you come back stronger! 💪",
                "Recovery is part of the workout! 🛁",
                "Perfect way to finish strong! ✅"
            ]
        }
    }
}