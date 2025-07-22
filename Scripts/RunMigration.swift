import FirebaseCore
import FirebaseFirestore

/// Quick script to run workout data migration
/// Add this to your AppDelegate or run once manually
func runWorkoutMigration() async {
    let migration = WorkoutDataMigration()
    await migration.runMigration()
}

// MARK: - For testing - you can call this from any view
struct MigrationTester: View {
    @State private var isRunning = false
    @State private var message = "Ready to migrate"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Workout Data Migration")
                .font(.title)
            
            Text(message)
                .foregroundColor(.secondary)
            
            Button("Run Migration") {
                runMigration()
            }
            .disabled(isRunning)
            
            if isRunning {
                ProgressView()
            }
        }
        .padding()
    }
    
    private func runMigration() {
        isRunning = true
        message = "Migrating data..."
        
        Task {
            let migration = WorkoutDataMigration()
            await migration.runMigration()
            
            await MainActor.run {
                isRunning = false
                message = "Migration completed!"
            }
        }
    }
}