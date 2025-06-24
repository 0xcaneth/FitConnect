import SwiftUI
import AVFoundation
import Combine

struct VideoRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoRecorderViewModel()
    
    let onVideoRecorded: (URL) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Camera preview
                CameraPreviewView(session: viewModel.captureSession)
                    .ignoresSafeArea()
                
                // UI Overlay
                VStack {
                    // Top bar with timer and close button
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Timer
                        if viewModel.isRecording {
                            Text(viewModel.formattedTime)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(20)
                                .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        // Placeholder for symmetry
                        Color.clear.frame(width: 44, height: 44)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 24) {
                        // Recording progress
                        if viewModel.isRecording {
                            ProgressView(value: viewModel.recordingProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Record button
                        Button {
                            if viewModel.isRecording {
                                viewModel.stopRecording()
                            } else {
                                viewModel.startRecording()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                
                                if viewModel.isRecording {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                        .frame(width: 28, height: 28)
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                }
                            }
                            .scaleEffect(viewModel.isRecording ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.isRecording)
                        }
                        .disabled(viewModel.isProcessing)
                        
                        // Instructions
                        Text(viewModel.isRecording ? "Tap to stop recording" : "Tap to start recording")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.setupCamera()
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Recording Complete", isPresented: $viewModel.showRecordingComplete) {
                Button("Use Video") {
                    if let videoURL = viewModel.recordedVideoURL {
                        onVideoRecorded(videoURL)
                        dismiss()
                    }
                }
                Button("Record Again") {
                    viewModel.resetRecording()
                }
            } message: {
                Text("Your workout video has been recorded successfully!")
            }
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Video Recorder ViewModel

class VideoRecorderViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recordingProgress: Double = 0.0
    @Published var recordingTime: TimeInterval = 0
    @Published var showError = false
    @Published var showRecordingComplete = false
    @Published var errorMessage = ""
    @Published var recordedVideoURL: URL?
    
    let captureSession = AVCaptureSession()
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var recordingTimer: Timer?
    private let maxRecordingTime: TimeInterval = 60.0
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    override init() {
        super.init()
    }
    
    func setupCamera() {
        Task {
            await requestPermissions()
            await setupCaptureSession()
        }
    }
    
    @MainActor
    private func requestPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if cameraStatus != .authorized {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted {
                showError(message: "Camera access is required to record workout videos.")
                return
            }
        }
        
        if microphoneStatus != .authorized {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted {
                showError(message: "Microphone access is required to record workout videos with audio.")
                return
            }
        }
    }
    
    private func setupCaptureSession() async {
        captureSession.sessionPreset = .high
        
        // Video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video) else {
            await MainActor.run {
                showError(message: "Unable to access camera.")
            }
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
        } catch {
            await MainActor.run {
                showError(message: "Unable to add video input: \(error.localizedDescription)")
            }
            return
        }
        
        // Audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            await MainActor.run {
                showError(message: "Unable to access microphone.")
            }
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
        } catch {
            await MainActor.run {
                showError(message: "Unable to add audio input: \(error.localizedDescription)")
            }
            return
        }
        
        // Movie file output
        let movieFileOutput = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
            self.movieFileOutput = movieFileOutput
        }
        
        // Start session
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func startRecording() {
        guard let movieFileOutput = movieFileOutput else {
            showError(message: "Movie file output not available.")
            return
        }
        
        let outputFileName = "\(UUID().uuidString).mov"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFileName)
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordingTime = 0
        recordingProgress = 0
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                self.recordingTime += 0.1
                self.recordingProgress = self.recordingTime / self.maxRecordingTime
                
                // Auto-stop at max time
                if self.recordingTime >= self.maxRecordingTime {
                    self.stopRecording()
                }
            }
        }
    }
    
    func stopRecording() {
        movieFileOutput?.stopRecording()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isProcessing = true
    }
    
    func resetRecording() {
        recordedVideoURL = nil
        recordingTime = 0
        recordingProgress = 0
        showRecordingComplete = false
    }
    
    func cleanup() {
        captureSession.stopRunning()
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension VideoRecorderViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isProcessing = false
            
            if let error = error {
                self.showError(message: "Recording failed: \(error.localizedDescription)")
                return
            }
            
            self.recordedVideoURL = outputFileURL
            self.showRecordingComplete = true
        }
    }
}
