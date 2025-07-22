import Foundation
import FirebaseFirestore

// MARK: - Enhanced Workout Models for Production

/// Workout template for creating standardized workouts
struct WorkoutTemplate: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let workoutType: WorkoutType
    let difficulty: DifficultyLevel
    let estimatedDuration: TimeInterval
    let estimatedCalories: Int
    let targetMuscleGroups: [MuscleGroup]
    let exercises: [WorkoutExercise]
    let imageURL: String?
    let videoPreviewURL: String?
    let isActive: Bool
    let priority: Int // For ordering in lists
    let tags: [String]
    let searchKeywords: [String]
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties for UI
    var safeId: String {
        return id ?? UUID().uuidString
    }
    
    var formattedDuration: String {
        let hours = Int(estimatedDuration / 3600)
        let minutes = Int((estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
    
    var exerciseCount: String {
        let count = exercises.count
        return "\(count) exercise\(count == 1 ? "" : "s")"
    }
    
    init(
        name: String,
        description: String? = nil,
        workoutType: WorkoutType,
        difficulty: DifficultyLevel,
        estimatedDuration: TimeInterval,
        estimatedCalories: Int,
        targetMuscleGroups: [MuscleGroup],
        exercises: [WorkoutExercise],
        imageURL: String? = nil,
        videoPreviewURL: String? = nil,
        isActive: Bool = true,
        priority: Int = 0,
        tags: [String] = [],
        searchKeywords: [String] = []
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.workoutType = workoutType
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.estimatedCalories = estimatedCalories
        self.targetMuscleGroups = targetMuscleGroups
        self.exercises = exercises
        self.imageURL = imageURL
        self.videoPreviewURL = videoPreviewURL
        self.isActive = isActive
        self.priority = priority
        self.tags = tags
        self.searchKeywords = searchKeywords
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Custom decoding for Firebase robustness
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id), !decodedId.isEmpty {
            self.id = decodedId
        } else {
            self.id = UUID().uuidString
        }
        
        self.name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Workout"
        self.description = try? container.decodeIfPresent(String.self, forKey: .description)
        self.workoutType = (try? container.decode(WorkoutType.self, forKey: .workoutType)) ?? .cardio
        self.difficulty = (try? container.decode(DifficultyLevel.self, forKey: .difficulty)) ?? .beginner
        self.estimatedDuration = (try? container.decode(TimeInterval.self, forKey: .estimatedDuration)) ?? 1800
        self.estimatedCalories = (try? container.decode(Int.self, forKey: .estimatedCalories)) ?? 200
        self.targetMuscleGroups = (try? container.decode([MuscleGroup].self, forKey: .targetMuscleGroups)) ?? []
        self.exercises = (try? container.decode([WorkoutExercise].self, forKey: .exercises)) ?? []
        self.imageURL = try? container.decodeIfPresent(String.self, forKey: .imageURL)
        self.videoPreviewURL = try? container.decodeIfPresent(String.self, forKey: .videoPreviewURL)
        self.isActive = (try? container.decode(Bool.self, forKey: .isActive)) ?? true
        self.priority = (try? container.decode(Int.self, forKey: .priority)) ?? 0
        self.tags = (try? container.decode([String].self, forKey: .tags)) ?? []
        self.searchKeywords = (try? container.decode([String].self, forKey: .searchKeywords)) ?? []
        self.createdAt = (try? container.decode(Date.self, forKey: .createdAt)) ?? Date()
        self.updatedAt = (try? container.decode(Date.self, forKey: .updatedAt)) ?? Date()
    }
    
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
        case videoPreviewURL
        case isActive
        case priority
        case tags
        case searchKeywords
        case createdAt
        case updatedAt
    }
}

