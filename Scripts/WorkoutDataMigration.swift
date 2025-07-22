import Foundation
import FirebaseFirestore
import FirebaseCore

/// Migration script to populate Firebase with workout templates
/// Run this once to setup initial workout data in Firestore
class WorkoutDataMigration {
    
    private let db = Firestore.firestore()
    
    /// Run the migration to populate workout templates
    func runMigration() async {
        print("[Migration] Starting workout templates migration...")
        
        do {
            // Check if templates already exist
            let existingTemplates = try await db.collection("workoutTemplates").getDocuments()
            
            if existingTemplates.documents.count > 0 {
                print("[Migration] Templates already exist (\(existingTemplates.documents.count)), skipping migration")
                return
            }
            
            // Create workout templates
            let templates = createWorkoutTemplates()
            
            // Upload to Firebase
            for (index, template) in templates.enumerated() {
                let docRef = db.collection("workoutTemplates").document()
                
                var templateData = try Firestore.Encoder().encode(template)
                templateData["id"] = docRef.documentID
                
                try await docRef.setData(templateData)
                print("[Migration] Uploaded template \(index + 1)/\(templates.count): \(template.name)")
            }
            
            print("[Migration] Successfully migrated \(templates.count) workout templates")
            
        } catch {
            print("[Migration] Migration failed: \(error}")
        }
    }
    
    private func createWorkoutTemplates() -> [WorkoutTemplate] {
        return [
            // CARDIO WORKOUTS
            WorkoutTemplate(
                name: "HIIT Cardio Blast",
                description: "High-intensity interval training to maximize calorie burn and improve cardiovascular health",
                workoutType: .cardio,
                difficulty: .intermediate,
                estimatedDuration: 20 * 60,
                estimatedCalories: 300,
                targetMuscleGroups: [.fullBody, .cardio],
                exercises: hiitCardioExercises(),
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400",
                priority: 1
            ),
            
            WorkoutTemplate(
                name: "Morning Energy Run",
                description: "Start your day with an energizing outdoor run designed to boost your mood and metabolism",
                workoutType: .running,
                difficulty: .beginner,
                estimatedDuration: 30 * 60,
                estimatedCalories: 400,
                targetMuscleGroups: [.legs, .cardio, .calves],
                exercises: morningRunExercises(),
                imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400",
                priority: 2
            ),
            
            // STRENGTH WORKOUTS
            WorkoutTemplate(
                name: "Full Body Strength",
                description: "Complete strength training session targeting all major muscle groups for balanced development",
                workoutType: .strength,
                difficulty: .intermediate,
                estimatedDuration: 45 * 60,
                estimatedCalories: 350,
                targetMuscleGroups: [.fullBody, .chest, .back, .arms, .legs],
                exercises: fullBodyStrengthExercises(),
                imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400",
                priority: 3
            ),
            
            WorkoutTemplate(
                name: "Upper Body Power",
                description: "Focus on building upper body strength with compound movements and targeted exercises",
                workoutType: .strength,
                difficulty: .advanced,
                estimatedDuration: 35 * 60,
                estimatedCalories: 280,
                targetMuscleGroups: [.chest, .back, .shoulders, .arms],
                exercises: upperBodyExercises(),
                imageURL: "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400",
                priority: 4
            ),
            
            // YOGA WORKOUTS
            WorkoutTemplate(
                name: "Morning Flow",
                description: "Gentle yoga sequence to awaken your body and mind for the day ahead",
                workoutType: .yoga,
                difficulty: .beginner,
                estimatedDuration: 25 * 60,
                estimatedCalories: 150,
                targetMuscleGroups: [.fullBody],
                exercises: morningYogaExercises(),
                imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400",
                priority: 5
            ),
            
            WorkoutTemplate(
                name: "Power Yoga Flow",
                description: "Dynamic yoga sequence combining strength, flexibility, and mindfulness",
                workoutType: .yoga,
                difficulty: .intermediate,
                estimatedDuration: 40 * 60,
                estimatedCalories: 250,
                targetMuscleGroups: [.fullBody, .abs],
                exercises: powerYogaExercises(),
                imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400",
                priority: 6
            ),
            
            // STRETCHING & RECOVERY
            WorkoutTemplate(
                name: "Deep Stretch & Recovery",
                description: "Comprehensive stretching routine for muscle recovery and flexibility improvement",
                workoutType: .stretching,
                difficulty: .beginner,
                estimatedDuration: 15 * 60,
                estimatedCalories: 80,
                targetMuscleGroups: [.fullBody],
                exercises: stretchingExercises(),
                imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400",
                priority: 7
            ),
            
            // HIIT WORKOUTS
            WorkoutTemplate(
                name: "Tabata Burn",
                description: "4-minute Tabata protocol for maximum fat burning in minimal time",
                workoutType: .hiit,
                difficulty: .advanced,
                estimatedDuration: 16 * 60,
                estimatedCalories: 320,
                targetMuscleGroups: [.fullBody],
                exercises: tabataExercises(),
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400",
                priority: 8
            ),
            
            // PILATES WORKOUTS
            WorkoutTemplate(
                name: "Core Pilates",
                description: "Targeted Pilates routine focusing on core strength and stability",
                workoutType: .pilates,
                difficulty: .intermediate,
                estimatedDuration: 30 * 60,
                estimatedCalories: 200,
                targetMuscleGroups: [.abs, .back],
                exercises: pilatesExercises(),
                imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400",
                priority: 9
            ),
            
            // DANCE WORKOUTS
            WorkoutTemplate(
                name: "Cardio Dance Party",
                description: "Fun, high-energy dance workout that doesn't feel like exercise",
                workoutType: .dance,
                difficulty: .beginner,
                estimatedDuration: 25 * 60,
                estimatedCalories: 280,
                targetMuscleGroups: [.fullBody, .cardio],
                exercises: danceExercises(),
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400",
                priority: 10
            )
        ]
    }
    
