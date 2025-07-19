import Foundation

/// Production-quality mock data for development and testing
struct MockWorkoutData {
    
    static let allWorkouts: [WorkoutSession] = [
        // CARDIO WORKOUTS
        createWorkout(
            type: .cardio,
            name: "HIIT Cardio Blast",
            description: "High-intensity interval training to maximize calorie burn and improve cardiovascular health",
            duration: 20 * 60, // 20 minutes
            calories: 300,
            difficulty: .intermediate,
            muscles: [.fullBody, .cardio],
            exercises: cardioBlastExercises,
            imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400"
        ),
        
        createWorkout(
            type: .running,
            name: "Morning Energy Run",
            description: "Start your day with an energizing outdoor run designed to boost your mood and metabolism",
            duration: 30 * 60,
            calories: 400,
            difficulty: .beginner,
            muscles: [.legs, .cardio, .calves],
            exercises: morningRunExercises,
            imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400"
        ),
        
        // STRENGTH WORKOUTS
        createWorkout(
            type: .strength,
            name: "Full Body Strength",
            description: "Complete strength training session targeting all major muscle groups for balanced development",
            duration: 45 * 60,
            calories: 350,
            difficulty: .intermediate,
            muscles: [.fullBody, .chest, .back, .arms, .legs],
            exercises: fullBodyStrengthExercises,
            imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400"
        ),
        
        createWorkout(
            type: .strength,
            name: "Upper Body Power",
            description: "Focus on building upper body strength with compound movements and targeted exercises",
            duration: 35 * 60,
            calories: 280,
            difficulty: .advanced,
            muscles: [.chest, .back, .shoulders, .arms],
            exercises: upperBodyExercises,
            imageURL: "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400"
        ),
        
        // YOGA WORKOUTS
        createWorkout(
            type: .yoga,
            name: "Morning Flow",
            description: "Gentle yoga sequence to awaken your body and mind for the day ahead",
            duration: 25 * 60,
            calories: 150,
            difficulty: .beginner,
            muscles: [.fullBody],
            exercises: morningYogaExercises,
            imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400"
        ),
        
        createWorkout(
            type: .yoga,
            name: "Power Yoga Flow",
            description: "Dynamic yoga sequence combining strength, flexibility, and mindfulness",
            duration: 40 * 60,
            calories: 250,
            difficulty: .intermediate,
            muscles: [.fullBody, .abs],
            exercises: powerYogaExercises,
            imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400"
        ),
        
        // STRETCHING & RECOVERY
        createWorkout(
            type: .stretching,
            name: "Deep Stretch & Recovery",
            description: "Comprehensive stretching routine for muscle recovery and flexibility improvement",
            duration: 15 * 60,
            calories: 80,
            difficulty: .beginner,
            muscles: [.fullBody],
            exercises: stretchingExercises,
            imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400"
        ),
        
        // HIIT WORKOUTS
        createWorkout(
            type: .hiit,
            name: "Tabata Burn",
            description: "4-minute Tabata protocol for maximum fat burning in minimal time",
            duration: 16 * 60, // 16 minutes total with warm-up and cool-down
            calories: 320,
            difficulty: .advanced,
            muscles: [.fullBody],
            exercises: tabataExercises,
            imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400"
        ),
        
        // PILATES WORKOUTS
        createWorkout(
            type: .pilates,
            name: "Core Pilates",
            description: "Targeted Pilates routine focusing on core strength and stability",
            duration: 30 * 60,
            calories: 200,
            difficulty: .intermediate,
            muscles: [.abs, .back],
            exercises: pilatesExercises,
            imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400"
        ),
        
        // DANCE WORKOUTS
        createWorkout(
            type: .dance,
            name: "Cardio Dance Party",
            description: "Fun, high-energy dance workout that doesn't feel like exercise",
            duration: 25 * 60,
            calories: 280,
            difficulty: .beginner,
            muscles: [.fullBody, .cardio],
            exercises: danceExercises,
            imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400"
        )
    ]
    
    // MARK: - Exercise Collections
    
