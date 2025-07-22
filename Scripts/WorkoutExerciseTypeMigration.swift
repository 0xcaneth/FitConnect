import Foundation
import FirebaseFirestore

/// Firebase migration script to add exerciseType field to all workout exercises
class WorkoutExerciseTypeMigration {
    private let db = Firestore.firestore()
    
    /// Exercise type mapping based on exercise name patterns
    private let exerciseTypeMapping: [String: String] = [
        // Cardio exercises
        "jumping jacks": "cardio",
        "high knees": "cardio", 
        "mountain climbers": "cardio",
        "burpees": "plyometric",
        "battle ropes": "cardio",
        "interval running": "endurance",
        
        // Strength exercises
        "barbell squat": "strength",
        "barbell bench press": "strength", 
        "barbell deadlift": "strength",
        "barbell rows": "strength",
        "jump squats": "plyometric",
        "russian twists": "strength",
        
        // Yoga exercises
        "sun salutation": "flexibility",
        "cat cow stretch": "flexibility",
        "child's pose": "flexibility", 
        "single leg stretch": "flexibility",
        
        // Pilates exercises
        "plank": "strength",
        
        // Dance exercises
        "salsa basic": "cardio",
        "hip hop groove": "cardio", 
        "zumba fusion": "cardio",
        
        // Stretching exercises
        "hamstring stretch": "flexibility",
        "hip flexor stretch": "flexibility",
        "seated spinal twist": "flexibility"
    ]
    
    func runMigration() async {
        print("🚀 Starting workout exercise type migration...")
        
        do {
            // Get all workout templates
            let snapshot = try await db.collection("workoutTemplates").getDocuments()
            
            print("📊 Found \(snapshot.documents.count) workout templates to migrate")
            
            for document in snapshot.documents {
                await migrateWorkoutTemplate(document: document)
            }
            
            print("✅ Migration completed successfully!")
            
        } catch {
            print("❌ Migration failed: \(error)")
        }
    }
    
    private func migrateWorkoutTemplate(document: QueryDocumentSnapshot) async {
        let documentId = document.documentID
        let data = document.data()
        
        print("🔄 Migrating template: \(documentId)")
        
        guard let exercises = data["exercises"] as? [[String: Any]] else {
            print("⚠️ No exercises found in template: \(documentId)")
            return
        }
        
        var updatedExercises: [[String: Any]] = []
        
        for var exercise in exercises {
            let exerciseName = (exercise["name"] as? String ?? "").lowercased()
            
            // Add exerciseType field
            let exerciseType = determineExerciseType(name: exerciseName, workoutType: data["workoutType"] as? String)
            exercise["exerciseType"] = exerciseType
            
            updatedExercises.append(exercise)
            print("  ✅ Added exerciseType '\(exerciseType)' to exercise: \(exercise["name"] ?? "unknown")")
        }
        
        // Update the document
        do {
            try await db.collection("workoutTemplates").document(documentId).updateData([
                "exercises": updatedExercises,
                "updatedAt": Timestamp()
            ])
            
            print("✅ Successfully updated template: \(documentId)")
            
        } catch {
            print("❌ Failed to update template \(documentId): \(error)")
        }
    }
    
    private func determineExerciseType(name: String, workoutType: String?) -> String {
        // First, try exact name mapping
        if let mappedType = exerciseTypeMapping[name] {
            return mappedType
        }
        
        // Then, try partial name matching
        for (keyword, type) in exerciseTypeMapping {
            if name.contains(keyword) {
                return type
            }
        }
        
        // Finally, fallback based on workout type
        switch workoutType?.lowercased() {
        case "cardio":
            return "cardio"
        case "strength":
            return "strength"
        case "yoga":
            return "flexibility"
        case "pilates":
            return "strength"
        case "hiit":
            return "plyometric"
        case "dance":
            return "cardio"
        case "stretching":
            return "flexibility"
        case "running":
            return "endurance"
        default:
            return "strength" // Safe default
        }
    }
}

// MARK: - Migration Runner Function

/// Run this function to execute the migration
func runWorkoutExerciseTypeMigration() async {
    let migration = WorkoutExerciseTypeMigration()
    await migration.runMigration()
}