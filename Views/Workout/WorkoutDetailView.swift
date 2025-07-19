import SwiftUI

@available(iOS 16.0, *)
struct WorkoutDetailView: View {
    let workout: WorkoutSession
    let onStartWorkout: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header image and info
                    headerSection
                    
                    // Workout details
                    detailsSection
                    
                    // Exercises list
                    exercisesSection
                    
                    Spacer(minLength: 100)
                }
                .padding(20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.043, green: 0.051, blue: 0.090), // #0B0D17
                        Color(red: 0.102, green: 0.106, blue: 0.145)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .overlay(alignment: .bottom) {
                startButton
                    .padding(20)
            }
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Workout type and difficulty
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: workout.workoutType.icon)
                        .font(.system(size: 16, weight: .semibold))
                    Text(workout.workoutType.displayName)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(hex: workout.workoutType.primaryColor))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: workout.workoutType.primaryColor).opacity(0.15))
                )
                
                Spacer()
                
                Text(workout.difficulty.displayName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: workout.difficulty.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: workout.difficulty.color).opacity(0.15))
                    )
            }
            
            // Title and description
            Text(workout.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            if let description = workout.description {
                Text(description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(Int(workout.estimatedDuration / 60))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Minutes")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(workout.estimatedCalories)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Calories")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(workout.exercises.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Exercises")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    @ViewBuilder
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack(spacing: 16) {
                        // Exercise number
                        ZStack {
                            Circle()
                                .fill(Color(hex: workout.workoutType.primaryColor).opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: workout.workoutType.primaryColor))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(exercise.exerciseTypeDescription)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var startButton: some View {
        Button(action: onStartWorkout) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                
                Text("START WORKOUT")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: workout.workoutType.primaryColor),
                        Color(hex: workout.workoutType.secondaryColor)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}