import Foundation
import FirebaseStorage
import FirebaseAuth
import UIKit

@MainActor
class MealAnalysisService: ObservableObject {
    static let shared = MealAnalysisService()
    
    private let session = URLSession.shared
    private let storage = Storage.storage()
    
    // Production AI API endpoint
    private let aiEndpoint = "https://api.fitconnect.ai/analyze"
    
    @Published var isAnalyzing = false
    @Published var analysisError: String?
    
    private init() {}
    
    /// Analyzes meal image using production AI service
    func analyzeMealImage(_ imageData: Data) async throws -> MealAnalysis {
        guard !imageData.isEmpty else {
            throw MealAnalysisError.invalidImageData
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        var request = URLRequest(url: URL(string: aiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30.0
        
        // Convert image to base64 for API
        let base64Image = imageData.base64EncodedString()
        let requestBody = [
            "image": base64Image,
            "format": "jpg"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw MealAnalysisError.requestEncodingFailed
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MealAnalysisError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let analysisResponse = try JSONDecoder().decode(AIAnalysisResponse.self, from: data)
                return MealAnalysis(
                    calories: analysisResponse.calories,
                    protein: analysisResponse.protein,
                    fat: analysisResponse.fat,
                    carbs: analysisResponse.carbs,
                    confidence: analysisResponse.confidence
                )
            case 400:
                throw MealAnalysisError.invalidRequest
            case 401:
                throw MealAnalysisError.unauthorized
            case 429:
                throw MealAnalysisError.rateLimitExceeded
            case 500...599:
                throw MealAnalysisError.serverError
            default:
                throw MealAnalysisError.unknownError(httpResponse.statusCode)
            }
        } catch let error as MealAnalysisError {
            throw error
        } catch {
            if error.localizedDescription.contains("timeout") {
                throw MealAnalysisError.timeout
            } else if error.localizedDescription.contains("network") {
                throw MealAnalysisError.networkError
            } else {
                throw MealAnalysisError.unknownError(0)
            }
        }
    }
    
    /// Uploads image to Firebase Storage and returns download URL
    func uploadMealImage(_ imageData: Data) async throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealAnalysisError.userNotAuthenticated
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let imagePath = "meal_photos/\(userId)/\(dateString())/\(fileName)"
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
    
    /// Creates and saves meal to Firestore with analysis results
    func saveMealWithAnalysis(
        imageData: Data,
        analysis: MealAnalysis,
        mealType: Meal.MealType = .snack
    ) async throws -> Meal {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw MealAnalysisError.userNotAuthenticated
        }
        
        // Upload image first
        let imageURL = try await uploadMealImage(imageData)
        
        // Create meal object
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
        
        // Save to Firestore via MealService
        try await MealService.shared.saveMeal(meal)
        
        return meal
    }
    
    // MARK: - Private Methods
    
    private func getAPIKey() -> String {
        // In production, this should be securely stored/retrieved
        // For now, using a placeholder - replace with actual API key management
        return "your-production-api-key-here"
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Response Models

private struct AIAnalysisResponse: Codable {
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let confidence: Double
}

// MARK: - Error Types

enum MealAnalysisError: LocalizedError {
    case invalidImageData
    case requestEncodingFailed
    case invalidResponse
    case invalidRequest
    case unauthorized
    case rateLimitExceeded
    case serverError
    case timeout
    case networkError
    case imageUploadFailed
    case userNotAuthenticated
    case unknownError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data provided"
        case .requestEncodingFailed:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidRequest:
            return "Invalid request format"
        case .unauthorized:
            return "Unauthorized access to AI service"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        case .serverError:
            return "Server error occurred"
        case .timeout:
            return "Request timed out. Please check your connection"
        case .networkError:
            return "Network error. Please check your internet connection"
        case .imageUploadFailed:
            return "Failed to upload image"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .unknownError(let code):
            return "Unknown error occurred (Code: \(code))"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .timeout, .networkError, .serverError, .rateLimitExceeded:
            return true
        default:
            return false
        }
    }
}
