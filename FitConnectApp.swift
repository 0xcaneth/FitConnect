@main
struct FitConnectApp: App {
    @StateObject private var sessionStore = SessionStore()
    
    init() {
        print("🔧 FitConnectApp initializing...")
        configureFirebase()
        
        // MIGRATION - Run only once to fix Firebase data
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Task {
                await runWorkoutExerciseTypeMigration()
            }
        }
        #endif
    }
    
    // ... rest of existing code ...
}

// Add the migration function
func runWorkoutExerciseTypeMigration() async {
    let migration = WorkoutExerciseTypeMigration()
    await migration.runMigration()
}