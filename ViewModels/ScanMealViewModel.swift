import Foundation
import SwiftUI
import AVFoundation
import Photos
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

@MainActor
class ScanMealViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var capturedImage: UIImage?
    @Published var analysisResult: MealAnalysis?
    @Published var isAnalyzing: Bool = false
    @Published var showingCameraPicker: Bool = false
    @Published var showingPhotoPicker: Bool = false
    @Published var showingResults: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?
    @Published var showSuccess: Bool = false
    @Published var successMessage: String = ""
    @Published var savedMeal: Meal?
    
    // Camera permissions
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoPermissionStatus: PHAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private let analysisService = MealAnalysisService.shared
    private let mealService = MealService.shared
    private let classifier = CoreMLFoodClassifier()
    
    // MARK: - Initialization
    init() {
        checkPermissions()
    }
    
    // MARK: - Permission Handling
    
    func checkPermissions() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoPermissionStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermissionStatus = granted ? .authorized : .denied
        
        if granted {
            showingCameraPicker = true
        } else {
            showPermissionError(for: .camera)
        }
    }
    
    func requestPhotoPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        photoPermissionStatus = status
        
        if status == .authorized || status == .limited {
            showingPhotoPicker = true
        } else {
            showPermissionError(for: .photos)
        }
    }
    
    // MARK: - Image Capture Actions
    
    func openCamera() {
        switch cameraPermissionStatus {
        case .authorized:
            showingCameraPicker = true
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
    
    func openPhotoLibrary() {
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
    
    func processCapturedImage(_ image: UIImage) {
        capturedImage = image
        Task {
            await analyzeMeal()
        }
    }
    
    func analyzeMeal() async {
        guard let image = capturedImage else {
            showError("No image to analyze")
            return
        }
        
        isAnalyzing = true
        showingResults = false
        errorMessage = nil
        
        // Add haptic feedback for start of analysis
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        do {
            // Use CoreML classifier first for food recognition
            let prediction = try await classifyFoodWithCoreML(image: image)
            analysisResult = prediction.mealAnalysis
            
            // Animate results presentation with spring animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingResults = true
            }
            
            // Success feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            successMessage = "Meal analyzed: \(prediction.label), \(prediction.calories) kcal"
            showSuccess = true
            
            // Auto-hide success message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showSuccess = false
            }
            
        } catch let error as ClassificationError {
            handleClassificationError(error)
        } catch let error as MealAnalysisError {
            handleAnalysisError(error)
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
                    if prediction.confidence < 0.3 {
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
    
    func saveMeal(mealType: Meal.MealType = .snack) async {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8),
              let analysis = analysisResult else {
            showError("Missing image or analysis data")
            return
        }
        
        isAnalyzing = true
        
        do {
            // Upload image and save meal
            let meal = try await saveMealToFirestore(
                analysis: analysis,
                image: image,
                mealType: mealType
            )
            
            savedMeal = meal
            
            // Success feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
            
            successMessage = "Meal saved to your diary!"
            showSuccess = true
            
            // Auto-dismiss after successful save
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetCapture()
            }
            
        } catch let error as MealAnalysisError {
            handleAnalysisError(error)
        } catch {
            showError("Failed to save meal. Please try again.")
        }
        
        isAnalyzing = false
    }
    
    private func saveMealToFirestore(analysis: MealAnalysis, image: UIImage, mealType: Meal.MealType) async throws -> Meal {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealAnalysisError.userNotAuthenticated
        }
        
        // Upload image to Storage
        let imageURL = try await uploadImageToStorage(image: image, userId: userId)
        
        // Create meal document
        let meal = Meal(
            mealName: "Scanned Meal",
            mealType: mealType,
            calories: analysis.calories,
            protein: analysis.protein,
            fat: analysis.fat,
            carbs: analysis.carbs,
            timestamp: Date(),
            imageURL: imageURL,
            userId: userId,
            confidence: analysis.confidence
        )
        
        // Save using MealService
        try await mealService.saveMeal(meal)
        
        return meal
    }
    
    private func uploadImageToStorage(image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MealAnalysisError.invalidImageData
        }
        
        let imageId = UUID().uuidString
        let imagePath = "meal_photos/\(userId)/\(dateString())/\(imageId).jpg"
        let storageRef = storage.reference().child(imagePath)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw MealAnalysisError.imageUploadFailed
        }
    }
    
    // MARK: - Error Handling
    
    private func handleClassificationError(_ error: ClassificationError) {
        switch error {
        case .lowConfidence:
            showError("Unable to identify food with confidence. Try taking another photo with better lighting.")
        case .noResults:
            showError("No food detected in image. Please ensure food is clearly visible.")
        case .invalidImage:
            showError("Invalid image. Please try taking another photo.")
        case .modelNotLoaded:
            showError("Food recognition is temporarily unavailable. Please try again later.")
        case .predictionFailed(let message):
            showError("Analysis failed: \(message)")
        }
        
        // Error haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    private func handleAnalysisError(_ error: MealAnalysisError) {
        showError(error.localizedDescription)
        
        // Error haptic feedback
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
    
    // MARK: - Retry Logic
    
    func retryAnalysis() {
        guard capturedImage != nil else { return }
        Task {
            await analyzeMeal()
        }
    }
    
    // MARK: - Reset State
    
    func resetCapture() {
        withAnimation(.easeInOut(duration: 0.3)) {
            capturedImage = nil
            analysisResult = nil
            savedMeal = nil
            errorMessage = nil
            showingResults = false
            showingError = false
            showSuccess = false
            isAnalyzing = false
            showingCameraPicker = false
            showingPhotoPicker = false
        }
    }
    
    // MARK: - Helper Methods
    
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
