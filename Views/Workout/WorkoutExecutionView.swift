import SwiftUI
import AVFoundation
import Combine

// Nike-level interactive workout execution experience
// Real-time workout session with video guidance, timers, and progress tracking
@available(iOS 16.0, *)
struct WorkoutExecutionView: View {
    let workout: WorkoutSession
    let onWorkoutComplete: (WorkoutCompletionData) -> Void
    let onDismiss: () -> Void
    
    @StateObject private var workoutEngine = WorkoutExecutionEngine()
    @StateObject private var motivationEngine = MotivationEngine()
    @Environment(\.dismiss) private var dismiss
    
    // UI State
    @State private var showExitConfirmation = false
    @State private var showRestPeriod = false
    @State private var showCompletionCelebration = false
    @State private var animateProgress = false
    
    var body: some View {
        ZStack {
            // Main content based on state
            if workoutEngine.isCompleted {
                WorkoutCompletionView(
                    completionData: workoutEngine.completionData,
                    workout: workout,
                    onDone: {
                        onWorkoutComplete(workoutEngine.completionData)
                    },
                    onShareWorkout: {
                        // Handle sharing
                    }
                )
            } else if showRestPeriod {
                RestPeriodView(
                    timeRemaining: workoutEngine.restTimeRemaining,
                    nextExercise: workoutEngine.nextExercise,
                    motivationMessage: motivationEngine.getRestMotivation(),
                    onSkipRest: {
                        workoutEngine.skipRest()
                        showRestPeriod = false
                    },
                    onRestComplete: {
                        showRestPeriod = false
                        workoutEngine.startNextExercise()
                    }
                )
            } else {
                // MAIN WORKOUT EXECUTION - FINAL FIX
                FitConnectWorkoutExecutionView(
                    workoutEngine: workoutEngine,
                    totalExercises: workout.exercises.count, // FIXED: Pass total exercises count
                    onSetComplete: {
                        handleSetCompletion()
                    },
                    onRepCompleted: {
                        workoutEngine.incrementRep()
                    },
                    onSkipCurrentSet: {
                        workoutEngine.skipCurrentSet()
                    },
                    onNextExercise: {
                        handleExerciseCompletion()
                    },
                    onPauseWorkout: {
                        workoutEngine.pauseWorkout()
                    },
                    onResumeWorkout: {
                        workoutEngine.resumeWorkout()
                    },
                    onExitWorkout: {
                        workoutEngine.pauseWorkout()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showExitConfirmation = true
                        }
                    }
                )
            }
            
            // Exit confirmation dialog
            if showExitConfirmation {
                ExitConfirmationOverlay(
                    onContinue: {
                        showExitConfirmation = false
                        workoutEngine.resumeWorkout()
                    },
                    onSaveAndExit: {
                        onWorkoutComplete(workoutEngine.getPartialCompletionData())
                    },
                    onExitWithoutSaving: {
                        onDismiss()
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            setupWorkout()
        }
        .onDisappear {
            workoutEngine.pauseWorkout()
        }
        .onChange(of: workoutEngine.isRestTime) { isResting in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showRestPeriod = isResting
            }
        }
        .onChange(of: workoutEngine.isCompleted) { completed in
            if completed {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    showCompletionCelebration = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupWorkout() {
        print("[WorkoutExecution] 🚀 Setting up workout: \(workout.name)")
        workoutEngine.initialize(with: workout)
        motivationEngine.startSession(workoutType: workout.workoutType)
        
        // Start the first exercise
        workoutEngine.startWorkout()
    }
    
    private func handleSetCompletion() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        workoutEngine.completeSet()
        motivationEngine.celebrateSetCompletion(
            set: workoutEngine.currentSet,
            totalSets: workoutEngine.totalSets
        )
        
        if workoutEngine.isExerciseCompleted {
            handleExerciseCompletion()
        }
    }
    
    private func handleExerciseCompletion() {
        let successFeedback = UINotificationFeedbackGenerator()
        successFeedback.notificationOccurred(.success)
        
        workoutEngine.completeExercise()
        motivationEngine.celebrateExerciseCompletion(
            exercise: workoutEngine.currentExercise?.name ?? ""
        )
        
        if workoutEngine.hasNextExercise {
            // Start rest period
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showRestPeriod = true
            }
            workoutEngine.startRestPeriod()
        } else {
            // Workout complete!
            workoutEngine.completeWorkout()
        }
    }
}

// MARK: - Rest Period View Component
@available(iOS 16.0, *)
struct RestPeriodView: View {
    let timeRemaining: TimeInterval
    let nextExercise: WorkoutExercise?
    let motivationMessage: String
    let onSkipRest: () -> Void
    let onRestComplete: () -> Void
    
    @State private var pulseAnimation = false
    
    var formattedTime: String {
        let seconds = Int(timeRemaining)
        return "\(seconds)"
    }
    
    var body: some View {
        ZStack {
            // SOLID BACKGROUND
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.10, green: 0.20, blue: 0.45),
                    Color(red: 0.15, green: 0.25, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Rest indicator
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseAnimation = true
                        }
                    }
                    
                    Text("REST TIME")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                }
                
                // Timer
                VStack(spacing: 12) {
                    Text(formattedTime)
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("seconds remaining")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Motivation
                Text(motivationMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Next exercise preview
                if let nextExercise = nextExercise {
                    VStack(spacing: 8) {
                        Text("UP NEXT")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(nextExercise.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 40)
                }
                
                // Skip button
                Button(action: onSkipRest) {
                    Text("SKIP REST")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.05, green: 0.15, blue: 0.35))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                }
                
                Spacer()
            }
        }
        .onChange(of: timeRemaining) { remaining in
            if remaining <= 0 {
                onRestComplete()
            }
        }
    }
}

