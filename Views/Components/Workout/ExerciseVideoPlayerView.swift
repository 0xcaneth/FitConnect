import SwiftUI
import AVFoundation
import AVKit

/// Video player for exercise demonstrations during workout
struct ExerciseVideoPlayerView: View {
    let exercise: WorkoutExercise
    let isPlaying: Bool
    
    @State private var player: AVPlayer?
    @State private var showVideoControls = false
    @State private var videoError = false
    
    var body: some View {
        ZStack {
            // Fallback gradient background
            LinearGradient(
                colors: [
                    Color(hex: exercise.exerciseType.primaryColor).opacity(0.6),
                    Color(hex: exercise.exerciseType.secondaryColor).opacity(0.8),
                    .black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let player = player, !videoError {
                CustomVideoPlayer(player: player)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showVideoControls.toggle()
                        }
                    }
            } else {
                // Fallback exercise visualization
                ExerciseFallbackView(exercise: exercise)
            }
            
            // Video controls overlay
            if showVideoControls {
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            player?.seek(to: .zero)
                        }) {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if player?.rate == 0 {
                                player?.play()
                            } else {
                                player?.pause()
                            }
                        }) {
                            Image(systemName: (player?.rate == 0) ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 50, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onAppear {
            setupVideoPlayer()
        }
        .onDisappear {
            player?.pause()
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onTapGesture {
            // Hide controls after delay
            if showVideoControls {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showVideoControls = false
                    }
                }
            }
        }
    }
    
    private func setupVideoPlayer() {
        // Try to load exercise video
        if let videoURL = exercise.videoURL {
            guard let url = URL(string: videoURL) else {
                videoError = true
                return
            }
            
            player = AVPlayer(url: url)
            
            // Loop the video
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                player?.seek(to: .zero)
                if self.isPlaying {
                    player?.play()
                }
            }
            
            // Handle errors
            player?.currentItem?.addObserver(
                self as! NSObject,
                forKeyPath: "status",
                options: .new,
                context: nil
            )
            
        } else {
            // Use fallback visualization
            videoError = true
        }
    }
}

// MARK: - Exercise Fallback View (when no video available)

struct ExerciseFallbackView: View {
    let exercise: WorkoutExercise
    
    @State private var animateIcon = false
    @State private var animateGlow = false
    
    var body: some View {
        ZStack {
            // Animated background
            ForEach(0..<3) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: exercise.exerciseType.primaryColor).opacity(0.3),
                                Color(hex: exercise.exerciseType.primaryColor).opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .frame(width: 300 + CGFloat(index * 50), height: 300 + CGFloat(index * 50))
                    .scaleEffect(animateGlow ? 1.2 : 1.0)
                    .opacity(animateGlow ? 0.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 2.0 + Double(index) * 0.5)
                        .repeatForever(autoreverses: true),
                        value: animateGlow
                    )
            }
            
            VStack(spacing: 24) {
                // Exercise icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: exercise.exerciseType.primaryColor),
                                    Color(hex: exercise.exerciseType.secondaryColor)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateIcon ? 1.05 : 1.0)
                    
                    Image(systemName: exercise.exerciseIcon)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(animateIcon ? 1.1 : 1.0)
                }
                
                VStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(exercise.exerciseType.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if let description = exercise.description {
                        Text(description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .lineLimit(3)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateIcon = true
                animateGlow = true
            }
        }
    }
}

// MARK: - Custom Video Player Wrapper (Fixed naming conflict)

struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Updates handled by player state
    }
}