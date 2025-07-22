import Foundation
import FirebaseFirestore

// MARK: - Enhanced Workout Models for Production

/// Complete workout session data
struct WorkoutSession: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let workoutType: WorkoutType
    let name: String
    let description: String?
    let estimatedDuration: TimeInterval
    let estimatedCalories: Int
    let difficulty: DifficultyLevel
    let targetMuscleGroups: [MuscleGroup]
    let exercises: [WorkoutExercise]
    let imageURL: String?
    let videoPreviewURL: String?
    let isCompleted: Bool
    let completedAt: Date?
    let actualDuration: TimeInterval?
    let actualCalories: Int?
    let userRating: Int? // 1-5 stars
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Computed ID for UI Safety
    var safeId: String {
        return id ?? UUID().uuidString
    }

    init(
        userId: String,
        workoutType: WorkoutType,
        name: String,
        description: String? = nil,
        estimatedDuration: TimeInterval,
        estimatedCalories: Int,
        difficulty: DifficultyLevel,
        targetMuscleGroups: [MuscleGroup],
        exercises: [WorkoutExercise],
        imageURL: String? = nil,
        videoPreviewURL: String? = nil
    ) {
        // CRITICAL: Generate ID for UI stability
        self.id = UUID().uuidString
        self.userId = userId
        self.workoutType = workoutType
        self.name = name
        self.description = description
        self.estimatedDuration = estimatedDuration
        self.estimatedCalories = estimatedCalories
        self.difficulty = difficulty
        self.targetMuscleGroups = targetMuscleGroups
        self.exercises = exercises
        self.imageURL = imageURL
        self.videoPreviewURL = videoPreviewURL
        self.isCompleted = false
        self.completedAt = nil
        self.actualDuration = nil
        self.actualCalories = nil
        self.userRating = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // MARK: - Custom Decoding for Firebase Robustness
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Ensure ID is never nil for UI stability
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id), !decodedId.isEmpty {
            self.id = decodedId
        } else {
            self.id = UUID().uuidString
            print("[WorkoutSession] ⚠️ Generated safe ID for workout: \(try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown")")
        }
        
        // Robust field decoding
        self.userId = (try? container.decode(String.self, forKey: .userId)) ?? ""
        self.workoutType = (try? container.decode(WorkoutType.self, forKey: .workoutType)) ?? .cardio
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Workout"
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        self.estimatedDuration = (try? container.decode(TimeInterval.self, forKey: .estimatedDuration)) ?? 1800 // 30 min default
        self.estimatedCalories = (try? container.decode(Int.self, forKey: .estimatedCalories)) ?? 200
        self.difficulty = (try? container.decode(DifficultyLevel.self, forKey: .difficulty)) ?? .beginner
        self.targetMuscleGroups = (try? container.decode([MuscleGroup].self, forKey: .targetMuscleGroups)) ?? []
        self.exercises = (try? container.decode([WorkoutExercise].self, forKey: .exercises)) ?? []
        self.imageURL = try? container.decodeIfPresent(String.self, forKey: .imageURL)
        self.videoPreviewURL = try? container.decodeIfPresent(String.self, forKey: .videoPreviewURL)
        self.isCompleted = (try? container.decode(Bool.self, forKey: .isCompleted)) ?? false
        self.completedAt = try? container.decodeIfPresent(Date.self, forKey: .completedAt)
        self.actualDuration = try? container.decodeIfPresent(TimeInterval.self, forKey: .actualDuration)
        self.actualCalories = try? container.decodeIfPresent(Int.self, forKey: .actualCalories)
        self.userRating = try? container.decodeIfPresent(Int.self, forKey: .userRating)
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
        
        print("[WorkoutSession] ✅ Safely decoded: \(name) with ID: \(self.id ?? "nil")")
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case workoutType
        case name
        case description
        case estimatedDuration
        case estimatedCalories
        case difficulty
        case targetMuscleGroups
        case exercises
        case imageURL
        case videoPreviewURL
        case isCompleted
        case completedAt
        case actualDuration
        case actualCalories
        case userRating
        case createdAt
        case updatedAt
    }
}

