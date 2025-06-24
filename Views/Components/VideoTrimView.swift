import SwiftUI
import AVFoundation
import AVKit

struct VideoTrimView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VideoTrimViewModel
    
    let onVideoTrimmed: (URL) -> Void
    
    init(videoURL: URL, onVideoTrimmed: @escaping (URL) -> Void) {
        self._viewModel = StateObject(wrappedValue: VideoTrimViewModel(videoURL: videoURL))
        self.onVideoTrimmed = onVideoTrimmed
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Video player
                    if let player = viewModel.player {
                        VideoPlayer(player: player)
                            .frame(height: 300)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Trim controls
                    VStack(spacing: 16) {
                        Text("Trim Video")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(FitConnectColors.textPrimary)
                        
                        // Timeline scrubber
                        VStack(spacing: 8) {
                            // Timeline
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background track
                                    Rectangle()
                                        .fill(FitConnectColors.textTertiary.opacity(0.3))
                                        .frame(height: 4)
                                    
                                    // Selected range
                                    Rectangle()
                                        .fill(FitConnectColors.accentPurple)
                                        .frame(
                                            width: geometry.size.width * (viewModel.endTime - viewModel.startTime) / viewModel.duration,
                                            height: 4
                                        )
                                        .offset(x: geometry.size.width * viewModel.startTime / viewModel.duration)
                                }
                                .overlay(
                                    // Start handle
                                    Circle()
                                        .fill(FitConnectColors.accentPurple)
                                        .frame(width: 20, height: 20)
                                        .offset(x: geometry.size.width * viewModel.startTime / viewModel.duration - 10)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    let newTime = max(0, min(viewModel.endTime - 1, value.location.x / geometry.size.width * viewModel.duration))
                                                    viewModel.startTime = newTime
                                                    viewModel.updatePreview()
                                                }
                                        )
                                )
                                .overlay(
                                    // End handle
                                    Circle()
                                        .fill(FitConnectColors.accentPurple)
                                        .frame(width: 20, height: 20)
                                        .offset(x: geometry.size.width * viewModel.endTime / viewModel.duration - 10)
                                        .gesture(
                                            DragGesture()
                                                .onChanged { value in
                                                    let newTime = max(viewModel.startTime + 1, min(viewModel.duration, value.location.x / geometry.size.width * viewModel.duration))
                                                    viewModel.endTime = newTime
                                                    viewModel.updatePreview()
                                                }
                                        )
                                )
                            }
                            .frame(height: 20)
                            .padding(.horizontal)
                            
                            // Time labels
                            HStack {
                                Text(viewModel.formatTime(viewModel.startTime))
                                    .font(.caption)
                                    .foregroundColor(FitConnectColors.textSecondary)
                                
                                Spacer()
                                
                                Text("Duration: \(viewModel.formatTime(viewModel.endTime - viewModel.startTime))")
                                    .font(.caption)
                                    .foregroundColor(FitConnectColors.textPrimary)
                                
                                Spacer()
                                
                                Text(viewModel.formatTime(viewModel.endTime))
                                    .font(.caption)
                                    .foregroundColor(FitConnectColors.textSecondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    .background(FitConnectColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(FitConnectColors.cardBackground)
                        .cornerRadius(25)
                        
                        Button("Confirm") {
                            Task {
                                await viewModel.trimVideo()
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(FitConnectColors.accentPurple)
                        .cornerRadius(25)
                        .disabled(viewModel.isProcessing)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.setupPlayer()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Trimming Complete", isPresented: $viewModel.showTrimComplete) {
                Button("Use Video") {
                    if let trimmedURL = viewModel.trimmedVideoURL {
                        onVideoTrimmed(trimmedURL)
                        dismiss()
                    }
                }
            } message: {
                Text("Your video has been trimmed successfully!")
            }
        }
    }
}

// MARK: - Video Trim ViewModel

class VideoTrimViewModel: ObservableObject {
    @Published var startTime: Double = 0
    @Published var endTime: Double = 0
    @Published var duration: Double = 0
    @Published var isProcessing = false
    @Published var showError = false
    @Published var showTrimComplete = false
    @Published var errorMessage = ""
    @Published var trimmedVideoURL: URL?
    
    let videoURL: URL
    var player: AVPlayer?
    private var asset: AVAsset?
    
    init(videoURL: URL) {
        self.videoURL = videoURL
    }
    
    func setupPlayer() {
        asset = AVAsset(url: videoURL)
        player = AVPlayer(url: videoURL)
        
        Task {
            if let asset = asset {
                let duration = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(duration)
                
                await MainActor.run {
                    self.duration = durationSeconds
                    self.endTime = durationSeconds
                }
            }
        }
    }
    
    func updatePreview() {
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        player?.seek(to: startCMTime)
    }
    
    func trimVideo() async {
        guard let asset = asset else {
            await MainActor.run {
                showError(message: "Video asset not available.")
            }
            return
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("trimmed_\(UUID().uuidString).mp4")
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            await MainActor.run {
                isProcessing = false
                showError(message: "Could not create export session.")
            }
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        let startCMTime = CMTime(seconds: startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: endTime, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
        exportSession.timeRange = timeRange
        
        await exportSession.export()
        
        await MainActor.run {
            isProcessing = false
            
            if exportSession.status == .completed {
                trimmedVideoURL = outputURL
                showTrimComplete = true
            } else {
                showError(message: exportSession.error?.localizedDescription ?? "Video trimming failed.")
            }
        }
    }
    
    func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