    // MARK: - Exercise Builders
    
    private func hiitCardioExercises() -> [WorkoutExercise] {
        return [
            WorkoutExercise(
                name: "Burpees",
                description: "Ultimate full-body HIIT exercise combining squat, plank, push-up and jump for maximum calorie burn",
                targetMuscleGroups: [.fullBody],
                sets: nil,
                reps: 15,
                duration: nil,
                restTime: 30,
                weight: nil,
                distance: nil,
                instructions: [
                    "Start in standing position",
                    "Drop to squat position, hands on ground",
                    "Jump back to plank position",
                    "Do a push-up (optional for beginners)",
                    "Jump feet back to squat position",
                    "Explode up with arms overhead"
                ],
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 18.0,
                exerciseIcon: "figure.mixed.cardio"
            ),
            
            WorkoutExercise(
                name: "Battle Ropes",
                description: "High-intensity rope training for explosive power and cardio conditioning",
                targetMuscleGroups: [.fullBody, .arms, .shoulders],
                sets: nil,
                reps: nil,
                duration: 30,
                restTime: 30,
                weight: nil,
                distance: nil,
                instructions: [
                    "Stand with feet shoulder-width apart, holding rope ends",
                    "Keep core engaged and slight bend in knees",
                    "Alternate arms creating waves in the rope",
                    "Maintain fast, powerful movements",
                    "Keep the waves consistent and strong"
                ],
                imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 16.0,
                exerciseIcon: "figure.strengthtraining.functional"
            ),
            
            WorkoutExercise(
                name: "Jump Squats",
                description: "Explosive lower body exercise combining strength and plyometric power",
                targetMuscleGroups: [.legs, .glutes],
                sets: nil,
                reps: 20,
                duration: nil,
                restTime: 20,
                weight: nil,
                distance: nil,
                instructions: [
                    "Stand with feet shoulder-width apart",
                    "Lower into squat position with thighs parallel to ground",
                    "Explode up jumping as high as possible",
                    "Land softly back in squat position",
                    "Immediately repeat the movement"
                ],
                imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 14.0,
                exerciseIcon: "figure.jump"
            ),
            
            WorkoutExercise(
                name: "Russian Twists",
                description: "Core-focused rotational exercise for oblique strength and stability",
                targetMuscleGroups: [.abs],
                sets: nil,
                reps: 30,
                duration: nil,
                restTime: 15,
                weight: nil,
                distance: nil,
                instructions: [
                    "Sit on ground with knees bent, feet lifted",
                    "Lean back slightly to engage core",
                    "Hold hands together in front of chest",
                    "Rotate torso left and right, touching ground beside hips",
                    "Keep feet off ground throughout movement"
                ],
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 10.0,
                exerciseIcon: "figure.core.training"
            )
        ]
    }
    