// MARK: - FitConnect Workout Execution View - FINAL FIX FOR VIDEO LOADING

struct FitConnectWorkoutExecutionView: View {
    // FIXED: Use the engine as the single source of truth
    @ObservedObject var workoutEngine: WorkoutExecutionEngine
    let totalExercises: Int
    
    // Callbacks
    let onSetComplete: () -> Void
    let onRepCompleted: () -> Void
    let onSkipCurrentSet: () -> Void
    let onNextExercise: () -> Void
    let onPauseWorkout: () -> Void
    let onResumeWorkout: () -> Void
    let onExitWorkout: () -> Void
    
    @State private var videoURL: URL?
    @State private var isLoadingVideo = true
    @State private var showInstructions = false
    @State private var isVideoReady = false
    @State private var isVideoPlaying = false
    
    @State private var lastExerciseName: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        Button(action: onExitWorkout) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        
                        Spacer()
                        
                        // FIXED: Use totalExercises parameter
                        Text("\(workoutEngine.currentExerciseIndex + 1) of \(totalExercises) exercises")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Button(action: {
                            if let exercise = workoutEngine.currentExercise, exercise.isTimeBasedExercise {
                                if isVideoPlaying {
                                    isVideoPlaying = false
                                    workoutEngine.pauseExerciseTimer()
                                    print("[WorkoutExecution] 🎮 PAUSE: Video + Timer paused")
                                } else {
                                    isVideoPlaying = true
                                    workoutEngine.startExerciseTimer()
                                    print("[WorkoutExecution] 🎮 PLAY: Video + Timer started")
                                }
                            } else if !isLoadingVideo {
                                print("[WorkoutExecution] 🔨 USER FORCE: Making video ready")
                                isVideoReady = true
                                isVideoPlaying = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isVideoReady ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                                    .frame(width: 44, height: 44)
                                
                                if isVideoReady {
                                    Image(systemName: isVideoPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                } else if isLoadingVideo {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        if let videoURL = videoURL {
                            SynchronizedVideoPlayerView(
                                url: videoURL,
                                isPlaying: isVideoPlaying,
                                onVideoReady: {
                                    print("[WorkoutExecution] 📺 Video component says ready!")
                                    isLoadingVideo = false
                                    isVideoReady = true
                                }
                            )
                            .aspectRatio(contentMode: .fill) // Ensure it fills the frame
                            .frame(height: min(geometry.size.height * 0.45, 350))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                            .padding(.horizontal, 20)
                            .overlay(
                                Group {
                                    if isLoadingVideo {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(
                                                VStack(spacing: 12) {
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                                        .scaleEffect(1.2)
                                                    
                                                    Text("Loading video...")
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(.gray)
                                                }
                                            )
                                            .padding(.horizontal, 20)
                                    }
                                }
                            )
                            
                        } else if isLoadingVideo {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: min(geometry.size.height * 0.45, 350))
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        
                                        Text("Loading video...")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                    }
                                )
                                .padding(.horizontal, 20)
                                
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: min(geometry.size.height * 0.45, 350))
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: workoutEngine.currentExercise?.exerciseIcon ?? "figure.strengthtraining.traditional")
                                            .font(.system(size: 50, weight: .light))
                                            .foregroundColor(.gray)
                                        
                                        Text("Ready to Start!")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Text("Tap play button to start")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.gray.opacity(0.7))
                                    }
                                )
                                .padding(.horizontal, 20)
                                .onAppear {
                                    print("[WorkoutExecution] 🎯 Fallback ready - no video mode")
                                    isVideoReady = true
                                    isLoadingVideo = false
                                }
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Overall Progress")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(workoutEngine.overallProgress * 100))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.blue)
                                    .animation(.easeInOut(duration: 0.3), value: workoutEngine.overallProgress)
                            }
                            
                            ProgressView(value: workoutEngine.overallProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .scaleEffect(y: 2.0)
                                .animation(.easeInOut(duration: 0.5), value: workoutEngine.overallProgress)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 0) {
                        VStack(spacing: 20) {
                            Text(workoutEngine.currentExercise?.name ?? "Exercise")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                            
                            if !isVideoReady && isLoadingVideo {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                        .scaleEffect(0.8)
                                    
                                    Text("Loading exercise video...")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                                .multilineTextAlignment(.center)
                            } else if !isVideoReady && !isLoadingVideo {
                                Text("Video not available - workout ready!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                    .multilineTextAlignment(.center)
                            } else if isVideoReady && !isVideoPlaying && (workoutEngine.currentExercise?.isTimeBasedExercise == true) {
                                Text("Ready to start! Tap play button above.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                            } else if workoutEngine.showMotivation && !workoutEngine.motivationMessage.isEmpty {
                                Text(workoutEngine.motivationMessage)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            if let exercise = workoutEngine.currentExercise {
                                if exercise.isTimeBasedExercise {
                                    HStack(spacing: 40) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Elapsed")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.gray)
                                            
                                            Text(formatElapsedTime(totalTime: exercise.duration ?? 30, remaining: workoutEngine.exerciseTimeRemaining))
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Text(formatTime(workoutEngine.exerciseTimeRemaining))
                                            .font(.system(size: 48, weight: .black))
                                            .foregroundColor(isVideoPlaying ? .black : .gray)
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("Set")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.gray)
                                            
                                            Text("\(workoutEngine.currentSet)/\(workoutEngine.totalSets)")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                    
                                } else {
                                    VStack(spacing: 16) {
                                        HStack(spacing: 20) {
                                            VStack(spacing: 4) {
                                                Text("CURRENT SET")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.gray)
                                                    .tracking(1)
                                                
                                                Text("\(workoutEngine.currentSet)")
                                                    .font(.system(size: 32, weight: .black))
                                                    .foregroundColor(.black)
                                            }
                                            
                                            Text("of")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.gray)
                                            
                                            VStack(spacing: 4) {
                                                Text("TOTAL SETS")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.gray)
                                                    .tracking(1)
                                                
                                                Text("\(workoutEngine.totalSets)")
                                                    .font(.system(size: 32, weight: .black))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        VStack(spacing: 8) {
                                            HStack(alignment: .bottom, spacing: 8) {
                                                Text("\(workoutEngine.repsCompleted)")
                                                    .font(.system(size: 40, weight: .black))
                                                    .foregroundColor(.blue)
                                                
                                                VStack(spacing: 2) {
                                                    Text("OF")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.gray)
                                                    
                                                    Text("\(workoutEngine.targetReps)")
                                                        .font(.system(size: 20, weight: .bold))
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.bottom, 6)
                                            }
                                            
                                            Text("REPS")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.gray)
                                                .tracking(1)
                                            
                                            ProgressView(value: Double(workoutEngine.repsCompleted), total: Double(workoutEngine.targetReps))
                                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                                .scaleEffect(y: 0.5)
                                        }
                                    }
                                }
                            }
                            
                            if let exercise = workoutEngine.currentExercise, !exercise.isTimeBasedExercise {
                                VStack(spacing: 12) {
                                    if workoutEngine.repsCompleted < workoutEngine.targetReps {
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            onRepCompleted()
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 18))
                                                
                                                Text("ADD REP")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .tracking(0.5)
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                Capsule()
                                                    .fill(.blue)
                                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                            )
                                        }
                                    }
                                    
                                    if workoutEngine.repsCompleted >= workoutEngine.targetReps {
                                        Button(action: {
                                            let successFeedback = UINotificationFeedbackGenerator()
                                            successFeedback.notificationOccurred(.success)
                                            onSetComplete()
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18))
                                                
                                                Text("COMPLETE SET")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .tracking(0.5)
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 16)
                                            .background(
                                                Capsule()
                                                    .fill(.green)
                                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                            )
                                        }
                                    }
                                    
                                    Button(action: {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        onSkipCurrentSet()
                                    }) {
                                        Text("Skip This Set")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gray)
                                            .underline()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: -2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Next exercise preview - ENHANCED
                        if let nextExercise = workoutEngine.nextExercise, 
                           workoutEngine.currentExerciseIndex < totalExercises - 1 {
                            HStack(spacing: 12) {
                                // Exercise icon instead of image placeholder
                                Image(systemName: nextExercise.exerciseIcon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .frame(width: 40, height: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Up Next")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                    
                                    Text(nextExercise.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                if !nextExercise.isTimeBasedExercise {
                                    Text("\(nextExercise.sets ?? 1) sets")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.4, green: 0.8, blue: 0.2),
                                                Color(red: 0.3, green: 0.7, blue: 0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .onAppear {
            print("[WorkoutExecution] 🎬 View appeared - starting video load")
            loadExerciseVideo()
        }
        .onChange(of: workoutEngine.currentExercise?.id) { newExerciseId in
            print("[WorkoutExecution] 🔄 Engine exercise changed to: '\(workoutEngine.currentExercise?.name ?? "nil")'")
            loadExerciseVideo()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            print("[WorkoutExecution] 📱 App entered foreground - retrying video load")
            if workoutEngine.currentExercise != nil {
                loadExerciseVideo()
            }
        }
    }
    
    private func loadExerciseVideo() {
        guard let exercise = workoutEngine.currentExercise else {
            print("[WorkoutExecution] ❌ CRITICAL: No workoutEngine.currentExercise to load video for.")
            return
        }
        
        // Prevent re-loading the same video
        if exercise.name == lastExerciseName && videoURL != nil {
            print("[WorkoutExecution] ✅ Video for '\(exercise.name)' is already loaded.")
            return
        }
        
        print("[WorkoutExecution] 🚀 SUCCESS: Starting video load for: '\(exercise.name)'")
        self.lastExerciseName = exercise.name
        isLoadingVideo = true
        isVideoReady = false
        isVideoPlaying = false
        videoURL = nil
        
        Task {
            do {
                print("[WorkoutExecution] 🎯 Attempting video fetch for: '\(exercise.name)'")
                
                let result = try await withTimeout(seconds: 2.0) {
                    return try await ExerciseVideoService.shared.fetchExerciseVideo(for: exercise.name)
                }
                
                await MainActor.run {
                    print("[WorkoutExecution] ✅ Video loaded successfully for '\(exercise.name)': \(result)")
                    self.videoURL = result
                    self.isLoadingVideo = false
                }
                
            } catch {
                print("[WorkoutExecution] ❌ Video loading failed for '\(exercise.name)': \(error)")
                
                await MainActor.run {
                    self.videoURL = nil
                    self.isLoadingVideo = false
                    self.isVideoReady = true  
                    
                    print("[WorkoutExecution] 🏃‍♂️ FALLBACK READY: No video for '\(exercise.name)' - workout can continue")
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatElapsedTime(totalTime: TimeInterval, remaining: TimeInterval) -> String {
        let elapsed = totalTime - remaining
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw VideoLoadingError.timeout
            }
            
            guard let result = try await group.next() else {
                throw VideoLoadingError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Exit Confirmation Overlay Component

struct ExitConfirmationOverlay: View {
    let onContinue: () -> Void
    let onSaveAndExit: () -> Void
    let onExitWithoutSaving: () -> Void
    
    @State private var showAnimation = false
    @State private var backgroundOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(backgroundOpacity)
                .ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.8))
            
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .orange.opacity(0.3),
                                        .orange.opacity(0.1),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(showAnimation ? 1.05 : 1.0)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 45, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    VStack(spacing: 12) {
                        Text("Exit Workout?")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Your progress will be saved\nand you can continue later.")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onContinue()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("CONTINUE WORKOUT")
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.white, .white.opacity(0.9)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onSaveAndExit()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text("SAVE & EXIT")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .tracking(0.5)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.clear)
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white, .white.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            onExitWithoutSaving()
                        }
                    }) {
                        Text("Exit Without Saving")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .underline()
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .white.opacity(0.05),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .scaleEffect(showAnimation ? 1.0 : 0.9)
            .opacity(showAnimation ? 1.0 : 0.0)
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showAnimation = true
                backgroundOpacity = 0.8
            }
        }
    }
}

enum VideoLoadingError: Error {
    case timeout
    case notFound
}