/// Workout categories with enhanced properties
enum WorkoutType: String, Codable, CaseIterable {
    case cardio = "cardio"
    case strength = "strength"
    case yoga = "yoga"
    case hiit = "hiit"
    case pilates = "pilates"
    case dance = "dance"
    case stretching = "stretching"
    case running = "running"
    
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .stretching: return "Stretching"
        case .running: return "Running"
        }
    }
    
    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .hiit: return "flame.fill"
        case .pilates: return "figure.pilates"
        case .dance: return "music.note"
        case .stretching: return "figure.flexibility"
        case .running: return "figure.run"
        }
    }
    
    var backgroundImageName: String {
        switch self {
        case .cardio: return "workout_cardio"
        case .strength: return "workout_strength"
        case .yoga: return "workout_yoga"
        case .hiit: return "workout_hiit"
        case .pilates: return "workout_pilates"
        case .dance: return "workout_dance"
        case .stretching: return "workout_stretching"
        case .running: return "workout_running"
        }
    }
    
    var primaryColor: String {
        switch self {
        case .cardio: return "#FF6B35"      // Orange
        case .strength: return "#4A90E2"   // Blue
        case .yoga: return "#9B59B6"       // Purple
        case .hiit: return "#E74C3C"       // Red
        case .pilates: return "#2ECC71"    // Green
        case .dance: return "#F39C12"      // Yellow-Orange
        case .stretching: return "#1ABC9C" // Teal
        case .running: return "#3498DB"    // Light Blue
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .cardio: return "#FF8E53"
        case .strength: return "#6AB7FF"
        case .yoga: return "#BB6BD9"
        case .hiit: return "#EC7063"
        case .pilates: return "#58D68D"
        case .dance: return "#F7DC6F"
        case .stretching: return "#48C9B0"
        case .running: return "#5DADE2"
        }
    }
}

/// Difficulty levels with proper UX copy
enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var emoji: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "💪"
        case .advanced: return "🔥"
        case .expert: return "🏆"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "#2ECC71"    // Green
        case .intermediate: return "#F39C12" // Orange
        case .advanced: return "#E74C3C"    // Red
        case .expert: return "#9B59B6"      // Purple
        }
    }
}

/// Target muscle groups for better workout planning
enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case abs = "abs"
    case legs = "legs"
    case glutes = "glutes"
    case calves = "calves"
    case fullBody = "fullBody"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .arms: return "Arms"
        case .abs: return "Abs"
        case .legs: return "Legs"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .fullBody: return "Full Body"
        case .cardio: return "Cardio"
        }
    }
    
    var icon: String {
        switch self {
        case .chest: return "lungs.fill"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.arms.open"
        case .arms: return "figure.arms.open" // Düzeltildi - mevcut iOS icon
        case .abs: return "figure.core.training"
        case .legs: return "figure.walk"
        case .glutes: return "figure.squat"
        case .calves: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "heart.fill"
        }
    }
}

/// Individual exercise within a workout
struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String?
    let exerciseType: ExerciseType 
    let targetMuscleGroups: [MuscleGroup]
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
    let exerciseIcon: String  
    
    // Computed properties for UI
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return seconds > 0 ? "\(minutes):\(String(format: "%02d", seconds))" : "\(minutes) min"
    }
    
    var exerciseTypeDescription: String {
        if let sets = sets, let reps = reps {
            return "\(sets) sets × \(reps) reps"
        } else if let duration = formattedDuration {
            return duration
        } else if let distance = distance {
            return "\(Int(distance))m"
        } else {
            return "Complete exercise"
        }
    }
    
    /// Determines if exercise is time-based (e.g. plank, cardio) vs rep-based (e.g. pushups)
    var isTimeBasedExercise: Bool {
        // If duration is set and no reps/sets, it's time-based
        return duration != nil && (reps == nil || sets == nil)
    }
    
    /// Default initializer with exerciseType
    init(
        name: String,
        description: String? = nil,
        exerciseType: ExerciseType,
        targetMuscleGroups: [MuscleGroup],
        sets: Int? = nil,
        reps: Int? = nil,
        duration: TimeInterval? = nil,
        restTime: TimeInterval? = nil,
        weight: Double? = nil,
        distance: Double? = nil,
        instructions: [String] = [],
        imageURL: String? = nil,
        videoURL: String? = nil,
        caloriesPerMinute: Double? = nil,
        exerciseIcon: String? = nil
    ) {
        self.name = name
        self.description = description
        self.exerciseType = exerciseType
        self.targetMuscleGroups = targetMuscleGroups
        self.sets = sets
        self.reps = reps
        self.duration = duration
        self.restTime = restTime
        self.weight = weight
        self.distance = distance
        self.instructions = instructions
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.caloriesPerMinute = caloriesPerMinute
        self.exerciseIcon = exerciseIcon ?? exerciseType.defaultIcon
    }
}