/// Workout completion data for tracking user's workout progress
struct WorkoutCompletionData: Codable {
    var workoutId: String?
    var userId: String?
    var workoutName: String = ""
    var workoutType: WorkoutType = .cardio
    var startTime: Date = Date()
    var endTime: Date?
    var totalDuration: TimeInterval = 0
    var completedExercises: [CompletedExercise] = []
    var totalCaloriesBurned: Int = 0
    var isFullyCompleted: Bool = false
    var userRating: Int?
    var actualDuration: TimeInterval = 0
    var actualCalories: Int = 0
    var completedAt: Date?
    
    var completionPercentage: Double {
        return isFullyCompleted ? 1.0 : 0.5
    }
    
    // Default initializer
    init() {}
    
    // Custom initializers for different use cases
    init(
        workoutId: String?,
        workoutName: String,
        workoutType: WorkoutType,
        startTime: Date,
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
        self.actualDuration = totalDuration
        self.actualCalories = totalCaloriesBurned
        self.completedAt = endTime
    }
    
    // Initializer for offline completion
    init(
        workoutId: String?,
        userId: String,
        actualDuration: TimeInterval,
        actualCalories: Int,
        rating: Int?,
        completedAt: Date
    ) {
        self.workoutId = workoutId
        self.userId = userId
        self.actualDuration = actualDuration
        self.totalDuration = actualDuration
        self.actualCalories = actualCalories
        self.totalCaloriesBurned = actualCalories
        self.userRating = rating
        self.completedAt = completedAt
        self.endTime = completedAt
        self.isFullyCompleted = true
    }
    
    // Manual Codable implementation to handle UUID field properly
    enum CodingKeys: String, CodingKey {
        case workoutId
        case userId
        case workoutName
        case workoutType
        case startTime
        case endTime
        case totalDuration
        case completedExercises
        case totalCaloriesBurned
        case isFullyCompleted
        case userRating
        case actualDuration
        case actualCalories
        case completedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        workoutId = try? container.decodeIfPresent(String.self, forKey: .workoutId)
        userId = try? container.decodeIfPresent(String.self, forKey: .userId)
        workoutName = (try? container.decode(String.self, forKey: .workoutName)) ?? ""
        workoutType = (try? container.decode(WorkoutType.self, forKey: .workoutType)) ?? .cardio
        startTime = (try? container.decode(Date.self, forKey: .startTime)) ?? Date()
        endTime = try? container.decodeIfPresent(Date.self, forKey: .endTime)
        totalDuration = (try? container.decode(TimeInterval.self, forKey: .totalDuration)) ?? 0
        completedExercises = (try? container.decode([CompletedExercise].self, forKey: .completedExercises)) ?? []
        totalCaloriesBurned = (try? container.decode(Int.self, forKey: .totalCaloriesBurned)) ?? 0
        isFullyCompleted = (try? container.decode(Bool.self, forKey: .isFullyCompleted)) ?? false
        userRating = try? container.decodeIfPresent(Int.self, forKey: .userRating)
        actualDuration = (try? container.decode(TimeInterval.self, forKey: .actualDuration)) ?? 0
        actualCalories = (try? container.decode(Int.self, forKey: .actualCalories)) ?? 0
        completedAt = try? container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(workoutId, forKey: .workoutId)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(workoutName, forKey: .workoutName)
        try container.encode(workoutType, forKey: .workoutType)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(totalDuration, forKey: .totalDuration)
        try container.encode(completedExercises, forKey: .completedExercises)
        try container.encode(totalCaloriesBurned, forKey: .totalCaloriesBurned)
        try container.encode(isFullyCompleted, forKey: .isFullyCompleted)
        try container.encodeIfPresent(userRating, forKey: .userRating)
        try container.encode(actualDuration, forKey: .actualDuration)
        try container.encode(actualCalories, forKey: .actualCalories)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
    }
}

/// Completed exercise data for workout completion tracking
struct CompletedExercise: Codable, Identifiable {
    let id: String // Use String instead of UUID for Codable compatibility
    let exercise: WorkoutExercise
    let setsCompleted: Int
    let repsPerSet: [Int]
    let duration: TimeInterval
    let caloriesBurned: Int
    let completedAt: Date
    
