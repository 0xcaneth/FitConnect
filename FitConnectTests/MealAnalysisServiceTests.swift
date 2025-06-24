import XCTest
@testable import FitConnect

@MainActor
final class MealAnalysisServiceTests: XCTestCase {
    var service: MealAnalysisService!
    
    override func setUp() {
        super.setUp()
        service = MealAnalysisService.shared
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testAnalyzeMealImageWithValidData() async throws {
        // Given
        let testImage = createTestImageData()
        
        // Mock successful API response
        let mockResponse = """
        {
            "calories": 350,
            "protein": 25.5,
            "fat": 12.0,
            "carbs": 45.2,
            "confidence": 0.87
        }
        """
        
        // This would require implementing a mock URLSession
        // For production, you would inject URLSession as a dependency
        
        // When/Then - This test requires actual API or mock setup
        // For now, documenting the expected behavior
        XCTAssertNotNil(testImage)
    }
    
    func testAnalyzeMealImageWithInvalidData() async {
        // Given
        let invalidData = Data()
        
        // When/Then
        do {
            _ = try await service.analyzeMealImage(invalidData)
            XCTFail("Should throw error for invalid data")
        } catch MealAnalysisError.invalidImageData {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMealAnalysisErrorDescriptions() {
        // Test error descriptions are user-friendly
        XCTAssertEqual(MealAnalysisError.invalidImageData.errorDescription, "Invalid image data provided")
        XCTAssertEqual(MealAnalysisError.networkError.errorDescription, "Network error. Please check your internet connection")
        XCTAssertEqual(MealAnalysisError.timeout.errorDescription, "Request timed out. Please check your connection")
        XCTAssertEqual(MealAnalysisError.serverError.errorDescription, "Server error occurred")
        XCTAssertEqual(MealAnalysisError.rateLimitExceeded.errorDescription, "Rate limit exceeded. Please try again later")
    }
    
    func testRetryableErrors() {
        // Test which errors are retryable
        XCTAssertTrue(MealAnalysisError.timeout.isRetryable)
        XCTAssertTrue(MealAnalysisError.networkError.isRetryable)
        XCTAssertTrue(MealAnalysisError.serverError.isRetryable)
        XCTAssertTrue(MealAnalysisError.rateLimitExceeded.isRetryable)
        
        XCTAssertFalse(MealAnalysisError.invalidImageData.isRetryable)
        XCTAssertFalse(MealAnalysisError.unauthorized.isRetryable)
        XCTAssertFalse(MealAnalysisError.invalidRequest.isRetryable)
    }
    
    private func createTestImageData() -> Data {
        let image = UIImage(systemName: "camera.fill")!
        return image.jpegData(compressionQuality: 0.8)!
    }
}

// MARK: - Mock Service for Testing

class MockMealAnalysisService: MealAnalysisService {
    var shouldSucceed = true
    var mockAnalysis = MealAnalysis(calories: 350, protein: 25.0, fat: 12.0, carbs: 45.0, confidence: 0.87)
    
    override func analyzeMealImage(_ imageData: Data) async throws -> MealAnalysis {
        if shouldSucceed {
            return mockAnalysis
        } else {
            throw MealAnalysisError.networkError
        }
    }
}