import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

@available(iOS 16.0, *)
struct LiveCameraScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = LiveCameraScanViewModel()
    
    let onFoodDetected: (UIImage, FoodPrediction) -> Void
    let onDismiss: () -> Void
    
    @State private var showingPermissionAlert = false
    @State private var showingSettingsAlert = false
    @State private var captureButtonScale = 1.0
    @State private var scanFrameAnimation = false
    @State private var overlayOpacity = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isAuthorized {
                // Live camera preview
                LiveCameraPreview(session: viewModel.captureSession)
                    .ignoresSafeArea()
                
                // Camera overlay UI
                cameraOverlayView
                
            } else {
                permissionRequestView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.checkPermissions()
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
            Button("Allow") {
                Task {
                    await viewModel.requestPermissions()
                }
            }
            Button("Cancel") {
                onDismiss()
            }
        } message: {
            Text("FitConnect needs camera access to scan your meals. Please allow camera permission to continue.")
        }
        .alert("Camera Access Denied", isPresented: $showingSettingsAlert) {
            Button("Open Settings") {
                openSettings()
            }
            Button("Cancel") {
                onDismiss()
            }
        } message: {
            Text("Camera access is permanently denied. Please go to Settings > FitConnect > Camera to enable camera access.")
        }
        .alert("Analysis Error", isPresented: $viewModel.showError) {
            Button("Retry") {
                viewModel.retryCapture()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.permissionStatus) { status in
            handlePermissionChange(status)
        }
        .onChange(of: viewModel.capturedResult) { result in
            if let result = result {
                onFoodDetected(result.image, result.prediction)
            }
        }
    }
    
    // MARK: - Camera Overlay View
    private var cameraOverlayView: some View {
        VStack(spacing: 0) {
            topBarView
            Spacer()
            centerScanningFrame
            Spacer()
            bottomControlsView
        }
        .opacity(overlayOpacity)
        .animation(.easeInOut(duration: 0.3), value: overlayOpacity)
    }
    
    // MARK: - Top Bar
    private var topBarView: some View {
        HStack {
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("Scan Meal")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                if viewModel.isAnalyzing {
                    Text("Analyzing...")
                        .font(.caption)
                        .foregroundColor(FitConnectColors.accentCyan)
                        .transition(.opacity)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.toggleFlash()
            } label: {
                Image(systemName: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(viewModel.isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Center Scanning Frame
    private var centerScanningFrame: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            FitConnectColors.accentCyan.opacity(scanFrameAnimation ? 1.0 : 0.6),
                            FitConnectColors.accentPurple.opacity(scanFrameAnimation ? 0.8 : 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 280, height: 280)
                .scaleEffect(scanFrameAnimation ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: scanFrameAnimation)
            
            cornerOverlays
            
            VStack(spacing: 12) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                
                Text("Position food within frame")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                
                if viewModel.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .opacity(viewModel.isAnalyzing ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isAnalyzing)
        }
        .onAppear {
            scanFrameAnimation = true
        }
    }
    
    // MARK: - Corner Overlays
    private var cornerOverlays: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                let isTop = index < 2
                let isLeft = index % 2 == 0
                
                VStack {
                    if isTop {
                        HStack {
                            if isLeft {
                                VStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 20, height: 3)
                                    Spacer()
                                }
                                .frame(height: 20)
                                Spacer()
                            } else {
                                Spacer()
                                VStack(spacing: 0) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 20, height: 3)
                                    Spacer()
                                }
                                .frame(height: 20)
                            }
                        }
                        
                        HStack {
                            if isLeft {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 3, height: 20)
                                Spacer()
                            } else {
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 3, height: 20)
                            }
                        }
                        Spacer()
                    } else {
                        Spacer()
                        HStack {
                            if isLeft {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 3, height: 20)
                                Spacer()
                            } else {
                                Spacer()
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 3, height: 20)
                            }
                        }
                        
                        HStack {
                            if isLeft {
                                VStack(spacing: 0) {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 20, height: 3)
                                }
                                .frame(height: 20)
                                Spacer()
                            } else {
                                Spacer()
                                VStack(spacing: 0) {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.9))
                                        .frame(width: 20, height: 3)
                                }
                                .frame(height: 20)
                            }
                        }
                    }
                }
                .frame(width: 280, height: 280)
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 24) {
            Button {
                capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Circle()
                        .stroke(Color.black.opacity(0.1), lineWidth: 2)
                        .frame(width: 72, height: 72)
                    
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
                .scaleEffect(captureButtonScale)
                .animation(.easeInOut(duration: 0.1), value: captureButtonScale)
            }
            .disabled(viewModel.isAnalyzing)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        captureButtonScale = 0.95
                    }
                    .onEnded { _ in
                        captureButtonScale = 1.0
                    }
            )
            
            Text(viewModel.isAnalyzing ? "Processing image..." : "Tap to capture and analyze")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Permission Request View
    private var permissionRequestView: some View {
        VStack(spacing: 32) {
            Image(systemName: "camera.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(FitConnectColors.accentCyan)
                .shadow(color: FitConnectColors.accentCyan.opacity(0.3), radius: 8, x: 0, y: 4)
            
            VStack(spacing: 16) {
                Text("Camera Access Required")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("FitConnect needs camera access to scan and analyze your meals with AI-powered food recognition.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            VStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.requestPermissions()
                    }
                } label: {
                    Text("Allow Camera Access")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: FitConnectColors.accentCyan.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                
                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FitConnectColors.backgroundDark)
    }
    
    // MARK: - Methods
    private func capturePhoto() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.1)) {
            overlayOpacity = 0.3
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                overlayOpacity = 1.0
            }
        }
        
        viewModel.capturePhoto()
    }
    
    private func handlePermissionChange(_ status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined:
            showingPermissionAlert = true
        case .denied, .restricted:
            showingSettingsAlert = true
        case .authorized:
            Task {
                await viewModel.startSession()
            }
        @unknown default:
            break
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - Live Camera Preview
struct LiveCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                layer.frame = uiView.bounds
            }
        }
    }
}