    init(
        exercise: WorkoutExercise,
        setsCompleted: Int,
        repsPerSet: [Int],
        duration: TimeInterval,
        caloriesBurned: Int
    ) {
        self.id = UUID().uuidString // Generate string ID
        self.exercise = exercise
        self.setsCompleted = setsCompleted
        self.repsPerSet = repsPerSet
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.completedAt = Date()
    }
    
    // Manual Codable implementation for UUID compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case exercise
        case setsCompleted
        case repsPerSet
        case duration
        case caloriesBurned
        case completedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        exercise = try container.decode(WorkoutExercise.self, forKey: .exercise)
        setsCompleted = (try? container.decode(Int.self, forKey: .setsCompleted)) ?? 0
        repsPerSet = (try? container.decode([Int].self, forKey: .repsPerSet)) ?? []
        duration = (try? container.decode(TimeInterval.self, forKey: .duration)) ?? 0
        caloriesBurned = (try? container.decode(Int.self, forKey: .caloriesBurned)) ?? 0
        completedAt = (try? container.decode(Date.self, forKey: .completedAt)) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(exercise, forKey: .exercise)
        try container.encode(setsCompleted, forKey: .setsCompleted)
        try container.encode(repsPerSet, forKey: .repsPerSet)
        try container.encode(duration, forKey: .duration)
        try container.encode(caloriesBurned, forKey: .caloriesBurned)
        try container.encode(completedAt, forKey: .completedAt)
    }
}

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
struct WorkoutExercise: Identifiable, Codable, Hashable {
    let id: String // Use String instead of UUID for Codable compatibility
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
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(exerciseType)
        hasher.combine(sets)
        hasher.combine(reps)
        hasher.combine(duration)
    }
    
    static func == (lhs: WorkoutExercise, rhs: WorkoutExercise) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.exerciseType == rhs.exerciseType &&
               lhs.sets == rhs.sets &&
               lhs.reps == rhs.reps &&
               lhs.duration == rhs.duration
    }
    
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
        self.id = UUID().uuidString // Generate string ID
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
    
    // Manual Codable implementation for UUID compatibility
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case exerciseType
        case targetMuscleGroups
        case sets
        case reps
        case duration
        case restTime
        case weight
        case distance
        case instructions
        case imageURL
        case videoURL
        case caloriesPerMinute
        case exerciseIcon
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown Exercise"
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        exerciseType = (try? container.decode(ExerciseType.self, forKey: .exerciseType)) ?? .cardio
        targetMuscleGroups = (try? container.decode([MuscleGroup].self, forKey: .targetMuscleGroups)) ?? []
        sets = try? container.decodeIfPresent(Int.self, forKey: .sets)
        reps = try? container.decodeIfPresent(Int.self, forKey: .reps)
        duration = try? container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        restTime = try? container.decodeIfPresent(TimeInterval.self, forKey: .restTime)
        weight = try? container.decodeIfPresent(Double.self, forKey: .weight)
        distance = try? container.decodeIfPresent(Double.self, forKey: .distance)
        instructions = (try? container.decode([String].self, forKey: .instructions)) ?? []
        imageURL = try? container.decodeIfPresent(String.self, forKey: .imageURL)
        videoURL = try? container.decodeIfPresent(String.self, forKey: .videoURL)
        caloriesPerMinute = try? container.decodeIfPresent(Double.self, forKey: .caloriesPerMinute)
        exerciseIcon = (try? container.decode(String.self, forKey: .exerciseIcon)) ?? exerciseType.defaultIcon
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(exerciseType, forKey: .exerciseType)
        try container.encode(targetMuscleGroups, forKey: .targetMuscleGroups)
        try container.encodeIfPresent(sets, forKey: .sets)
        try container.encodeIfPresent(reps, forKey: .reps)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(restTime, forKey: .restTime)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encode(instructions, forKey: .instructions)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(videoURL, forKey: .videoURL)
        try container.encodeIfPresent(caloriesPerMinute, forKey: .caloriesPerMinute)
        try container.encode(exerciseIcon, forKey: .exerciseIcon)
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
    let id: String // Use String instead of UUID for Codable compatibility
    let type: RecordType
    let value: Double
    let unit: String
    let workoutType: WorkoutType
    let achievedAt: Date
    let exerciseName: String?
    
    init(
        type: RecordType,
        value: Double,
        unit: String,
        workoutType: WorkoutType,
        achievedAt: Date,
        exerciseName: String? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.value = value
        self.unit = unit
        self.workoutType = workoutType
        self.achievedAt = achievedAt
        self.exerciseName = exerciseName
    }
    
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
    
    // Manual Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case type
        case value
        case unit
        case workoutType
        case achievedAt
        case exerciseName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        type = (try? container.decode(RecordType.self, forKey: .type)) ?? .longestWorkout
        value = (try? container.decode(Double.self, forKey: .value)) ?? 0
        unit = (try? container.decode(String.self, forKey: .unit)) ?? ""
        workoutType = (try? container.decode(WorkoutType.self, forKey: .workoutType)) ?? .cardio
        achievedAt = (try? container.decode(Date.self, forKey: .achievedAt)) ?? Date()
        exerciseName = try? container.decodeIfPresent(String.self, forKey: .exerciseName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
        try container.encode(unit, forKey: .unit)
        try container.encode(workoutType, forKey: .workoutType)
        try container.encode(achievedAt, forKey: .achievedAt)
        try container.encodeIfPresent(exerciseName, forKey: .exerciseName)
    }
}

