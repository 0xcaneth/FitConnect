import SwiftUI
import AVFoundation

/// Nike-level interactive workout execution experience
/// Real-time workout session with video guidance, timers, and progress tracking
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
            // Background
            Color.black.ignoresSafeArea()
            
            // Main content
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
                ActiveWorkoutView(
                    currentExercise: workoutEngine.currentExercise,
                    currentSet: workoutEngine.currentSet,
                    totalSets: workoutEngine.totalSets,
                    timeRemaining: workoutEngine.exerciseTimeRemaining,
                    repsCompleted: workoutEngine.repsCompleted,
                    targetReps: workoutEngine.targetReps,
                    exerciseIndex: workoutEngine.currentExerciseIndex,
                    totalExercises: workout.exercises.count,
                    motivationMessage: motivationEngine.getExerciseMotivation(
                        exercise: workoutEngine.currentExercise
                    ),
                    onSetComplete: {
                        handleSetCompletion()
                    },
                    onRepCompleted: {
                        workoutEngine.incrementRep()
                    },
                    onNextExercise: {
                        handleExerciseCompletion()
                    },
                    onPauseWorkout: {
                        workoutEngine.pauseWorkout()
                    },
                    onResumeWorkout: {
                        workoutEngine.resumeWorkout()
                    }
                )
            }
            
            // Top overlay with progress and exit
            VStack {
                topControlsOverlay
                Spacer()
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
    
    // MARK: - Top Controls Overlay
    
    @ViewBuilder
    private var topControlsOverlay: some View {
        HStack {
            // Exit button
            Button(action: {
                workoutEngine.pauseWorkout()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showExitConfirmation = true
                }
            }) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Workout progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("Exercise \(workoutEngine.currentExerciseIndex + 1) of \(workout.exercises.count)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(
                                width: geometry.size.width * workoutEngine.overallProgress,
                                height: 4
                            )
                            .animation(.easeOut(duration: 0.3), value: workoutEngine.overallProgress)
                    }
                }
                .frame(width: 120, height: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60) // Account for status bar
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

// MARK: - Active Workout View

@available(iOS 16.0, *)
struct ActiveWorkoutView: View {
    let currentExercise: WorkoutExercise?
    let currentSet: Int
    let totalSets: Int
    let timeRemaining: TimeInterval
    let repsCompleted: Int
    let targetReps: Int
    let exerciseIndex: Int
    let totalExercises: Int
    let motivationMessage: String
    
    let onSetComplete: () -> Void
    let onRepCompleted: () -> Void
    let onNextExercise: () -> Void
    let onPauseWorkout: () -> Void
    let onResumeWorkout: () -> Void
    
    @State private var isPaused = false
    @State private var showInstructions = false
    @State private var animateReps = false
    