// MARK: - Live Camera Scan ViewModel
@MainActor
class LiveCameraScanViewModel: ObservableObject {
    @Published var isAuthorized = false
    @Published var isAnalyzing = false
    @Published var isFlashOn = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var capturedResult: CapturedResult?
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?
    private let coreMLClassifier = CoreMLFoodClassifier()
    
    struct CapturedResult: Equatable {
        let image: UIImage
        let prediction: FoodPrediction
        
        static func == (lhs: CapturedResult, rhs: CapturedResult) -> Bool {
            return lhs.prediction.label == rhs.prediction.label &&
                   lhs.prediction.confidence == rhs.prediction.confidence &&
                   lhs.prediction.calories == rhs.prediction.calories
        }
    }
    
    func checkPermissions() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permissionStatus = status
        isAuthorized = status == .authorized
        
        if isAuthorized {
            await startSession()
        }
    }
    
    func requestPermissions() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        permissionStatus = granted ? .authorized : .denied
        isAuthorized = granted
        
        if granted {
            await startSession()
        }
    }
    
    func startSession() async {
        guard !captureSession.isRunning else { return }
        
        captureSession.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showError(message: "Unable to access camera device")
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let photoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
            
        } catch {
            showError(message: "Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func toggleFlash() {
        guard let device = currentDevice, device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if device.torchMode == .off {
                try device.setTorchModeOn(level: 1.0)
                isFlashOn = true
            } else {
                device.torchMode = .off
                isFlashOn = false
            }
            device.unlockForConfiguration()
        } catch {
            print("Error toggling flash: \(error)")
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else {
            showError(message: "Photo output not available")
            return
        }
        
        isAnalyzing = true
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off
        
        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { [weak self] result in
            Task { @MainActor in
                await self?.handleCapturedPhoto(result)
            }
        })
    }
    
    func retryCapture() {
        capturedResult = nil
        isAnalyzing = false
        showError = false
    }
    
    private func handleCapturedPhoto(_ result: Result<UIImage, Error>) async {
        switch result {
        case .success(let image):
            await classifyImage(image)
        case .failure(let error):
            isAnalyzing = false
            showError(message: "Failed to capture photo: \(error.localizedDescription)")
        }
    }
    
    private func classifyImage(_ image: UIImage) async {
        print("📱 Live camera: Starting classification...")
        
        let result = await withCheckedContinuation { continuation in
            coreMLClassifier.classifyFood(image: image) { result in
                continuation.resume(returning: result)
            }
        }
        
        switch result {
        case .success(let prediction):
            print("📱 Live camera: Classification successful - \(prediction.label) with \(String(format: "%.0f%%", prediction.confidence * 100)) confidence")
            
            if prediction.confidence < 0.3 {
                isAnalyzing = false
                showError(message: "Unable to identify food with confidence. Please try again with better lighting or a clearer view of the food.")
                
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
                return
            }
            
            capturedResult = CapturedResult(image: image, prediction: prediction)
            isAnalyzing = false
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            print("📱 Live camera: Food detected successfully - \(prediction.label)")
            
        case .failure(let error):
            print("📱 Live camera: Classification failed - \(error.localizedDescription)")
            
            isAnalyzing = false
            
            switch error {
            case ClassificationError.lowConfidence:
                showError(message: "Unable to identify food with confidence. Please try again with better lighting or position the food more clearly in the frame.")
            case ClassificationError.noResults:
                showError(message: "No food detected in image. Please ensure food is clearly visible and well-lit.")
            case ClassificationError.invalidImage:
                showError(message: "Invalid image. Please try taking another photo.")
            case ClassificationError.modelNotLoaded:
                showError(message: "Food recognition is temporarily unavailable. Please try again in a moment.")
            case ClassificationError.predictionFailed(let message):
                showError(message: "Analysis failed: \(message)")
            default:
                showError(message: "Food classification failed. Please try again.")
            }
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Photo Capture Delegate
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<UIImage, Error>) -> Void
    
    init(completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.completion = completion
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion(.failure(NSError(domain: "PhotoCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from photo data"])))
            return
        }
        
        completion(.success(image))
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct LiveCameraScanView_Previews: PreviewProvider {
    static var previews: some View {
        LiveCameraScanView(
            onFoodDetected: { _, _ in },
            onDismiss: { }
        )
        .preferredColorScheme(.dark)
    }
}
#endif