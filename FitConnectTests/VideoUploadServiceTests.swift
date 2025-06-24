import XCTest
import AVFoundation
@testable import FitConnect

final class VideoUploadServiceTests: XCTestCase {
    var videoUploadService: VideoUploadService!
    
    override func setUpWithError() throws {
        videoUploadService = VideoUploadService.shared
    }
    
    override func tearDownWithError() throws {
        videoUploadService = nil
    }
    
    // MARK: - Video Validation Tests
    
    func testVideoValidation_ValidVideo() async throws {
        // Create a test video URL (you would need to provide a valid test video file)
        let testVideoURL = createTestVideoURL()
        
        do {
            let isValid = try await videoUploadService.validateVideo(at: testVideoURL)
            XCTAssertTrue(isValid, "Valid video should pass validation")
        } catch {
            XCTFail("Valid video validation failed: \(error)")
        }
    }
    
    func testVideoValidation_InvalidDuration() async throws {
        // Create a test video that exceeds 60 seconds
        let longVideoURL = createLongTestVideoURL()
        
        do {
            _ = try await videoUploadService.validateVideo(at: longVideoURL)
            XCTFail("Video with duration > 60 seconds should fail validation")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("60 seconds"), "Error should mention duration limit")
        }
    }
    
    // MARK: - Thumbnail Generation Tests
    
    func testThumbnailGeneration() async throws {
        let testVideoURL = createTestVideoURL()
        
        do {
            let thumbnail = try await videoUploadService.generateThumbnail(from: testVideoURL)
            XCTAssertNotNil(thumbnail, "Thumbnail should be generated")
            XCTAssertGreaterThan(thumbnail.size.width, 0, "Thumbnail should have valid width")
            XCTAssertGreaterThan(thumbnail.size.height, 0, "Thumbnail should have valid height")
        } catch {
            XCTFail("Thumbnail generation failed: \(error)")
        }
    }
    
    // MARK: - Video Compression Tests
    
    func testVideoCompression() async throws {
        let testVideoURL = createTestVideoURL()
        
        do {
            let compressedURL = try await videoUploadService.compressVideo(at: testVideoURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: compressedURL.path), "Compressed video file should exist")
            
            // Check if compressed file is smaller (basic test)
            let originalSize = try testVideoURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            let compressedSize = try compressedURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            
            XCTAssertLessThanOrEqual(compressedSize, originalSize, "Compressed video should be smaller or equal in size")
            
            // Clean up
            try? FileManager.default.removeItem(at: compressedURL)
        } catch {
            XCTFail("Video compression failed: \(error)")
        }
    }
    
    // MARK: - Mock Upload Test (without Firebase)
    
    func testUploadVideoMock() async throws {
        // This would test the upload logic with a mock Firebase Storage
        // For now, we'll test the method exists and handles errors properly
        
        let invalidURL = URL(fileURLWithPath: "/nonexistent/video.mp4")
        
        do {
            _ = try await videoUploadService.uploadVideo(invalidURL, for: "testUser", chatId: "testChat")
            XCTFail("Upload should fail for nonexistent file")
        } catch {
            // Expected to fail
            XCTAssertTrue(true, "Upload correctly failed for invalid file")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestVideoURL() -> URL {
        // In a real test, you would include a small test video file in your test bundle
        // For now, return a placeholder URL
        let testBundle = Bundle(for: type(of: self))
        return testBundle.url(forResource: "test_video", withExtension: "mp4") ?? URL(fileURLWithPath: "/tmp/test_video.mp4")
    }
    
    private func createLongTestVideoURL() -> URL {
        // In a real test, you would include a long test video file
        let testBundle = Bundle(for: type(of: self))
        return testBundle.url(forResource: "long_test_video", withExtension: "mp4") ?? URL(fileURLWithPath: "/tmp/long_test_video.mp4")
    }
}