    var body: some View {
        ZStack {
            // Full-screen auto-looping video background
            if let exercise = currentExercise {
                AutoLoopingVideoPlayerView(
                    exercise: exercise,
                    isPlaying: !isPaused
                )
                .ignoresSafeArea(.all)
                .clipShape(Rectangle())
            }
            
            // Clean gradient overlay for readability
            LinearGradient(
                colors: [
                    .clear,
                    .clear,
                    .black.opacity(0.4),
                    .black.opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            // Main content with Nike-level design
            VStack(spacing: 0) {
                Spacer()
                
                // Bottom content panel - Crystal clear design
                VStack(spacing: 32) {
                    // Exercise name - Nike style typography
                    VStack(spacing: 16) {
                        Text(currentExercise?.name ?? "High Knees")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        // Clean motivation message
                        Text(motivationMessage.isEmpty ? "Keep that energy flowing! " : motivationMessage)
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                    
                    // Instructions toggle - Minimalist design
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showInstructions.toggle()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showInstructions ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .bold))
                            
                            Text("Instructions")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.3))
                                .overlay(
                                    Capsule()
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Clean instructions panel
                    if showInstructions, let instructions = currentExercise?.instructions {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(.white.opacity(0.2))
                                        )
                                    
                                    Text(instruction)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.95))
                                        .multilineTextAlignment(.leading)
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.black.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                    
                    // Set/Rep counter or timer - Nike-inspired design
                    if let exercise = currentExercise {
                        if exercise.isTimeBasedExercise {
                            NikeStyleTimeCounter(
                                timeRemaining: timeRemaining,
                                onComplete: onNextExercise
                            )
                        } else {
                            NikeStyleSetsRepsCounter(
                                currentSet: currentSet,
                                totalSets: totalSets,
                                repsCompleted: repsCompleted,
                                targetReps: targetReps,
                                onRepCompleted: onRepCompleted,
                                onSetComplete: onSetComplete
                            )
                        }
                    }
                    
                    // Clean control buttons - Nike style
                    HStack(spacing: 24) {
                        // Pause/Resume button
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPaused.toggle()
                            }
                            
                            if isPaused {
                                onPauseWorkout()
                            } else {
                                onResumeWorkout()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(.black.opacity(0.8))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Nike-Style Sets/Reps Counter

struct NikeStyleSetsRepsCounter: View {
    let currentSet: Int
    let totalSets: Int
    let repsCompleted: Int
    let targetReps: Int
    let onRepCompleted: () -> Void
    let onSetComplete: () -> Void
    
    @State private var animateReps = false
    
    var body: some View {
        VStack(spacing: 28) {
            // Set progress - Clean Nike style
            HStack(alignment: .bottom, spacing: 16) {
                VStack(spacing: 8) {
                    Text("SET")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(currentSet)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("OF")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
                
                VStack(spacing: 8) {
                    Text("TOTAL")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(totalSets)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Rep counter - Clean and bold
            VStack(spacing: 20) {
                // Large rep display
                HStack(alignment: .bottom, spacing: 12) {
                    Text("\(repsCompleted)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(animateReps ? 1.05 : 1.0)
                        .onChange(of: repsCompleted) { _ in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                animateReps = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                animateReps = false
                            }
                        }
                    
                    VStack(spacing: 4) {
                        Text("OF")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1)
                        
                        Text("\(targetReps)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 8)
                }
                
                Text("REPS")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
                
                // Clean progress indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.white)
                            .frame(
                                width: geometry.size.width * min(1.0, Double(repsCompleted) / Double(targetReps)),
                                height: 6
                            )
                            .animation(.easeOut(duration: 0.3), value: repsCompleted)
                    }
                }
                .frame(height: 6)
                .frame(maxWidth: 240)
            }
            
            // Action buttons - Nike inspired
            VStack(spacing: 16) {
                // +1 Rep button - Primary action
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    onRepCompleted()
                }) {
                    Text("+1 REP")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.black)
                        .tracking(1)
                        .frame(width: 200, height: 56)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                }
                .disabled(repsCompleted >= targetReps)
                .opacity(repsCompleted >= targetReps ? 0.5 : 1.0)
                
                // Complete Set button - Success action
                if repsCompleted >= targetReps {
                    Button(action: {
                        let successFeedback = UINotificationFeedbackGenerator()
                        successFeedback.notificationOccurred(.success)
                        onSetComplete()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("COMPLETE SET")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.black)
                        .frame(width: 200, height: 56)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.0, green: 1.0, blue: 0.533333333333333))
                        )
                        .shadow(color: Color(red: 0.0, green: 1.0, blue: 0.533333333333333).opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Nike-Style Time Counter

struct NikeStyleTimeCounter: View {
    let timeRemaining: TimeInterval
    let onComplete: () -> Void
    
    @State private var animateTimer = false
    
    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("TIME REMAINING")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2)
            
            ZStack {
                // Background circle - Clean design
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 220, height: 220)
                
                // Progress circle - Nike style
                Circle()
                    .trim(from: 0.0, to: min(1.0, 1.0 - (timeRemaining / 60.0)))
                    .stroke(.white, lineWidth: 8)
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeRemaining)
                
                // Time display - Bold and clear
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .scaleEffect(animateTimer ? 1.02 : 1.0)
                    
                    Text("REMAINING")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                }
            }
            .onChange(of: Int(timeRemaining)) { _ in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    animateTimer = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateTimer = false
                }
                
                if timeRemaining <= 0 {
                    onComplete()
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Auto-Looping Video Player

struct AutoLoopingVideoPlayerView: View {
    let exercise: WorkoutExercise
    let isPlaying: Bool
    
    @StateObject private var videoManager = VideoLoopManager()
    
    var body: some View {
        GeometryReader { geometry in
            if let videoURL = exercise.videoURL, !videoURL.isEmpty {
                EnhancedVideoPlayerView(
                    url: videoURL,
                    isPlaying: isPlaying,
                    shouldLoop: true,
                    exerciseDuration: exercise.duration ?? 30, // Exercise duration in seconds
                    videoManager: videoManager
                )
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(
                    // Subtle video overlay for better text readability
                    LinearGradient(
                        colors: [
                            .clear,
                            .clear,
                            .black.opacity(0.1),
                            .black.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            } else {
                // Enhanced fallback demonstration
                ExerciseDemonstrationView(exercise: exercise)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear {
            if let videoURL = exercise.videoURL {
                videoManager.setupVideo(url: videoURL, exerciseDuration: exercise.duration ?? 30)
            }
        }
        .onDisappear {
            videoManager.stopVideo()
        }
    }
}

// MARK: - Enhanced Video Loop Manager

class VideoLoopManager: ObservableObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var exerciseDuration: TimeInterval = 30
    private var videoDuration: TimeInterval = 0
    private var loopTimer: Timer?
    
    func setupVideo(url: String, exerciseDuration: TimeInterval = 30) {
        guard let videoURL = URL(string: url) else { return }
        
        self.exerciseDuration = exerciseDuration
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Get video duration
        playerItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let duration = self.playerItem?.asset.duration ?? CMTime.zero
                self.videoDuration = CMTimeGetSeconds(duration)
                self.setupIntelligentLooping()
            }
        }
        
        player?.play()
    }
    
    private func setupIntelligentLooping() {
        // INTELLIGENT AUTO-LOOP: Match exercise duration
        if videoDuration > 0 && videoDuration < exerciseDuration {
            // Video is shorter than exercise - loop multiple times
            let loopsNeeded = Int(ceil(exerciseDuration / videoDuration))
            print("[VideoManager] 🔄 Video (\(Int(videoDuration))s) will loop \(loopsNeeded) times for exercise (\(Int(exerciseDuration))s)")
            
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        } else {
            // Video is longer or equal - play once and loop if needed
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { [weak self] _ in
                self?.player?.seek(to: .zero)
                self?.player?.play()
            }
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func stopVideo() {
        player?.pause()
        player = nil
        playerItem = nil
        loopTimer?.invalidate()
        loopTimer = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}

// MARK: - Enhanced Video Player View

struct EnhancedVideoPlayerView: UIViewRepresentable {
    let url: String
    let isPlaying: Bool
    let shouldLoop: Bool
    let exerciseDuration: TimeInterval
    let videoManager: VideoLoopManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        guard let videoURL = URL(string: url) else { return view }
        
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        
        // Enhanced video display
        playerLayer.frame = view.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.cornerRadius = 0 // Full screen
        view.layer.addSublayer(playerLayer)
        
        // Setup intelligent looping
        if shouldLoop {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                player.seek(to: .zero)
                if self.isPlaying {
                    player.play()
                }
            }
        }
        
        if isPlaying {
            player.play()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Auto-layout for full screen
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
            
            if isPlaying {
                playerLayer.player?.play()
            } else {
                playerLayer.player?.pause()
            }
        }
    }
}

// MARK: - Video Loop Manager

class VideoLoopManagerOld: ObservableObject {
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    
    func setupVideo(url: String) {
        guard let videoURL = URL(string: url) else { return }
        
        playerItem = AVPlayerItem(url: videoURL)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup seamless looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
        
        player?.play()
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func stopVideo() {
        player?.pause()
        player = nil
        playerItem = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
}

// MARK: - Exercise Demonstration Fallback

struct ExerciseDemonstrationView: View {
    let exercise: WorkoutExercise
    
    var body: some View {
        ZStack {
            // High-quality gradient background
            LinearGradient(
                colors: [
                    Color(red: 255/255, green: 107/255, blue: 107/255),
                    Color(red: 78/255, green: 205/255, blue: 196/255),
                    Color(red: 69/255, green: 183/255, blue: 209/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Exercise icon with animation
            VStack(spacing: 20) {
                Image(systemName: exercise.exerciseIcon ?? "figure.strengthtraining.traditional")
                    .font(.system(size: 120, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Text("Follow the instructions")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Rest Period View

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
            // Rest background
            LinearGradient(
                colors: [
                    Color(red: 0.10196078431372549, green: 0.1568627450980392, blue: 0.4980392156862745).opacity(0.8),
                    Color(red: 0.06666666666666667, green: 0.23529411764705883, blue: 0.6274509803921569).opacity(0.9),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Rest indicator
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0.3 : 0.8)
                        
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            pulseAnimation = true
                        }
                    }
                    
                    Text("REST TIME")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Timer
                VStack(spacing: 12) {
                    Text(formattedTime)
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("seconds remaining")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Motivation message
                if !motivationMessage.isEmpty {
                    Text(motivationMessage)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Next exercise preview
                if let nextExercise = nextExercise {
                    VStack(spacing: 12) {
                        Text("UP NEXT")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(nextExercise.name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                // Skip rest button
                Button(action: onSkipRest) {
                    Text("SKIP REST")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(.white)
                        )
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onChange(of: timeRemaining) { remaining in
            if remaining <= 0 {
                onRestComplete()
            }
        }
    }
}

// MARK: - Exit Confirmation Overlay

struct ExitConfirmationOverlay: View {
    let onContinue: () -> Void
    let onSaveAndExit: () -> Void
    let onExitWithoutSaving: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.orange)
                    
                    Text("Exit Workout?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your progress will be saved and you can continue later.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("CONTINUE WORKOUT")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(.white)
                            )
                    }
                    
                    Button(action: onSaveAndExit) {
                        Text("SAVE & EXIT")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }
                    
                    Button(action: onExitWithoutSaving) {
                        Text("Exit Without Saving")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 40)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct WorkoutExecutionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample workout for preview only
        let sampleWorkout = WorkoutSession(
            userId: "preview-user",
            workoutType: .strength,
            name: "Strength Training",
            description: "Sample workout for preview",
            estimatedDuration: 1800,
            estimatedCalories: 300,
            difficulty: .intermediate,
            targetMuscleGroups: [.chest, .arms],
            exercises: [
                WorkoutExercise(
                    name: "Push-ups",
                    exerciseType: .strength,
                    targetMuscleGroups: [.chest, .arms],
                    sets: 3,
                    reps: 10,
                    instructions: ["Start in plank", "Lower chest", "Push up"],
                    exerciseIcon: "figure.strengthtraining.traditional"
                )
            ]
        )
        
        WorkoutExecutionView(
            workout: sampleWorkout,
            onWorkoutComplete: { _ in },
            onDismiss: { }
        )
    }
}
#endif