import SwiftUI
import AVFoundation
import Vision
import CoreML
import UIKit

@available(iOS 16.0, *)
struct LiveCameraScanView: View {
    let onFoodDetected: (UIImage, FoodPrediction) -> Void
    let onDismiss: () -> Void

    @StateObject private var cameraManager = SimpleCameraManager()
    @State private var isAnalyzing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var captureButtonScale = 1.0
    @State private var scanFrameAnimation = false
    @State private var flashAnimation = false
    @State private var scanFrameRect: CGRect = .zero

    private let classifier = CoreMLFoodClassifier.shared

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if cameraManager.isAuthorized {
                ManagerBasedCameraPreview(cameraManager: cameraManager)
                    .ignoresSafeArea()
                cameraOverlay
            } else {
                permissionView
            }
        }
        .onAppear {
            Task {
                await cameraManager.requestPermission()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .alert("Analysis Error", isPresented: $showingError) {
            Button("Try Again") {}
            Button("Cancel") { onDismiss() }
        } message: {
            Text(errorMessage)
        }
    }

    private var cameraOverlay: some View {
        VStack {
            HStack {
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.title2.weight(.semibold)).foregroundColor(.white)
                        .frame(width: 44, height: 44).background(Color.black.opacity(0.6)).clipShape(Circle())
                }
                Spacer()
                Text("Scan Meal").font(.headline.weight(.semibold)).foregroundColor(.white)
                Spacer()
                Button { toggleFlash() } label: {
                    Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                        .font(.title2.weight(.semibold)).foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                        .frame(width: 44, height: 44).background(Color.black.opacity(0.6)).clipShape(Circle())
                        .scaleEffect(flashAnimation ? 1.1 : 1.0).animation(.easeInOut(duration: 0.1), value: flashAnimation)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.top ?? 0)

            Spacer()

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LinearGradient(colors: [FitConnectColors.accentCyan.opacity(scanFrameAnimation ? 1.0 : 0.6), FitConnectColors.accentPurple.opacity(scanFrameAnimation ? 0.8 : 0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                        .frame(width: 280, height: 280)
                        .scaleEffect(scanFrameAnimation ? 1.02 : 1.0).animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: scanFrameAnimation)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "viewfinder").font(.system(size: 40, weight: .light)).foregroundColor(.white.opacity(0.8))
                        Text("Position food in frame").font(.system(size: 16, weight: .medium)).foregroundColor(.white).multilineTextAlignment(.center)
                        if isAnalyzing { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan)).scaleEffect(1.2) }
                    }.opacity(isAnalyzing ? 0.7 : 1.0)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .onAppear { 
                    scanFrameAnimation = true
                    let screenWidth = UIScreen.main.bounds.width
                    let frameSize: CGFloat = 280
                    scanFrameRect = CGRect(
                        x: (screenWidth - frameSize) / 2,
                        y: geometry.frame(in: .global).midY - frameSize / 2,
                        width: frameSize,
                        height: frameSize
                    )
                }
            }

            Spacer()

            VStack(spacing: 20) {
                Button { captureAndAnalyze() } label: {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 80, height: 80).shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        if isAnalyzing { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan)).scaleEffect(1.2)
                        } else { Image(systemName: "camera.fill").font(.system(size: 28, weight: .medium)).foregroundColor(.black) }
                    }.scaleEffect(captureButtonScale)
                }
                .disabled(isAnalyzing).scaleEffect(isAnalyzing ? 0.9 : 1.0).animation(.easeInOut(duration: 0.2), value: isAnalyzing)
                .simultaneousGesture(TapGesture().onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) { captureButtonScale = 0.95 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.easeInOut(duration: 0.1)) { captureButtonScale = 1.0 } }
                })
                Text(isAnalyzing ? "Analyzing..." : "Tap to capture").font(.system(size: 16, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            .padding(.bottom, (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.safeAreaInsets.bottom ?? 20)
        }
    }

    private var permissionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "camera.fill").font(.system(size: 64, weight: .light)).foregroundColor(FitConnectColors.accentCyan)
            VStack(spacing: 16) {
                Text("Camera Access Required").font(.title2.bold()).foregroundColor(.white)
                Text("Allow camera access to scan your meals").font(.body).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
            }
            Button { Task { await cameraManager.requestPermission() } } label: {
                Text("Allow Camera Access").font(.headline.weight(.semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16).background(FitConnectColors.accentCyan).cornerRadius(16)
            }
        }
        .padding(.horizontal, 40).frame(maxWidth: .infinity, maxHeight: .infinity).background(FitConnectColors.backgroundDark)
    }

    private func toggleFlash() {
        cameraManager.toggleFlash()
        withAnimation(.easeInOut(duration: 0.1)) { flashAnimation.toggle() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { withAnimation(.easeInOut(duration: 0.1)) { flashAnimation = false } }
    }

    private func captureAndAnalyze() {
        guard !isAnalyzing else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium); impactFeedback.impactOccurred()
        isAnalyzing = true
        cameraManager.capturePhoto { result in
            switch result {
            case .success(let image):
                print("📷 Photo captured, analyzing...")
                analyzeImage(image)
            case .failure(let error):
                print("❌ Photo capture failed: \(error)")
                DispatchQueue.main.async { self.isAnalyzing = false; self.showError("Failed to capture photo: \(error.localizedDescription)") }
            }
        }
    }

    private func analyzeImage(_ image: UIImage) {
        print("🔍 Cropping to center and classifying image...")
        let centerImage = cropToCenterSquare(image)
        classifier.classifyFood(image: centerImage) { result in
            DispatchQueue.main.async {
                self.isAnalyzing = false
                switch result {
                case .success(let prediction):
                    print("✅ Classified: \(prediction.label) (\(String(format: "%.0f%%", prediction.confidence * 100)))")
                    if prediction.confidence < 0.3 {
                        self.showError("Food not detected clearly. Try better lighting.")
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        return
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    self.onFoodDetected(image, prediction)
                case .failure(let error):
                    print("❌ Classification failed: \(error.localizedDescription)")
                    self.showError("Could not identify food. Error: \(error.localizedDescription)")
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    private func showError(_ message: String) { errorMessage = message; showingError = true }

    private func cropToCenterSquare(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        print("🖼️ Original image size: \(cgImage.width)x\(cgImage.height)")
        
        // Calculate the crop region based on the scan frame
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let screenWidth = UIScreen.main.bounds.width
        
        // Scale factors to map screen coordinates to image coordinates
        let scaleX = imageWidth / screenWidth
        let scaleY = imageHeight / UIScreen.main.bounds.height
        
        // Use the larger scale to ensure we crop the correct portion
        let scale = max(scaleX, scaleY)
        
        // Calculate crop size (280pt scan frame scaled to image coordinates)
        let cropSize = 280 * scale
        
        // Center the crop
        let cropX = (imageWidth - cropSize) / 2
        let cropY = (imageHeight - cropSize) / 2
        
        let cropRect = CGRect(x: cropX, y: cropY, width: cropSize, height: cropSize)
        
        print("🔍 Cropping to: \(cropRect) from image: \(imageWidth)x\(imageHeight)")
        
        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            print("❌ Failed to crop image, using original")
            return image
        }
        
        print("✅ Cropped to: \(croppedImage.width)x\(croppedImage.height)")
        return UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

@MainActor
class SimpleCameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isFlashOn = false
    @Published var isSessionRunning = false
    let captureSession = AVCaptureSession()
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?
    private var photoCaptureCompletionHandler: ((Result<UIImage, Error>) -> Void)?

    override init() { super.init() }

    func requestPermission() async {
        print("Requesting camera permission...")
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .authorized {
            print("Permission already authorized.")
            isAuthorized = true
            await setupCamera()
            return
        }
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("Permission granted: \(granted)")
            isAuthorized = granted
            if granted { await setupCamera() }
            else { print("Permission denied by user.") }
        } else {
            isAuthorized = false // Denied or restricted
            print("Permission previously denied or restricted.")
            // Consider guiding user to settings here
        }
    }

    func setupCamera() async {
        guard isAuthorized else { print("Not authorized to setup camera."); return }
        guard !captureSession.isRunning else { print("Session already running."); isSessionRunning = true; return }
        print("Setting up camera...")
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ No back camera."); captureSession.commitConfiguration(); isSessionRunning = false; return
        }
        currentDevice = device
        do {
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) { captureSession.addInput(input); print("✅ Input added.") }
            else { print("❌ Failed to add input."); captureSession.commitConfiguration(); isSessionRunning = false; return }

            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            let newPhotoOutput = AVCapturePhotoOutput()
            if captureSession.canAddOutput(newPhotoOutput) { captureSession.addOutput(newPhotoOutput); self.photoOutput = newPhotoOutput; print("✅ Output added.") }
            else { print("❌ Failed to add output.")}
            
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("✅ Session started.")
                    DispatchQueue.main.async { self.isSessionRunning = true }
                }
            }
        } catch {
            print("❌ Setup failed: \(error.localizedDescription)"); captureSession.commitConfiguration(); isSessionRunning = false
        }
    }

    func toggleFlash() {
        guard let device = currentDevice, device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            isFlashOn = device.torchMode == .on
            device.unlockForConfiguration()
        } catch { print("❌ Flash toggle failed: \(error)") }
    }

    func capturePhoto(completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let photoOutput = photoOutput, captureSession.isRunning else {
            completion(.failure(NSError(domain: "Camera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Output not ready or session not running"])))
            return
        }
        photoCaptureCompletionHandler = completion
        var photoSettings = AVCapturePhotoSettings()
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) { photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc]) }
        photoSettings.flashMode = isFlashOn ? .on : .off
        guard photoOutput.connection(with: .video) != nil else {
            completion(.failure(NSError(domain: "Camera", code: 3, userInfo: [NSLocalizedDescriptionKey: "No video connection"]))); return
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        print("Capturing photo...")
    }

    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning(); print("Session stopped.")
                DispatchQueue.main.async { self.isSessionRunning = false }
            }
        } else { DispatchQueue.main.async { self.isSessionRunning = false } }
    }
    func getSession() -> AVCaptureSession { return captureSession }
}

