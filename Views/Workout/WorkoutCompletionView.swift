import SwiftUI

/// Nike-level workout completion celebration screen
@available(iOS 16.0, *)
struct WorkoutCompletionView: View {
    let completionData: WorkoutCompletionData
    let workout: WorkoutSession
    let onDone: () -> Void
    let onShareWorkout: () -> Void
    
    @State private var showCelebration = false
    @State private var animateStats = false
    @State private var currentStatIndex = 0
    
    var body: some View {
        ZStack {
            // Celebration background
            celebrationBackground
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 32) {
                    // Celebration header
                    celebrationHeader
                    
                    // Workout completion stats
                    statsSection
                    
                    // Exercise summary
                    exerciseSummarySection
                    
                    // Achievement badges (if any)
                    if !achievements.isEmpty {
                        achievementSection
                    }
                    
                    // Action buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startCelebrationSequence()
        }
    }
    
    // MARK: - Background - FIXED WITH DARK THEME FROM SECOND IMAGE
    
    @ViewBuilder
    private var celebrationBackground: some View {
        ZStack {
            // BASE DARK GRADIENT BACKGROUND - LIKE SECOND IMAGE
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.15),   // Dark navy
                    Color(red: 0.15, green: 0.15, blue: 0.25), // Medium dark
                    Color(red: 0.05, green: 0.05, blue: 0.1)   // Very dark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle overlay pattern - much more subtle
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.1),
                    Color.clear,
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Celebration Header - UPDATED WITH ORANGE ICON
    
    @ViewBuilder
    private var celebrationHeader: some View {
        VStack(spacing: 20) {
            // Success icon - RESTORED ORANGE THEME
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.orange,
                                Color(red: 1.0, green: 0.6, blue: 0.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)
                    .opacity(showCelebration ? 1.0 : 0.0)
            }
            .onAppear {
            }
            
            // Completion message
            VStack(spacing: 12) {
                Text(completionMessage)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .scaleEffect(showCelebration ? 1.0 : 0.8)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                Text(workout.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .scaleEffect(showCelebration ? 1.0 : 0.8)
                    .opacity(showCelebration ? 1.0 : 0.0)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                Text(motivationalMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .scaleEffect(showCelebration ? 1.0 : 0.8)
                    .opacity(showCelebration ? 1.0 : 0.0)
            }
        }
    }
    
    // MARK: - Stats Section
    
    @ViewBuilder
    private var statsSection: some View {
        VStack(spacing: 20) {
            Text("Workout Summary")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(animateStats ? 1.0 : 0.0)
                .offset(y: animateStats ? 0 : 20)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            // IMPROVED GRID WITH EQUAL SPACING
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                CompletionStatCard(
                    title: "Duration",
                    value: formattedDuration,
                    subtitle: completionData.isFullyCompleted ? "Completed" : "Partial",
                    icon: "clock.fill",
                    color: .blue,
                    animationDelay: 0.0,
                    showAnimation: animateStats
                )
                
                CompletionStatCard(
                    title: "Calories",
                    value: "\(completionData.totalCaloriesBurned)",
                    subtitle: "kcal burned",
                    icon: "flame.fill",
                    color: .red,
                    animationDelay: 0.1,
                    showAnimation: animateStats
                )
                
                CompletionStatCard(
                    title: "Exercises",
                    value: "\(completionData.completedExercises.count)",
                    subtitle: "of \(workout.exercises.count)",
                    icon: "figure.strengthtraining.traditional",
                    color: .green,
                    animationDelay: 0.2,
                    showAnimation: animateStats
                )
                
                CompletionStatCard(
                    title: "Completion",
                    value: "\(Int(completionData.completionPercentage * 100))%",
                    subtitle: completionData.isFullyCompleted ? "Perfect!" : "Great effort!",
                    icon: "chart.pie.fill",
                    color: .purple,
                    animationDelay: 0.3,
                    showAnimation: animateStats
                )
            }
            .padding(.horizontal, 4) // Small padding for better spacing
        }
    }
    
    // MARK: - Exercise Summary
    