    private static let cardioBlastExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Jumping Jacks",
            description: "Classic full-body cardio exercise",
            targetMuscleGroups: [.fullBody, .cardio],
            sets: nil,
            reps: nil,
            duration: 45,
            restTime: 15,
            weight: nil,
            distance: nil,
            instructions: [
                "Stand with feet together, arms at sides",
                "Jump feet apart while raising arms overhead",
                "Jump back to starting position",
                "Maintain steady rhythm"
            ],
            imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200",
            videoURL: nil,
            caloriesPerMinute: 12.0
        ),
        
        WorkoutExercise(
            name: "High Knees",
            description: "Running in place with high knee raises",
            targetMuscleGroups: [.legs, .cardio],
            sets: nil,
            reps: nil,
            duration: 30,
            restTime: 15,
            weight: nil,
            distance: nil,
            instructions: [
                "Stand in place",
                "Run in place lifting knees to hip level",
                "Pump arms as if running",
                "Maintain quick pace"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 15.0
        ),
        
        WorkoutExercise(
            name: "Burpees",
            description: "Full-body exercise combining squat, plank, and jump",
            targetMuscleGroups: [.fullBody],
            sets: nil,
            reps: 10,
            duration: nil,
            restTime: 30,
            weight: nil,
            distance: nil,
            instructions: [
                "Start in standing position",
                "Drop to squat position, hands on ground",
                "Jump back to plank position",
                "Do a push-up",
                "Jump feet back to squat",
                "Jump up with arms overhead"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 18.0
        )
    ]
    
    private static let morningRunExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Warm-up Walk",
            description: "Gentle walking to prepare for running",
            targetMuscleGroups: [.legs, .cardio],
            sets: nil,
            reps: nil,
            duration: 300, // 5 minutes
            restTime: nil,
            weight: nil,
            distance: nil,
            instructions: [
                "Start with slow, comfortable walking pace",
                "Focus on proper posture",
                "Gradually increase pace",
                "Prepare body for running"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 5.0
        ),
        
        WorkoutExercise(
            name: "Easy Jog",
            description: "Comfortable jogging pace",
            targetMuscleGroups: [.legs, .cardio, .calves],
            sets: nil,
            reps: nil,
            duration: 1200, // 20 minutes
            restTime: nil,
            weight: nil,
            distance: 3000, // 3km
            instructions: [
                "Maintain conversational pace",
                "Focus on rhythmic breathing",
                "Land midfoot, not heel",
                "Keep posture upright"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 12.0
        ),
        
        WorkoutExercise(
            name: "Cool-down Walk",
            description: "Gradual cooldown to prevent injury",
            targetMuscleGroups: [.legs],
            sets: nil,
            reps: nil,
            duration: 300, // 5 minutes
            restTime: nil,
            weight: nil,
            distance: nil,
            instructions: [
                "Gradually slow down from jogging",
                "Return to comfortable walking pace",
                "Focus on deep breathing",
                "Allow heart rate to lower"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 4.0
        )
    ]
    
    private static let fullBodyStrengthExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Push-ups",
            description: "Classic upper body strength exercise",
            targetMuscleGroups: [.chest, .shoulders, .arms],
            sets: 3,
            reps: 12,
            duration: nil,
            restTime: 60,
            weight: nil,
            distance: nil,
            instructions: [
                "Start in plank position",
                "Lower chest to ground",
                "Push back to starting position",
                "Keep body straight"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 8.0
        ),
        
        WorkoutExercise(
            name: "Squats",
            description: "Fundamental lower body exercise",
            targetMuscleGroups: [.legs, .glutes],
            sets: 3,
            reps: 15,
            duration: nil,
            restTime: 60,
            weight: nil,
            distance: nil,
            instructions: [
                "Stand with feet shoulder-width apart",
                "Lower by sitting back and down",
                "Keep chest up, knees behind toes",
                "Return to standing position"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 6.0
        ),
        
        WorkoutExercise(
            name: "Plank",
            description: "Core stability exercise",
            targetMuscleGroups: [.abs, .back],
            sets: 3,
            reps: nil,
            duration: 45,
            restTime: 45,
            weight: nil,
            distance: nil,
            instructions: [
                "Start in push-up position",
                "Hold body straight",
                "Engage core muscles",
                "Breathe normally"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 5.0
        )
    ]
    
    private static let upperBodyExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Pike Push-ups",
            description: "Shoulder-focused push-up variation",
            targetMuscleGroups: [.shoulders, .arms],
            sets: 3,
            reps: 10,
            duration: nil,
            restTime: 75,
            weight: nil,
            distance: nil,
            instructions: [
                "Start in downward dog position",
                "Lower head toward ground",
                "Push back to starting position",
                "Keep hips high throughout"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 9.0
        )
    ]
    
    private static let morningYogaExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Sun Salutation A",
            description: "Classic yoga sequence to energize the body",
            targetMuscleGroups: [.fullBody],
            sets: 3,
            reps: nil,
            duration: 60,
            restTime: 30,
            weight: nil,
            distance: nil,
            instructions: [
                "Start in mountain pose",
                "Flow through upward salute",
                "Forward fold to standing forward bend",
                "Flow through chaturanga to upward facing dog",
                "Return to downward facing dog",
                "Step forward to standing"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 6.0
        )
    ]
    
    private static let powerYogaExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Warrior Sequence",
            description: "Dynamic warrior pose flow",
            targetMuscleGroups: [.legs, .abs],
            sets: 2,
            reps: nil,
            duration: 120,
            restTime: 60,
            weight: nil,
            distance: nil,
            instructions: [
                "Flow between warrior I, II, and III",
                "Hold each pose for 30 seconds",
                "Focus on proper alignment",
                "Breathe deeply throughout"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 7.0
        )
    ]
    
    private static let stretchingExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Forward Fold",
            description: "Hamstring and back stretch",
            targetMuscleGroups: [.back, .legs],
            sets: 1,
            reps: nil,
            duration: 45,
            restTime: 15,
            weight: nil,
            distance: nil,
            instructions: [
                "Stand with feet hip-width apart",
                "Slowly fold forward from hips",
                "Let arms hang naturally",
                "Breathe deeply and relax"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 2.0
        )
    ]
    
    private static let tabataExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Tabata Rounds",
            description: "20 seconds work, 10 seconds rest",
            targetMuscleGroups: [.fullBody],
            sets: 8,
            reps: nil,
            duration: 20,
            restTime: 10,
            weight: nil,
            distance: nil,
            instructions: [
                "20 seconds maximum effort",
                "10 seconds complete rest",
                "Repeat for 8 rounds (4 minutes)",
                "Give everything you have"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 20.0
        )
    ]
    
    private static let pilatesExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "The Hundred",
            description: "Classic Pilates core exercise",
            targetMuscleGroups: [.abs],
            sets: 1,
            reps: 100,
            duration: nil,
            restTime: 60,
            weight: nil,
            distance: nil,
            instructions: [
                "Lie on back, knees to chest",
                "Extend legs to 45 degrees",
                "Pump arms up and down",
                "Breathe in for 5, out for 5"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 7.0
        )
    ]
    
    private static let danceExercises: [WorkoutExercise] = [
        WorkoutExercise(
            name: "Dance Cardio",
            description: "High-energy dance moves",
            targetMuscleGroups: [.fullBody, .cardio],
            sets: nil,
            reps: nil,
            duration: 1500, // 25 minutes
            restTime: nil,
            weight: nil,
            distance: nil,
            instructions: [
                "Follow the beat",
                "Move your whole body",
                "Have fun with it",
                "Don't worry about perfection"
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 11.0
        )
    ]
    
    // MARK: - Helper Methods
    
    private static func createWorkout(
        type: WorkoutType,
        name: String,
        description: String,
        duration: TimeInterval,
        calories: Int,
        difficulty: DifficultyLevel,
        muscles: [MuscleGroup],
        exercises: [WorkoutExercise],
        imageURL: String? = nil
    ) -> WorkoutSession {
        return WorkoutSession(
            userId: "mock_user",
            workoutType: type,
            name: name,
            description: description,
            estimatedDuration: duration,
            estimatedCalories: calories,
            difficulty: difficulty,
            targetMuscleGroups: muscles,
            exercises: exercises,
            imageURL: imageURL
        )
    }
}