extension SimpleCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let capturedCompletionHandler = self.photoCaptureCompletionHandler
        
        Task { @MainActor in
            self.photoCaptureCompletionHandler = nil
            
            if let error = error { 
                print("❌ Error processing: \(error.localizedDescription)")
                capturedCompletionHandler?(.failure(error))
                return 
            }
            
            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
                print("❌ No image data")
                capturedCompletionHandler?(.failure(NSError(domain: "Camera", code: 2, userInfo: [NSLocalizedDescriptionKey: "No image data"])))
                return
            }
            
            print("✅ Photo processed.")
            capturedCompletionHandler?(.success(image))
        }
    }
}

struct ManagerBasedCameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: SimpleCameraManager
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds); view.backgroundColor = .black
        print("Preview: makeUIView")
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.getSession())
        previewLayer.videoGravity = .resizeAspectFill; view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer; previewLayer.frame = view.bounds
        if cameraManager.isAuthorized && !cameraManager.captureSession.isRunning {
            print("Preview: Starting session via manager.")
            Task { await cameraManager.setupCamera() } // Call setupCamera if needed
        } else if cameraManager.captureSession.isRunning { print("Preview: Session running.") }
        else if !cameraManager.isAuthorized { print("Preview: Not authorized.")}
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        context.coordinator.previewLayer?.frame = uiView.bounds
        if context.coordinator.previewLayer?.session !== cameraManager.getSession() {
            context.coordinator.previewLayer?.session = cameraManager.getSession()
            print("Preview: Session updated.")
        }
        CATransaction.commit()
        // print("Preview: updateUIView, frame: \(uiView.bounds)")
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject { var previewLayer: AVCaptureVideoPreviewLayer? }
}

#if DEBUG
@available(iOS 16.0, *)
struct LiveCameraScanView_Previews: PreviewProvider {
    static var previews: some View {
        LiveCameraScanView(
            onFoodDetected: { _, p in print("Preview Detected: \(p.label)") },
            onDismiss: { print("Preview Dismissed") }
        ).preferredColorScheme(.dark)
    }
}
#endif