    @ViewBuilder
    private var exerciseSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises Completed")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(completionData.completedExercises.enumerated()), id: \.element.id) { index, completedExercise in
                    CompletedExerciseRow(
                        exercise: completedExercise,
                        index: index,
                        workoutColor: .orange
                    )
                    .opacity(animateStats ? 1.0 : 0.0)
                    .offset(x: animateStats ? 0 : -20)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(0.4 + Double(index) * 0.1),
                        value: animateStats
                    )
                }
            }
        }
    }
    
    // MARK: - Achievement Section
    
    @ViewBuilder
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements Unlocked! ")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementBadge(achievement: achievement)
                        .scaleEffect(animateStats ? 1.0 : 0.5)
                        .opacity(animateStats ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(0.8),
                            value: animateStats
                        )
                }
            }
        }
    }
    
    // MARK: - Action Buttons - RESTORED ORANGE THEME
    
    @ViewBuilder
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Share workout button
            Button(action: onShareWorkout) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("SHARE WORKOUT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.8),
                            Color.red.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // Done button
            Button(action: onDone) {
                Text("DONE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .opacity(animateStats ? 1.0 : 0.0)
        .offset(y: animateStats ? 0 : 30)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.8)
            .delay(1.0),
            value: animateStats
        )
    }
    
    // MARK: - Helper Properties
    
    private var completionMessage: String {
        if completionData.isFullyCompleted {
            return "WORKOUT COMPLETE!"
        } else if completionData.completionPercentage > 0.7 {
            return "GREAT EFFORT!"
        } else {
            return "GOOD START!"
        }
    }
    
    private var motivationalMessage: String {
        if completionData.isFullyCompleted {
            return "You crushed it! Every rep, every set - perfectly executed. You're getting stronger! "
        } else if completionData.completionPercentage > 0.7 {
            return "Fantastic work! You pushed through and made real progress. Keep building that momentum! "
        } else {
            return "Every workout counts! You took the first step and that's what matters most. Tomorrow you'll go even further! "
        }
    }
    
    private var formattedDuration: String {
        let minutes = Int(completionData.totalDuration / 60)
        let seconds = Int(completionData.totalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var achievements: [WorkoutAchievement] {
        var earned: [WorkoutAchievement] = []
        
        // Check for various achievements
        if completionData.isFullyCompleted {
            earned.append(WorkoutAchievement(
                id: "workout-complete",
                title: "Workout Complete",
                description: "Finished the entire workout",
                icon: "checkmark.seal.fill",
                color: .green
            ))
        }
        
        if completionData.totalCaloriesBurned > 200 {
            earned.append(WorkoutAchievement(
                id: "calorie-burner",
                title: "Calorie Crusher",
                description: "Burned 200+ calories",
                icon: "flame.fill",
                color: .orange
            ))
        }
        
        if completionData.totalDuration > 1800 { // 30 minutes
            earned.append(WorkoutAchievement(
                id: "endurance-champ",
                title: "Endurance Champion",
                description: "Worked out for 30+ minutes",
                icon: "timer",
                color: .blue
            ))
        }
        
        return earned
    }
    
    // MARK: - Helper Methods
    
    private func startCelebrationSequence() {
        // Initial celebration animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
            showCelebration = true
        }
        
        // Stats animation with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateStats = true
            }
        }
    }
}

// MARK: - Completion Stat Card

struct CompletionStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let animationDelay: Double
    let showAnimation: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140) // FIXED HEIGHT
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(showAnimation ? 1.0 : 0.8)
        .opacity(showAnimation ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.6, dampingFraction: 0.8)
            .delay(animationDelay),
            value: showAnimation
        )
    }
}

// MARK: - Completed Exercise Row

struct CompletedExerciseRow: View {
    let exercise: CompletedExercise
    let index: Int
    let workoutColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise number
            ZStack {
                Circle()
                    .fill(workoutColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Text("\(index + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                HStack(spacing: 8) {
                    if exercise.setsCompleted > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "repeat.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(exercise.setsCompleted) sets")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    if exercise.duration > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(Int(exercise.duration))s")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        
                        Text("\(exercise.caloriesBurned) kcal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            
            Spacer()
            
            // Checkmark
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Achievement Badge

struct AchievementBadge: View {
    let achievement: WorkoutAchievement
    
    @State private var shine = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                achievement.color,
                                achievement.color.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: achievement.color.opacity(0.4), radius: 8, x: 0, y: 4)
                
                // Shine effect
                if shine {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.4), .clear],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: 25
                            )
                        )
                        .frame(width: 50, height: 50)
                        .animation(.easeInOut(duration: 1.5).repeatForever(), value: shine)
                }
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(achievement.description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            shine = true
        }
    }
}

// MARK: - Supporting Types

struct WorkoutAchievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
}

#if DEBUG
@available(iOS 16.0, *)
struct WorkoutCompletionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample workout session for preview only
        let sampleWorkout = WorkoutSession(
            userId: "preview-user",
            workoutType: .hiit,
            name: "Morning HIIT",
            description: "Sample workout for preview",
            estimatedDuration: 1200,
            estimatedCalories: 250,
            difficulty: .intermediate,
            targetMuscleGroups: [.fullBody],
            exercises: [
                WorkoutExercise(
                    name: "Jumping Jacks",
                    exerciseType: .cardio,
                    targetMuscleGroups: [.fullBody],
                    duration: 30,
                    instructions: ["Jump with arms and legs"],
                    exerciseIcon: "figure.jumper"
                )
            ]
        )
        
        let sampleCompletionData = WorkoutCompletionData(
            workoutId: "preview-id",
            workoutName: "Morning HIIT",
            workoutType: .hiit,
            startTime: Date().addingTimeInterval(-1200),
            endTime: Date(),
            totalDuration: 1200,
            totalCaloriesBurned: 250,
            completedExercises: [
                CompletedExercise(
                    exercise: sampleWorkout.exercises.first!,
                    setsCompleted: 1,
                    repsPerSet: [],
                    duration: 30,
                    caloriesBurned: 50
                )
            ],
            isFullyCompleted: true,
            userRating: nil
        )
        
        WorkoutCompletionView(
            completionData: sampleCompletionData,
            workout: sampleWorkout,
            onDone: {},
            onShareWorkout: {}
        )
    }
}
#endif