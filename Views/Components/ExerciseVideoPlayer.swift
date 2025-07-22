import SwiftUI
import AVFoundation
import AVKit

/// Premium exercise video player with Apple-style design
struct ExerciseVideoPlayer: View {
    let videoURL: URL?
    let isPlaying: Bool
    let showControls: Bool
    
    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    @State private var showError = false
    
    init(videoURL: URL?, isPlaying: Bool = true, showControls: Bool = true) {
        self.videoURL = videoURL
        self.isPlaying = isPlaying
        self.showControls = showControls
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with Firebase Storage branding
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if let videoURL = videoURL {
                    // Use VideoPlayer from AVKit - much more reliable
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                        .onAppear {
                            setupPlayer(with: videoURL)
                        }
                        .onDisappear {
                            cleanupPlayer()
                        }
                    
                    // Loading state
                    if !isVideoReady {
                        ZStack {
                            Color(.systemBackground).opacity(0.9)
                            
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(.blue)
                                
                                Text("Loading exercise video...")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Error state
                    if showError {
                        ZStack {
                            Color(.systemBackground).opacity(0.95)
                            
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.orange)
                                
                                VStack(spacing: 8) {
                                    Text("Video Error")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text("Unable to load exercise video")
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                Button("Retry") {
                                    setupPlayer(with: videoURL)
                                }
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                            }
                            .padding(20)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Firebase Storage badge
                    VStack {
                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "icloud.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("Firebase")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                
                } else {
                    // No video fallback
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle")
                            .font(.system(size: 60, weight: .thin))
                            .foregroundColor(.white.opacity(0.8))
                        
                        VStack(spacing: 8) {
                            Text("No Video Available")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Exercise instructions below")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer(with url: URL) {
        showError = false
        isVideoReady = false
        
        let newPlayer = AVPlayer(url: url)
        
        // Monitor player status
        Task {
            do {
                // Wait for player to be ready
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                await MainActor.run {
                    self.player = newPlayer
                    self.isVideoReady = true
                    
                    if isPlaying {
                        newPlayer.play()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError = true
                    self.isVideoReady = false
                }
            }
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        isVideoReady = false
    }
}