/// Daily workout recommendations
struct WorkoutRecommendation: Identifiable, Codable {
    let id: String // Use String instead of UUID for Codable compatibility
    let workoutSession: WorkoutSession
    let reason: RecommendationReason
    let priority: Int // 1-10, higher = more important
    let validUntil: Date
    
    init(
        workoutSession: WorkoutSession,
        reason: RecommendationReason,
        priority: Int,
        validUntil: Date
    ) {
        self.id = UUID().uuidString
        self.workoutSession = workoutSession
        self.reason = reason
        self.priority = priority
        self.validUntil = validUntil
    }
    
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
    
    // Manual Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSession
        case reason
        case priority
        case validUntil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        workoutSession = try container.decode(WorkoutSession.self, forKey: .workoutSession)
        reason = (try? container.decode(RecommendationReason.self, forKey: .reason)) ?? .dailyGoal
        priority = (try? container.decode(Int.self, forKey: .priority)) ?? 5
        validUntil = (try? container.decode(Date.self, forKey: .validUntil)) ?? Date()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(workoutSession, forKey: .workoutSession)
        try container.encode(reason, forKey: .reason)
        try container.encode(priority, forKey: .priority)
        try container.encode(validUntil, forKey: .validUntil)
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

extension WorkoutTemplate {
    static let mockData: [WorkoutTemplate] = [
        WorkoutTemplate(
            name: "Quick Morning Yoga",
            description: "Start your day with gentle movements and mindfulness",
            workoutType: .yoga,
            difficulty: .beginner,
            estimatedDuration: 900, // 15 minutes
            estimatedCalories: 80,
            targetMuscleGroups: [.fullBody],
            exercises: [
                WorkoutExercise(
                    name: "Sun Salutation",
                    description: "Classic yoga sequence",
                    exerciseType: .flexibility,
                    targetMuscleGroups: [.fullBody],
                    sets: 3,
                    instructions: ["Flow through the sequence", "Focus on breath", "Move slowly and mindfully"]
                )
            ],
            tags: ["morning", "yoga", "beginner", "flexibility"],
            searchKeywords: ["yoga", "morning", "stretch", "flexibility", "mindfulness"]
        )
    ]
}