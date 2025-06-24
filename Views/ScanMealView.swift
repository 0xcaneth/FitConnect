import SwiftUI
import AVFoundation
import PhotosUI
import FirebaseAuth
import FirebaseStorage

@available(iOS 16.0, *)
struct ScanMealView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var capturedImage: UIImage?
    @State private var analysisResult: MealAnalysis?
    @State private var isAnalyzing: Bool = false
    @State private var showingPhotoPicker: Bool = false
    @State private var showingResults: Bool = false
    @State private var showingError: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccess: Bool = false
    @State private var successMessage: String = ""
    @State private var showingActionSheet = false
    @State private var animateBackground = false
    @State private var pulseAnimation = false
    @State private var showingLiveCamera = false
    @State private var foodPrediction: FoodPrediction?
    
    // Camera permissions
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var photoPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    // Services
    private let mealService = MealService.shared
    private let classifier = CoreMLFoodClassifier()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FitConnectColors.backgroundDark,
                    FitConnectColors.backgroundSecondary.opacity(animateBackground ? 0.8 : 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateBackground)
            
            if showingResults {
                ScanResultView( 
                    image: capturedImage,
                    analysis: analysisResult,
                    detectedFoodName: foodPrediction?.label ?? "Unknown Food", 
                    onSave: { mealType in
                        Task {
                            await saveMeal(mealType: mealType)
                        }
                    },
                    onRetry: {
                        retryAnalysis()
                    },
                    onDismiss: {
                        dismiss()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                mainScanView
            }
        }
        .fullScreenCover(isPresented: $showingLiveCamera) {
            LiveCameraScanView(
                onFoodDetected: { image, prediction in
                    processCapturedResult(image: image, prediction: prediction)
                },
                onDismiss: {
                    showingLiveCamera = false
                }
            )
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView { image in
                processCapturedImage(image)
            }
        }
        .confirmationDialog("Choose Photo Source", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button(" Live Camera Scan") {
                openLiveCamera()
            }
            
            Button(" Choose from Library") {
                openPhotoLibrary()
            }
            
            Button("Cancel", role: .cancel) { }
        }
        .alert("Error", isPresented: $showingError) {
            if errorMessage?.contains("Settings") == true {
                Button("Open Settings") {
                    openSettings()
                }
                Button("Cancel", role: .cancel) { }
            } else {
                Button("Retry") {
                    retryAnalysis()
                }
                Button("Cancel", role: .cancel) { }
            }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .overlay(
            VStack {
                if showSuccess {
                    MealSuccessToastView(message: successMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
        )
        .onAppear {
            animateBackground = true
            pulseAnimation = true
            checkPermissions()
        }
    }
    
    // MARK: - Views
    
    private var mainScanView: some View {
        VStack(spacing: 0) {
            headerView
            Spacer()
            
            if isAnalyzing {
                analyzingView
            } else {
                instructionView
            }
            
            Spacer()
            actionButtonsView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(MealScaleButtonStyle())
            
            Spacer()
            
            Text("Scan Meal")
                .font(.title2.bold())
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    private var instructionView: some View {
        VStack(spacing: 32) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                FitConnectColors.accentCyan.opacity(pulseAnimation ? 0.8 : 0.4),
                                FitConnectColors.accentPurple.opacity(pulseAnimation ? 0.6 : 0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                VStack(spacing: 20) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(FitConnectColors.accentCyan)
                        .shadow(color: FitConnectColors.accentCyan.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(spacing: 8) {
                        Text("AI-Powered Live Scanning")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitConnectColors.textSecondary)
                        
                        Text(" Point • Detect • Analyze")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(FitConnectColors.textTertiary)
                    }
                }
            }
            
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Real-Time Food Recognition")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(FitConnectColors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Live camera feed with instant AI classification and nutrition analysis")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(FitConnectColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                HStack(spacing: 20) {
                    MealFeatureHighlight(icon: "camera.viewfinder", text: "Live Preview")
                    MealFeatureHighlight(icon: "brain.head.profile", text: "AI Recognition")
                    MealFeatureHighlight(icon: "speedometer", text: "Instant Results")
                }
            }
        }
    }
    
    private var analyzingView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(isAnalyzing ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnalyzing)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(FitConnectColors.accentCyan)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            VStack(spacing: 16) {
                Text("Analyzing Your Meal...")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Text("Our advanced AI is identifying ingredients and calculating precise nutrition information")
                    .font(.system(size: 16))
                    .foregroundColor(FitConnectColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                HStack(spacing: 12) {
                    MealProgressStep(text: "Capturing", isActive: true)
                    MealProgressStep(text: "Analyzing", isActive: isAnalyzing)
                    MealProgressStep(text: "Calculating", isActive: false)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            Button {
                openLiveCamera()
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Start Live Scan")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: FitConnectColors.accentCyan.opacity(0.4), radius: 12, x: 0, y: 6)
                .scaleEffect(isAnalyzing ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isAnalyzing)
            }
            .disabled(isAnalyzing)
            .buttonStyle(MealScaleButtonStyle())
            
            HStack(spacing: 20) {
                MealQuickActionButton(
                    icon: "photo.on.rectangle",
                    text: "Gallery",
                    color: FitConnectColors.accentPurple
                ) {
                    openPhotoLibrary()
                }
                .disabled(isAnalyzing)
                
                MealQuickActionButton(
                    icon: "plus.viewfinder",
                    text: "More Options",
                    color: FitConnectColors.accentOrange
                ) {
                    showingActionSheet = true
                }
                .disabled(isAnalyzing)
            }
        }
        .padding(.bottom, 32)
        .opacity(isAnalyzing ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isAnalyzing)
    }
    
    // MARK: - Permission Handling
    
    private func checkPermissions() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    private func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermissionStatus = granted ? .authorized : .denied
        
        if granted {
            showingLiveCamera = true
        } else {
            showPermissionError(for: .camera)
        }
    }
    
    private func requestPhotoPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoPermissionStatus = status
        
        if status == .authorized || status == .limited {
            showingPhotoPicker = true
        } else {
            showPermissionError(for: .photos)
        }
    }
    
    private func openLiveCamera() {
        switch cameraPermissionStatus {
        case .authorized:
            showingLiveCamera = true
        case .notDetermined:
            Task {
                await requestCameraPermission()
            }
        case .denied, .restricted:
            showPermissionError(for: .camera)
        @unknown default:
            showPermissionError(for: .camera)
        }
    }
    
    private func openPhotoLibrary() {
        switch photoPermissionStatus {
        case .authorized, .limited:
            showingPhotoPicker = true
        case .notDetermined:
            Task {
                await requestPhotoPermission()
            }
        case .denied, .restricted:
            showPermissionError(for: .photos)
        @unknown default:
            showPermissionError(for: .photos)
        }
    }
    
    // MARK: - Image Processing
    
    private func processCapturedResult(image: UIImage, prediction: FoodPrediction) {
        capturedImage = image
        foodPrediction = prediction
        analysisResult = prediction.mealAnalysis
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        successMessage = "Meal detected: \(prediction.label), \(prediction.calories) kcal"
        showSuccess = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showSuccess = false
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingResults = true
        }
        
        showingLiveCamera = false
    }
    
    private func processCapturedImage(_ image: UIImage) {
        capturedImage = image
        Task {
            await analyzeMeal()
        }
    }
    
    private func analyzeMeal() async {
        guard let image = capturedImage else {
            showError("No image to analyze")
            return
        }
        
        isAnalyzing = true
        showingResults = false
        errorMessage = nil
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        do {
            let prediction = try await classifyFoodWithCoreML(image: image)
            analysisResult = prediction.mealAnalysis
            foodPrediction = prediction
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingResults = true
            }
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            successMessage = "Meal analyzed: \(prediction.label), \(prediction.calories) kcal"
            showSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showSuccess = false
            }
            
        } catch let error as ClassificationError {
            handleClassificationError(error)
        } catch {
            showError("Unexpected error occurred during analysis")
        }
        
        isAnalyzing = false
    }
    
    private func classifyFoodWithCoreML(image: UIImage) async throws -> FoodPrediction {
        return try await withCheckedThrowingContinuation { continuation in
            classifier.classifyFood(image: image) { result in
                switch result {
                case .success(let prediction):
                    if prediction.confidence < 0.5 {
                        continuation.resume(throwing: ClassificationError.lowConfidence)
                    } else {
                        continuation.resume(returning: prediction)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Save Meal
    
    private func saveMeal(mealType: Meal.MealType = .snack) async {
        guard let image = capturedImage,
              let analysis = analysisResult else {
            showError("Missing image or analysis data")
            return
        }
        
        isAnalyzing = true
        
        do {
            let meal = try await saveMealToFirestore(
                analysis: analysis,
                image: image,
                mealType: mealType
            )
            
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            successMessage = "Meal saved to your diary!"
            showSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetCapture()
            }
            
        } catch {
            showError("Failed to save meal. Please try again.")
        }
        
        isAnalyzing = false
    }
    
    private func saveMealToFirestore(analysis: MealAnalysis, image: UIImage, mealType: Meal.MealType) async throws -> Meal {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ScanMealView", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let mealId = UUID().uuidString
        
        let imageURL: String
        do {
            imageURL = try await uploadImageToStorage(image: image, userId: userId, mealId: mealId)
        } catch {
            print("❌ Image upload failed: \(error.localizedDescription)")
            // Use empty URL if upload fails - meal can still be saved
            imageURL = ""
        }
        
        let mealName = foodPrediction?.label ?? "Scanned Meal"
        
        var meal = Meal(
            mealName: mealName,
            mealType: mealType,
            calories: analysis.calories,
            protein: analysis.protein,
            fat: analysis.fat,
            carbs: analysis.carbs,
            timestamp: Date(),
            imageURL: imageURL.isEmpty ? nil : imageURL,
            userId: userId,
            confidence: analysis.confidence
        )
        
        meal.id = mealId
        
        do {
            try await mealService.saveMeal(meal)
            print("✅ Meal saved successfully with ID: \(mealId)")
        } catch {
            print("❌ Meal save failed: \(error.localizedDescription)")
            throw error
        }
        
        return meal
    }
    
    private func uploadImageToStorage(image: UIImage, userId: String, mealId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ScanMealView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        }
        
        let storage = Storage.storage()
        let photoId = UUID().uuidString
        
        let imagePath = "meal_photos/\(userId)/\(mealId)/\(photoId)"
        let storageRef = storage.reference().child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw NSError(domain: "ScanMealView", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to upload image"])
        }
    }
    
    // MARK: - Error Handling
    
    private func handleClassificationError(_ error: ClassificationError) {
        switch error {
        case .lowConfidence:
            showError("Unable to identify food with confidence. Try taking another photo with better lighting or positioning the food more clearly in the frame.")
        case .noResults:
            showError("No food detected in image. Please ensure food is clearly visible and well-lit.")
        case .invalidImage:
            showError("Invalid image. Please try taking another photo.")
        case .modelNotLoaded:
            showError("Food recognition is temporarily unavailable. Please try again later.")
        case .predictionFailed(let message):
            showError("Analysis failed: \(message)")
        }
        
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func showPermissionError(for type: PermissionType) {
        let message = type == .camera
            ? "Camera access is required to scan meals. Please enable camera access in Settings."
            : "Photo access is required to select images. Please enable photo access in Settings."
        showError(message)
    }
    
    private func retryAnalysis() {
        guard capturedImage != nil else { return }
        Task {
            await analyzeMeal()
        }
    }
    
    private func resetCapture() {
        withAnimation(.easeInOut(duration: 0.3)) {
            capturedImage = nil
            analysisResult = nil
            foodPrediction = nil
            errorMessage = nil
            showingResults = false
            showingError = false
            showSuccess = false
            isAnalyzing = false
            showingLiveCamera = false
            showingPhotoPicker = false
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Helper Types

enum PermissionType {
    case camera
    case photos
}

// MARK: - Supporting Views

struct MealFeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(FitConnectColors.accentCyan)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(FitConnectColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealProgressStep: View {
    let text: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isActive ? FitConnectColors.accentCyan : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)
                .scaleEffect(isActive ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isActive ? FitConnectColors.textPrimary : FitConnectColors.textTertiary)
        }
    }
}

struct MealQuickActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(MealScaleButtonStyle())
    }
}

struct MealSuccessToastView: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.green)
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FitConnectColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct MealScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

@available(iOS 16.0, *)
struct PhotoPickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                parent.dismiss()
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        self.parent.onImageSelected(image)
                    }
                }
            }
            
            parent.dismiss()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ScanMealView_Previews: PreviewProvider {
    static var previews: some View {
        ScanMealView()
            .preferredColorScheme(.dark)
    }
}
#endif