import SwiftUI

struct CustomWorkoutBuilderView: View {
    let selectedExercises: [WorkoutExercise]
    let workoutType: WorkoutType
    let onWorkoutCreated: ([WorkoutExercise]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var workoutName = ""
    @State private var showContent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        HStack {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("Build Workout")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Save") {
                                onWorkoutCreated(selectedExercises)
                            }
                            .foregroundColor(Color(hex: workoutType.primaryColor))
                            .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Workout name input
                        TextField("Enter workout name", text: $workoutName)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                    }
                    
                    // Selected exercises list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(selectedExercises, id: \.id) { exercise in
                                HStack {
                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if let sets = exercise.sets, let reps = exercise.reps {
                                        Text("\(sets)×\(reps)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}