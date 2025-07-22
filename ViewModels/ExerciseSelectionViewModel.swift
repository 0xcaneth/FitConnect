import Foundation
import SwiftUI

@MainActor
class ExerciseSelectionViewModel: ObservableObject {
    @Published var exercises: [WorkoutExercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var networkError = false
    
    private let videoService = ExerciseVideoService.shared
    
    func loadExercises(for workoutType: WorkoutType) {
        isLoading = true
        errorMessage = nil
        networkError = false
        
        Task {
            do {
                print("[ExerciseSelectionVM] 🚀 Loading exercises for \(workoutType.displayName)")
                
                // Get exercises from WorkoutService Firebase data only
                let workoutService = WorkoutService.shared
                let firebaseExercises = await getExercisesFromFirebase(for: workoutType, workoutService: workoutService)
                
                if firebaseExercises.isEmpty {
                    // No Firebase data available - show error
                    await MainActor.run {
                        self.errorMessage = "No exercises available for \(workoutType.displayName) at the moment. Please check back later or try a different category."
                        self.networkError = true
                        self.isLoading = false
                    }
                    return
                }
                
                // Load videos for Firebase exercises
                let exercisesWithVideos = await loadVideosForExercises(firebaseExercises)
                
                await MainActor.run {
                    self.exercises = exercisesWithVideos
                    self.isLoading = false
                    print("[ExerciseSelectionVM] ✅ Successfully loaded \(exercisesWithVideos.count) exercises")
                }
                
                // Start background prefetching for better user experience
                let exerciseNames = exercisesWithVideos.map { $0.name }
                videoService.prefetchVideos(for: exerciseNames)
                
            } catch {
                print("[ExerciseSelectionVM] ❌ Error loading exercises: \(error)")
                await MainActor.run {
                    self.errorMessage = "Unable to load exercises. Please check your internet connection and try again."
                    self.networkError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadVideosForExercises(_ exercises: [WorkoutExercise]) async -> [WorkoutExercise] {
        print("[ExerciseSelectionVM] 📹 Loading videos for \(exercises.count) exercises...")
        
        var updatedExercises: [WorkoutExercise] = []
        
        // Process exercises in batches to avoid overwhelming the API
        let batchSize = 3
        let batches = exercises.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            print("[ExerciseSelectionVM] Processing batch \(batchIndex + 1)/\(batches.count)")
            
            await withTaskGroup(of: WorkoutExercise.self) { group in
                for exercise in batch {
                    group.addTask {
                        return await self.loadVideoForExercise(exercise)
                    }
                }
                
                for await updatedExercise in group {
                    updatedExercises.append(updatedExercise)
                }
            }
            
            // Small delay between batches to respect rate limits
            if batchIndex < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
        }
        
        print("[ExerciseSelectionVM] ✅ Finished loading videos for \(updatedExercises.count) exercises")
        return updatedExercises.sorted { $0.name < $1.name }
    }
    
    private func loadVideoForExercise(_ exercise: WorkoutExercise) async -> WorkoutExercise {
        // If exercise already has a video URL, validate and use it
        if let existingVideoURL = exercise.videoURL, 
           !existingVideoURL.isEmpty,
           URL(string: existingVideoURL) != nil {
            print("[ExerciseSelectionVM] ✅ Exercise \(exercise.name) already has video")
            return exercise
        }
        
        // Fetch video from Firebase Storage via ExerciseVideoService
        if let videoURL = await videoService.fetchExerciseVideo(for: exercise.name) {
            print("[ExerciseSelectionVM] 📹 Loaded video for \(exercise.name)")
            return WorkoutExercise(
                name: exercise.name,
                description: exercise.description,
                targetMuscleGroups: exercise.targetMuscleGroups,
                sets: exercise.sets,
                reps: exercise.reps,
                duration: exercise.duration,
                restTime: exercise.restTime,
                weight: exercise.weight,
                distance: exercise.distance,
                instructions: exercise.instructions,
                imageURL: exercise.imageURL,
                videoURL: videoURL.absoluteString,
                caloriesPerMinute: exercise.caloriesPerMinute,
                exerciseIcon: exercise.exerciseIcon
            )
        }
        
        print("[ExerciseSelectionVM] ⚠️ No video found for \(exercise.name)")
        return exercise
    }
    
    @MainActor
    private func getExercisesFromFirebase(for workoutType: WorkoutType, workoutService: WorkoutService) async -> [WorkoutExercise] {
        print("[ExerciseSelectionVM] 🔍 Searching Firebase for: \(workoutType.rawValue)")
        
        // Wait for templates if they're still loading (with timeout)
        var attempts = 0
        let maxAttempts = 15 // 7.5 seconds max wait
        
        while workoutService.workoutTemplates.isEmpty && attempts < maxAttempts {
            print("[ExerciseSelectionVM] ⏳ Waiting for Firebase templates... (attempt \(attempts + 1)/\(maxAttempts))")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            attempts += 1
        }
        
        if workoutService.workoutTemplates.isEmpty {
            print("[ExerciseSelectionVM] ❌ No Firebase templates loaded after \(maxAttempts) attempts")
            return []
        }
        
        // Get exercises from Firebase workout templates
        let matchingWorkouts = workoutService.workoutTemplates.filter { template in
            template.workoutType == workoutType
        }
        
        print("[ExerciseSelectionVM] 📊 Found \(matchingWorkouts.count) templates for \(workoutType.rawValue)")
        
        var allExercises: [WorkoutExercise] = []
        
        for workout in matchingWorkouts {
            print("[ExerciseSelectionVM] 📋 Processing: \(workout.name) (\(workout.exercises.count) exercises)")
            allExercises.append(contentsOf: workout.exercises)
        }
        
        print("[ExerciseSelectionVM] 🎯 Total exercises collected: \(allExercises.count)")
        return allExercises
    }
    
    func retryLoading(for workoutType: WorkoutType) {
        print("[ExerciseSelectionVM] 🔄 Retrying to load exercises for \(workoutType.displayName)")
        loadExercises(for: workoutType)
    }
    
    func getFilteredExercises(
        for workoutType: WorkoutType,
        muscleGroup: MuscleGroup?,
        difficulty: DifficultyLevel?,
        searchText: String
    ) -> [WorkoutExercise] {
        var filtered = exercises
        
        // Filter by muscle group
        if let muscleGroup = muscleGroup {
            filtered = filtered.filter { exercise in
                exercise.targetMuscleGroups.contains(muscleGroup)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
                exercise.targetMuscleGroups.contains { muscle in
                    muscle.displayName.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private func generateExercises(for workoutType: WorkoutType) throws -> [WorkoutExercise] {
        switch workoutType {
        case .strength:
            return [
                WorkoutExercise(
                    name: "Push-ups",
                    description: "Classic upper body exercise targeting chest, shoulders, and triceps",
                    targetMuscleGroups: [.chest, .shoulders, .arms],
                    sets: 3,
                    reps: 12,
                    duration: nil,
                    restTime: 60,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Start in plank position with hands shoulder-width apart",
                        "Lower your body until chest nearly touches the floor",
                        "Push back up to starting position",
                        "Keep your core tight throughout the movement"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 8.0,
                    exerciseIcon: "figure.strengthtraining.functional.pushup"
                ),
                WorkoutExercise(
                    name: "Squats",
                    description: "Lower body compound exercise for legs and glutes",
                    targetMuscleGroups: [.legs, .glutes],
                    sets: 3,
                    reps: 15,
                    duration: nil,
                    restTime: 60,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Stand with feet shoulder-width apart",
                        "Lower by bending knees and hips",
                        "Keep chest up and knees tracking over toes",
                        "Return to standing position"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 10.0,
                    exerciseIcon: "figure.squat"
                ),
                WorkoutExercise(
                    name: "Plank",
                    description: "Core stability exercise for abs and overall strength",
                    targetMuscleGroups: [.abs, .fullBody],
                    sets: 3,
                    reps: nil,
                    duration: 60,
                    restTime: 30,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Start in push-up position",
                        "Keep body in straight line from head to heels",
                        "Engage core and hold position",
                        "Breathe normally throughout"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 6.0,
                    exerciseIcon: "figure.core.training"
                ),
                WorkoutExercise(
                    name: "Lunges",
                    description: "Single-leg exercise for legs and balance",
                    targetMuscleGroups: [.legs, .glutes],
                    sets: 3,
                    reps: 12,
                    duration: nil,
                    restTime: 60,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Step forward with one leg",
                        "Lower hips until both knees are bent at 90 degrees",
                        "Push back to starting position",
                        "Alternate legs or complete all reps on one side"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 9.5,
                    exerciseIcon: "figure.lunge"
                )
            ]
        case .cardio:
            return [
                WorkoutExercise(
                    name: "Burpees",
                    description: "Full-body cardio exercise combining squat, plank, and jump",
                    targetMuscleGroups: [.fullBody, .cardio],
                    sets: 3,
                    reps: 10,
                    duration: nil,
                    restTime: 45,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Start in standing position",
                        "Drop into squat and place hands on floor",
                        "Jump feet back into plank position",
                        "Jump feet forward and leap up with arms overhead"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 15.0,
                    exerciseIcon: "figure.jump"
                ),
                WorkoutExercise(
                    name: "Jumping Jacks",
                    description: "Classic cardio exercise for full-body conditioning",
                    targetMuscleGroups: [.fullBody, .cardio],
                    sets: 3,
                    reps: 30,
                    duration: nil,
                    restTime: 30,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Start with feet together, arms at sides",
                        "Jump feet apart while raising arms overhead",
                        "Jump back to starting position",
                        "Maintain steady rhythm"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 12.0,
                    exerciseIcon: "figure.jumprope"
                )
            ]
        case .dance:
            return [
                WorkoutExercise(
                    name: "Ballet Relevé",
                    description: "Rising onto balls of feet for calf strength and balance",
                    targetMuscleGroups: [.calves, .legs],
                    sets: 3,
                    reps: 16,
                    duration: nil,
                    restTime: 45,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Stand in first position with heels together",
                        "Slowly rise up onto balls of feet",
                        "Hold briefly at the top",
                        "Lower heels to floor with control",
                        "Keep core engaged and shoulders down"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 4.0,
                    exerciseIcon: "figure.ballet"
                ),
                WorkoutExercise(
                    name: "Body Rolls",
                    description: "Fluid movement flowing through spine and torso",
                    targetMuscleGroups: [.abs, .back],
                    sets: 3,
                    reps: 6,
                    duration: nil,
                    restTime: 30,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Stand with feet shoulder-width apart",
                        "Start movement from head, rolling down through spine",
                        "Continue roll through chest, abs, and hips",
                        "Reverse movement, rolling back up to start",
                        "Keep movement smooth and controlled"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 6.0,
                    exerciseIcon: "waveform.circle"
                ),
                WorkoutExercise(
                    name: "Cha-Cha Basic",
                    description: "Fundamental Latin dance step with triple rhythm",
                    targetMuscleGroups: [.legs, .glutes, .cardio],
                    sets: 4,
                    reps: 8,
                    duration: nil,
                    restTime: 45,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Step forward on right foot (count 1)",
                        "Transfer weight to left foot in place (count 2)",
                        "Step right-left-right in place (cha-cha-cha)",
                        "Step back on left foot, then forward on right",
                        "Maintain hip action and bent knees"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 9.0,
                    exerciseIcon: "music.note"
                ),
                WorkoutExercise(
                    name: "Grapevine",
                    description: "Classic dance step moving laterally with crossing feet",
                    targetMuscleGroups: [.legs, .cardio],
                    sets: 3,
                    reps: 8,
                    duration: nil,
                    restTime: 30,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Step right foot to right side",
                        "Cross left foot behind right foot",
                        "Step right foot to right side again",
                        "Tap left foot next to right foot",
                        "Reverse direction, leading with left foot"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 8.0,
                    exerciseIcon: "figure.dance"
                ),
                WorkoutExercise(
                    name: "Hip Hop Bounce",
                    description: "Basic bounce movement fundamental to hip hop dance",
                    targetMuscleGroups: [.legs, .cardio],
                    sets: 1,
                    reps: nil,
                    duration: 60,
                    restTime: 30,
                    weight: nil,
                    distance: nil,
                    instructions: [
                        "Stand with feet shoulder-width apart",
                        "Bounce rhythmically by bending knees slightly",
                        "Keep weight on balls of feet",
                        "Add subtle shoulder and arm movements",
                        "Stay relaxed and find your natural rhythm"
                    ],
                    imageURL: nil,
                    videoURL: nil, // Will be loaded from API
                    caloriesPerMinute: 10.0,
                    exerciseIcon: "figure.dance"
                )
            ]
        default:
            return []
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}