// MARK: - Exercise Type Enum
enum ExerciseType: String, Codable, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case flexibility = "flexibility"
    case balance = "balance"
    case plyometric = "plyometric"
    case endurance = "endurance"
    case warmup = "warmup"
    case cooldown = "cooldown"
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .flexibility: return "Flexibility"
        case .balance: return "Balance"
        case .plyometric: return "Plyometric"
        case .endurance: return "Endurance"
        case .warmup: return "Warm Up"
        case .cooldown: return "Cool Down"
        }
    }
    
    var defaultIcon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .flexibility: return "figure.flexibility"
        case .balance: return "figure.yoga"
        case .plyometric: return "flame.fill"
        case .endurance: return "figure.run"
        case .warmup: return "thermometer.sun.fill"
        case .cooldown: return "snowflake"
        }
    }
    
    var primaryColor: String {
        switch self {
        case .strength: return "#4A90E2"     // Blue
        case .cardio: return "#E74C3C"       // Red
        case .flexibility: return "#9B59B6"  // Purple
        case .balance: return "#1ABC9C"      // Teal
        case .plyometric: return "#F39C12"   // Orange
        case .endurance: return "#2ECC71"    // Green
        case .warmup: return "#FF6B35"       // Orange-Red
        case .cooldown: return "#3498DB"     // Light Blue
        }
    }
    
    var secondaryColor: String {
        switch self {
        case .strength: return "#6AB7FF"
        case .cardio: return "#EC7063"
        case .flexibility: return "#BB6BD9"
        case .balance: return "#48C9B0"
        case .plyometric: return "#F7DC6F"
        case .endurance: return "#58D68D"
        case .warmup: return "#FF8E53"
        case .cooldown: return "#5DADE2"
        }
    }
}

/// User's workout statistics and progress
struct WorkoutStats: Codable {
    let userId: String
    let totalWorkouts: Int
    let totalDuration: TimeInterval // in seconds
    let totalCaloriesBurned: Int
    let currentStreak: Int
    let longestStreak: Int
    let favoriteWorkoutType: WorkoutType?
    let weeklyGoal: Int // workouts per week
    let weeklyProgress: Int // current week workouts completed
    let monthlyCalorieGoal: Int
    let monthlyCalorieProgress: Int
    let personalRecords: [PersonalRecord]
    let lastWorkoutDate: Date?
    let updatedAt: Date
    
    // Computed properties
    var averageWorkoutDuration: TimeInterval {
        guard totalWorkouts > 0 else { return 0 }
        return totalDuration / Double(totalWorkouts)
    }
    
    var averageCaloriesPerWorkout: Double {
        guard totalWorkouts > 0 else { return 0 }
        return Double(totalCaloriesBurned) / Double(totalWorkouts)
    }
    
    var weeklyProgressPercentage: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(weeklyProgress) / Double(weeklyGoal) * 100, 100)
    }
    
    var monthlyCaloriePercentage: Double {
        guard monthlyCalorieGoal > 0 else { return 0 }
        return min(Double(monthlyCalorieProgress) / Double(monthlyCalorieGoal) * 100, 100)
    }
}

/// Personal records for motivation
struct PersonalRecord: Identifiable, Codable {
    let id = UUID()
    let type: RecordType
    let value: Double
    let unit: String
    let workoutType: WorkoutType
    let achievedAt: Date
    let exerciseName: String?
    