    private func morningRunExercises() -> [WorkoutExercise] {
        return [
            WorkoutExercise(
                name: "Warm-up Walk",
                description: "Gentle walking to prepare for running",
                targetMuscleGroups: [.legs, .cardio],
                sets: nil,
                reps: nil,
                duration: 300,
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
                caloriesPerMinute: 5.0,
                exerciseIcon: "figure.walk"
            ),
            
            WorkoutExercise(
                name: "Easy Jog",
                description: "Comfortable jogging pace",
                targetMuscleGroups: [.legs, .cardio, .calves],
                sets: nil,
                reps: nil,
                duration: 1200,
                restTime: nil,
                weight: nil,
                distance: 3000,
                instructions: [
                    "Maintain conversational pace",
                    "Focus on rhythmic breathing",
                    "Land midfoot, not heel",
                    "Keep posture upright"
                ],
                imageURL: nil,
                videoURL: nil,
                caloriesPerMinute: 12.0,
                exerciseIcon: "figure.run"
            ),
            
            WorkoutExercise(
                name: "Cool-down Walk",
                description: "Gradual cooldown to prevent injury",
                targetMuscleGroups: [.legs],
                sets: nil,
                reps: nil,
                duration: 300,
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
                caloriesPerMinute: 4.0,
                exerciseIcon: "figure.walk"
            )
        ]
    }
    
    private func fullBodyStrengthExercises() -> [WorkoutExercise] {
        return [
            WorkoutExercise(
                name: "Barbell Bench Press",
                description: "Classic chest builder and upper body strength foundation. Essential for developing pectoral muscles, deltoids, and triceps.",
                targetMuscleGroups: [.chest, .shoulders, .arms],
                sets: 3,
                reps: 8,
                duration: nil,
                restTime: 120,
                weight: 165,
                distance: nil,
                instructions: [
                    "Lie on a flat bench with your eyes under the bar.",
                    "Grip the bar slightly wider than shoulder-width.",
                    "Lower the bar to your chest with controlled movement.",
                    "Press the bar back up to the starting position until your arms are fully extended."
                ],
                imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 10.0,
                exerciseIcon: "lungs.fill"
            ),
            
            WorkoutExercise(
                name: "Barbell Deadlift",
                description: "The king of all exercises. Builds total body strength and power through posterior chain development.",
                targetMuscleGroups: [.back, .legs, .glutes],
                sets: 3,
                reps: 5,
                duration: nil,
                restTime: 180,
                weight: 225,
                distance: nil,
                instructions: [
                    "Stand with feet hip-width apart, bar over mid-foot.",
                    "Hinge at hips and bend knees to grip the bar.",
                    "Keep chest up, shoulders back, and core engaged.",
                    "Drive through heels and extend hips to lift the bar.",
                    "Lower the bar by hinging at hips first, then bending knees."
                ],
                imageURL: "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 12.0,
                exerciseIcon: "figure.strengthtraining.traditional"
            ),
            
            WorkoutExercise(
                name: "Barbell Squat",
                description: "Fundamental lower body exercise for building leg and glute strength. The foundation of functional movement.",
                targetMuscleGroups: [.legs, .glutes],
                sets: 3,
                reps: 10,
                duration: nil,
                restTime: 120,
                weight: 185,
                distance: nil,
                instructions: [
                    "Position bar on your upper back, just below the trapezius.",
                    "Stand with feet shoulder-width apart, toes slightly out.",
                    "Descend by pushing hips back and bending knees.",
                    "Go down until thighs are parallel to the ground.",
                    "Drive through heels to return to starting position."
                ],
                imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 9.0,
                exerciseIcon: "figure.strengthtraining.functional"
            ),
            
            WorkoutExercise(
                name: "Barbell Rows",
                description: "Essential back building exercise for developing pulling strength and improving posture. Targets the entire posterior chain.",
                targetMuscleGroups: [.back, .shoulders, .arms],
                sets: 3,
                reps: 8,
                duration: nil,
                restTime: 90,
                weight: 135,
                distance: nil,
                instructions: [
                    "Stand with feet hip-width apart, holding the bar with overhand grip.",
                    "Hinge at hips, keeping knees slightly bent and back straight.",
                    "Let the bar hang with arms extended.",
                    "Pull the bar to your lower chest/upper abdomen.",
                    "Squeeze shoulder blades together and lower with control."
                ],
                imageURL: "https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 8.0,
                exerciseIcon: "figure.strengthtraining.traditional"
            )
        ]
    }
    
