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
    case boxing = "boxing"
    case running = "running"
    case cycling = "cycling"
    
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .stretching: return "Stretching"
        case .boxing: return "Boxing"
        case .running: return "Running"
        case .cycling: return "Cycling"
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
        case .boxing: return "boxing.gloves"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
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
        case .boxing: return "#34495E"     // Dark Gray
        case .running: return "#3498DB"    // Light Blue
        case .cycling: return "#27AE60"    // Forest Green
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
        case .boxing: return "#5D6D7E"
        case .running: return "#5DADE2"
        case .cycling: return "#52C882"
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
        case .arms: return "arm"
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