    enum RecordType: String, Codable {
        case longestWorkout = "longest_workout"
        case mostCalories = "most_calories"
        case heaviestWeight = "heaviest_weight"
        case longestDistance = "longest_distance"
        case fastestTime = "fastest_time"
        case longestStreak = "longest_streak"
    }
    
    var displayText: String {
        switch type {
        case .longestWorkout:
            let hours = Int(value / 3600)
            let minutes = Int((value.truncatingRemainder(dividingBy: 3600)) / 60)
            return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes) min"
        case .mostCalories:
            return "\(Int(value)) kcal"
        case .heaviestWeight:
            return "\(Int(value)) \(unit)"
        case .longestDistance:
            return "\(value) \(unit)"
        case .fastestTime:
            let minutes = Int(value / 60)
            let seconds = Int(value.truncatingRemainder(dividingBy: 60))
            return "\(minutes):\(String(format: "%02d", seconds))"
        case .longestStreak:
            return "\(Int(value)) days"
        }
    }
}

/// Daily workout recommendations
struct WorkoutRecommendation: Identifiable, Codable {
    let id = UUID()
    let workoutSession: WorkoutSession
    let reason: RecommendationReason
    let priority: Int // 1-10, higher = more important
    let validUntil: Date
    
    enum RecommendationReason: String, Codable {
        case dailyGoal = "daily_goal"
        case restDay = "rest_day"
        case muscleGroupRotation = "muscle_rotation"
        case personalPreference = "preference"
        case streakMaintenance = "streak"
        case newWorkout = "new_workout"
        case completePreviousSession = "incomplete"
        
        var displayText: String {
            switch self {
            case .dailyGoal: return "Daily Goal"
            case .restDay: return "Rest Day Recovery"
            case .muscleGroupRotation: return "Muscle Group Focus"
            case .personalPreference: return "Your Favorite"
            case .streakMaintenance: return "Keep Your Streak"
            case .newWorkout: return "Try Something New"
            case .completePreviousSession: return "Complete Previous"
            }
        }
        
        var icon: String {
            switch self {
            case .dailyGoal: return "target"
            case .restDay: return "leaf.fill"
            case .muscleGroupRotation: return "arrow.triangle.2.circlepath"
            case .personalPreference: return "heart.fill"
            case .streakMaintenance: return "flame.fill"
            case .newWorkout: return "sparkles"
            case .completePreviousSession: return "clock.fill"
            }
        }
    }
}

// MARK: - Mock Data for Previews and Testing

extension WorkoutSession {
    static let mockData: [WorkoutSession] = [
        WorkoutSession(
            userId: "mock-user",
            workoutType: .hiit,
            name: "Morning HIIT Blast",
            description: "High-intensity interval training to kickstart your day",
            estimatedDuration: 1200, // 20 minutes
            estimatedCalories: 280,
            difficulty: .intermediate,
            targetMuscleGroups: [.fullBody, .cardio],
            exercises: [
                WorkoutExercise(
                    name: "Jumping Jacks",
                    description: "Full-body cardio exercise",
                    exerciseType: .cardio,
                    targetMuscleGroups: [.fullBody, .cardio],
                    duration: 30,
                    instructions: ["Stand with feet together", "Jump while spreading legs and raising arms", "Return to starting position"],
                    exerciseIcon: "figure.jumper"
                ),
                WorkoutExercise(
                    name: "Push-ups",
                    description: "Upper body strength exercise",
                    exerciseType: .strength,
                    targetMuscleGroups: [.chest, .arms],
                    sets: 3,
                    reps: 10,
                    instructions: ["Start in plank position", "Lower chest to ground", "Push back up"],
                    exerciseIcon: "figure.strengthtraining.traditional"
                ),
                WorkoutExercise(
                    name: "Mountain Climbers",
                    description: "Core and cardio exercise",
                    exerciseType: .cardio,
                    targetMuscleGroups: [.abs, .cardio],
                    duration: 45,
                    instructions: 
                        ["Start in plank position", "Bring one knee up towards chest", "Quickly switch legs"]
                ),
            ],
            imageURL: nil,
            videoPreviewURL: nil
        ),
    ]
}