    private func upperBodyExercises() -> [WorkoutExercise] {
        return [
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
                caloriesPerMinute: 9.0,
                exerciseIcon: "figure.strengthtraining.functional.pushup"
            )
        ]
    }
    
    private func morningYogaExercises() -> [WorkoutExercise] {
        return [
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
                imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 6.0,
                exerciseIcon: "figure.yoga"
            ),
            
            WorkoutExercise(
                name: "Downward Facing Dog",
                description: "Classic yoga pose for full-body stretch and strength",
                targetMuscleGroups: [.fullBody, .back, .shoulders],
                sets: nil,
                reps: nil,
                duration: 60,
                restTime: 15,
                weight: nil,
                distance: nil,
                instructions: [
                    "Start on hands and knees",
                    "Tuck toes under and lift hips up",
                    "Straighten legs and create inverted V-shape",
                    "Ground through hands and feet",
                    "Breathe deeply"
                ],
                imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 4.0,
                exerciseIcon: "figure.yoga"
            ),
            
            WorkoutExercise(
                name: "Child's Pose",
                description: "Restorative yoga pose for relaxation",
                targetMuscleGroups: [.back, .shoulders],
                sets: nil,
                reps: nil,
                duration: 45,
                restTime: 0,
                weight: nil,
                distance: nil,
                instructions: [
                    "Kneel on the floor",
                    "Touch your big toes together",
                    "Sit back on your heels",
                    "Fold forward with arms extended",
                    "Rest forehead on the ground"
                ],
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 2.0,
                exerciseIcon: "figure.yoga"
            )
        ]
    }
    
    private func powerYogaExercises() -> [WorkoutExercise] {
        return [
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
                imageURL: "https://images.unsplash.com/photo-1506629905607-d5f99e2cdb40?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 7.0,
                exerciseIcon: "figure.yoga"
            ),
            
            WorkoutExercise(
                name: "Vinyasa Flow",
                description: "Flowing sequence linking breath with movement",
                targetMuscleGroups: [.fullBody, .abs],
                sets: 3,
                reps: nil,
                duration: 90,
                restTime: 30,
                weight: nil,
                distance: nil,
                instructions: [
                    "Flow from chaturanga to upward dog",
                    "Transition to downward dog",
                    "Step forward to standing forward fold",
                    "Rise to mountain pose",
                    "Synchronize breath with movement"
                ],
                imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 8.0,
                exerciseIcon: "figure.yoga"
            ),
            
            WorkoutExercise(
                name: "Tree Pose",
                description: "Balancing pose to improve focus and stability",
                targetMuscleGroups: [.legs, .fullBody],
                sets: 2,
                reps: nil,
                duration: 45,
                restTime: 15,
                weight: nil,
                distance: nil,
                instructions: [
                    "Stand on one leg",
                    "Place other foot on inner thigh",
                    "Find your balance point",
                    "Bring palms together at heart center",
                    "Focus on a fixed point ahead"
                ],
                imageURL: "https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=300&fit=crop",
                videoURL: nil,
                caloriesPerMinute: 3.0,
                exerciseIcon: "figure.yoga"
            )
        ]
    }
    
    private func stretchingExercises() -> [WorkoutExercise] {
        return [
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
                caloriesPerMinute: 2.0,
                exerciseIcon: "figure.flexibility"
            )
        ]
    }
    
    private func tabataExercises() -> [WorkoutExercise] {
        return [
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
                caloriesPerMinute: 20.0,
                exerciseIcon: "timer"
            )
        ]
    }
    
    private func pilatesExercises() -> [WorkoutExercise] {
        return [
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
                caloriesPerMinute: 7.0,
                exerciseIcon: "figure.pilates"
            )
        ]
    }
    
    private func danceExercises() -> [WorkoutExercise] {
        return [
            WorkoutExercise(
                name: "Dance Cardio",
                description: "High-energy dance moves",
                targetMuscleGroups: [.fullBody, .cardio],
                sets: nil,
                reps: nil,
                duration: 1500,
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
                caloriesPerMinute: 11.0,
                exerciseIcon: "music.note"
            )
        ]
    }
}