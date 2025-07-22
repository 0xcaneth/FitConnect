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
    @Published var motivationMessage: String = ""
    @Published var showMotivation: Bool = false
    
    // FIXED: Add totalExercises property
    var totalExercises: Int {
        return exercises.count
    }
    
    // Computed Properties
    var overallProgress: Double {
        guard !exercises.isEmpty else { return 0.0 }
        
        let totalExercises = Double(exercises.count)
        var completedProgress = 0.0
        
        // Add full progress for completed exercises
        completedProgress += Double(currentExerciseIndex)
        
        // Add partial progress for current exercise
        if currentExerciseIndex < exercises.count {
            if let currentEx = currentExercise {
                if currentEx.isTimeBasedExercise {
                    // For time-based exercises, calculate progress based on time elapsed
                    if let totalTime = currentEx.duration, totalTime > 0 {
                        let timeElapsed = totalTime - exerciseTimeRemaining
                        let exerciseProgress = max(0.0, min(1.0, timeElapsed / totalTime))
                        completedProgress += exerciseProgress
                    }
                } else {
                    // For rep-based exercises, calculate progress based on completed sets
                    if totalSets > 0 {
                        let setProgress = Double(currentSet - 1) / Double(totalSets)
                        
                        // Add partial progress for current set reps
                        if targetReps > 0 {
                            let repProgress = Double(repsCompleted) / Double(targetReps) / Double(totalSets)
                            completedProgress += setProgress + repProgress
                        } else {
                            completedProgress += setProgress
                        }
                    }
                }
            }
        }
        
        let finalProgress = min(1.0, completedProgress / totalExercises)
        print("[WorkoutEngine] Progress: \(Int(finalProgress * 100))% - Exercise \(currentExerciseIndex + 1)/\(exercises.count)")
        
        return finalProgress
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
            return currentSet > totalSets
        }
    }
    
    var currentSetProgress: String {
        guard let exercise = currentExercise, !exercise.isTimeBasedExercise else { return "" }
        return "Set \(currentSet)/\(totalSets)"
    }
    
    var currentRepProgress: String {
        guard let exercise = currentExercise, !exercise.isTimeBasedExercise else { return "" }
        return "\(repsCompleted)/\(targetReps) reps"
    }
    
    // MARK: - Private Properties
    private var workout: WorkoutSession?
    private var exercises: [WorkoutExercise] = []
    private var exerciseTimer: Timer?
    private var restTimer: Timer?
    private var motivationTimer: Timer?
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
        print("[WorkoutEngine] Initializing workout: \(workout.name)")
        
        self.workout = workout
        self.exercises = workout.exercises
        
        if !exercises.isEmpty {
            setupCurrentExercise(at: 0)
            
            // CRITICAL: Pre-load videos for better UX
            let exerciseNames = exercises.map { $0.name }
            print("[WorkoutEngine] Pre-loading videos for: \(exerciseNames)")
            ExerciseVideoService.shared.prefetchVideos(for: exerciseNames)
            print("[WorkoutEngine] Started pre-loading \(exerciseNames.count) videos")
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
        
        print("[WorkoutEngine] Workout initialized with \(exercises.count) exercises")
    }
    
    // MARK: - Workout Control
    
    func startWorkout() {
        print("[WorkoutEngine] Starting workout")
        
        guard !exercises.isEmpty else {
            print("[WorkoutEngine] Cannot start workout - no exercises")
            return
        }
        
        isWorkoutActive = true
        isPaused = false
        workoutStartTime = Date()
        completionData.startTime = Date()
        
        startCurrentExercise()
    }
    
    func pauseWorkout() {
        print("[WorkoutEngine] Pausing workout")
        
        isPaused = true
        exerciseTimer?.invalidate()
        restTimer?.invalidate()
        
        // Track pause time for accurate duration calculation
        if let startTime = exerciseStartTime {
            totalWorkoutDuration += Date().timeIntervalSince(startTime)
        }
    }
    
    func resumeWorkout() {
        print("[WorkoutEngine] Resuming workout")
        
        isPaused = false
        exerciseStartTime = Date()
        
        if isRestTime {
            startRestTimer()
        } else {
            startExerciseTimer()
        }
    }
    
    func completeWorkout() {
        print("[WorkoutEngine] Completing workout")
        
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
        
        print("[WorkoutEngine] Workout completed - Duration: \(Int(totalWorkoutDuration/60)) min, Calories: \(totalCaloriesBurned)")
    }
    
    // MARK: - Exercise Control
    
    func startCurrentExercise() {
        guard let exercise = currentExercise else { return }
        
        print("[WorkoutEngine] Starting exercise: \(exercise.name) - Set \(currentSet)/\(totalSets)")
        
        exerciseStartTime = Date()
        isRestTime = false
        
        // Show motivation message
        showMotivationMessage(getExerciseMotivation())
        
        // Setup exercise parameters
        if exercise.isTimeBasedExercise {
            exerciseTimeRemaining = exercise.duration ?? 30
        } else {
            targetReps = exercise.reps ?? 10
            totalSets = exercise.sets ?? 1
            repsCompleted = 0
        }
    }
    
    func completeExercise() {
        guard let exercise = currentExercise else { return }
        
        print("[WorkoutEngine] Exercise completed: \(exercise.name)")
        
        // Record completed exercise with all sets data
        let completedExercise = CompletedExercise(
            exercise: exercise,
            setsCompleted: totalSets,
            repsPerSet: exercise.isTimeBasedExercise ? [] : Array(repeating: targetReps, count: totalSets),
            duration: Date().timeIntervalSince(exerciseStartTime ?? Date()),
            caloriesBurned: calculateExerciseCalories(exercise)
        )
        
        completedExercises.append(completedExercise)
        totalCaloriesBurned += completedExercise.caloriesBurned
        
        exerciseTimer?.invalidate()
        
        // Progress will update automatically when currentExerciseIndex changes
        
        // Move to next exercise or complete workout
        if hasNextExercise {
            // Move to next exercise immediately
            currentExerciseIndex += 1
            setupCurrentExercise(at: currentExerciseIndex)
            startRestPeriod()
            
            // Force UI update for progress
            print("[WorkoutEngine] Moving to exercise \(currentExerciseIndex + 1)/\(exercises.count)")
        } else {
            completeWorkout()
        }
    }
    
    func startNextExercise() {
        print("[WorkoutEngine] Moving to next exercise")
        
        startCurrentExercise()
    }
    
    func startExerciseTimer() {
        guard let exercise = currentExercise, exercise.isTimeBasedExercise else { return }
        
        print("[WorkoutEngine] Manual timer start for: \(exercise.name)")
        
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                
                self.exerciseTimeRemaining -= 1
                
                // Print progress updates for debugging
                if Int(self.exerciseTimeRemaining) % 5 == 0 {
                    print("[WorkoutEngine] Time remaining: \(Int(self.exerciseTimeRemaining))s - Progress: \(Int(self.overallProgress * 100))%")
                }
                
                if self.exerciseTimeRemaining <= 0 {
                    self.exerciseTimer?.invalidate()
                    self.completeExercise()
                }
            }
        }
    }
    
    func pauseExerciseTimer() {
        exerciseTimer?.invalidate()
    }
    
    // MARK: - Set/Rep Control
    
    func incrementRep() {
        guard !isPaused, let exercise = currentExercise, !exercise.isTimeBasedExercise else { return }
        
        repsCompleted += 1
        print("[WorkoutEngine] Rep completed: \(repsCompleted)/\(targetReps) - Progress: \(Int(overallProgress * 100))%")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Check if set is completed
        if repsCompleted >= targetReps {
            completeSet()
        }
    }
    
    func completeSet() {
        guard let exercise = currentExercise, !exercise.isTimeBasedExercise else { return }
        
        print("[WorkoutEngine] Set completed: \(currentSet)/\(totalSets) - Progress: \(Int(overallProgress * 100))%")
        
        // Show celebration
        showMotivationMessage("Set completed! Great job!")
        
        // Check if this was the last set of the current exercise
        if currentSet >= totalSets {
            // All sets completed for this exercise, move to next exercise
            completeExercise()
        } else {
            // Move to next set of the same exercise
            currentSet += 1
            repsCompleted = 0
            
            // Start short rest between sets (same exercise)
            startSetRestPeriod()
        }
    }
    
    func skipCurrentSet() {
        guard let exercise = currentExercise, !exercise.isTimeBasedExercise else { return }
        
        if currentSet >= totalSets {
            completeExercise()
        } else {
            currentSet += 1
            repsCompleted = 0
            startCurrentExercise()
        }
    }
    
    // MARK: - Rest Control
    
    func startRestPeriod() {
        print("[WorkoutEngine] Starting rest period between exercises")
        
        isRestTime = true
        restTimeRemaining = defaultRestDuration
        motivationMessage = "Great work! Rest and prepare for the next exercise"
        showMotivation = true
        startRestTimer()
    }
    
    func skipRest() {
        print("[WorkoutEngine] Skipping rest period")
        
        restTimer?.invalidate()
        
        isRestTime = false
        restTimeRemaining = 0
        showMotivation = false
        
        if currentSet <= totalSets, let _ = currentExercise {
            startCurrentExercise()
        } else {
            startNextExercise()
        }
    }
    
    private func startSetRestPeriod() {
        print("[WorkoutEngine] Starting rest between sets")
        
        isRestTime = true
        restTimeRemaining = setRestDuration
        motivationMessage = "Quick rest between sets. You're doing great!"
        showMotivation = true
        startRestTimer()
    }
    
    // MARK: - Timer Management
    
    private func startRestTimer() {
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, !self.isPaused else { return }
                
                self.restTimeRemaining -= 1
                
                if self.restTimeRemaining <= 0 {
                    self.restTimer?.invalidate()
                    self.isRestTime = false
                    self.showMotivation = false
                    
                    self.startCurrentExercise()
                }
            }
        }
    }
    
    // MARK: - Motivation System
    
    private func showMotivationMessage(_ message: String) {
        motivationMessage = message
        showMotivation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showMotivation = false
        }
    }
    
    private func getExerciseMotivation() -> String {
        guard let exercise = currentExercise else { return "You've got this! " }
        
        switch exercise.exerciseType {
        case .strength:
            let messages = [
                "Feel the strength building! ",
                "Every rep makes you stronger! ",
                "Power through, champion! ",
                "Build that muscle! "
            ]
            return messages.randomElement() ?? "You've got this! "
        case .cardio:
            let messages = [
                "Your heart is getting stronger! ",
                "Keep that energy flowing! ",
                "Push through, you're amazing! ",
                "Every beat counts! "
            ]
            return messages.randomElement() ?? "Keep going! "
        default:
            return "You're doing great! Keep it up! "
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupCurrentExercise(at index: Int) {
        guard index < exercises.count else { return }
        
        let exercise = exercises[index]
        currentExercise = exercise
        currentExerciseIndex = index
        
        if !exercise.isTimeBasedExercise {
            currentSet = 1
            totalSets = exercise.sets ?? 1
            repsCompleted = 0
            targetReps = exercise.reps ?? 10
        }
        
        print("[WorkoutEngine]  Setup exercise \(index + 1)/\(exercises.count): \(exercise.name)")
    }
    
    private func calculateExerciseCalories(_ exercise: WorkoutExercise) -> Int {
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
        motivationTimer?.invalidate()
    }
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
        print("[MotivationEngine]  Started motivation session for \(workoutType.displayName)")
    }
    
    func getExerciseMotivation(exercise: WorkoutExercise?) -> String {
        guard let exercise = exercise else { return "" }
        
        let messages = getMotivationMessages(for: exercise)
        return messages.randomElement() ?? "You've got this! "
    }
    
    func getRestMotivation() -> String {
        let restMessages = [
            "Take your time, you're doing great! ",
            "Perfect form is better than rushed reps! ",
            "Breathe deep, recover strong! ",
            "Your body is getting stronger with every rep! ",
            "Rest now, dominate the next exercise! ",
            "Quality over quantity, always! ",
            "Feel that burn? That's progress! ",
            "You're tougher than you think! "
        ]
        
        return restMessages.randomElement() ?? "Keep it up!"
    }
    
    func celebrateSetCompletion(set: Int, totalSets: Int) {
        print("[MotivationEngine]  Set \(set)/\(totalSets) completed!")
        
        // Could trigger confetti animation or other celebration UI
    }
    
    func celebrateExerciseCompletion(exercise: String) {
        print("[MotivationEngine]  Exercise completed: \(exercise)")
        
        // Could trigger success animation
    }
    
    private func getMotivationMessages(for exercise: WorkoutExercise) -> [String] {
        switch exercise.exerciseType {
        case .strength:
            return [
                "Feel the strength building! ",
                "Every rep makes you stronger! ",
                "Power through, champion! ",
                "Your future self thanks you! ",
                "Strength isn't given, it's earned! "
            ]
            
        case .cardio:
            return [
                "Your heart is getting stronger! ",
                "Push through, you're amazing! ",
                "Every beat counts! ",
                "Endurance is your superpower! ",
                "Keep that energy flowing! "
            ]
            
        case .flexibility:
            return [
                "Breathe into the stretch! ",
                "Flexibility is freedom! ",
                "Your body will thank you later! ",
                "Find your flow! ",
                "Gentle progress is still progress! "
            ]
            
        case .balance:
            return [
                "Find your center! ",
                "Balance builds core strength! ",
                "Steady wins the race! ",
                "You're more stable than you know! "
            ]
            
        case .plyometric:
            return [
                "Explosive power! ",
                "Jump higher, land stronger! ",
                "Athletic power building! ",
                "Every jump builds athleticism! "
            ]
            
        case .endurance:
            return [
                "Building unstoppable endurance! ",
                "Mile by mile, you're getting stronger! ",
                "Endurance is mental strength! ",
                "You can go the distance! "
            ]
            
        case .warmup:
            return [
                "Perfect warm-up sets you up for success! ",
                "Get those muscles ready! ",
                "Smart training starts with warmup! ",
                "Preparing for greatness! "
            ]
            
        case .cooldown:
            return [
                "Great job! Time to recover right! ",
                "Cool down helps you come back stronger! ",
                "Recovery is part of the workout! ",
                "Perfect way to finish strong! "
            ]
        }
    }
}