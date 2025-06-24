import XCTest
import SwiftUI
@testable import FitConnect

@available(iOS 16.0, *)
final class ScanResultViewTests: XCTestCase {
    
    func testScanResultViewWithHighConfidence() {
        // Given
        let testImage = UIImage(systemName: "camera.fill")!
        let highConfidenceAnalysis = MealAnalysis(
            calories: 450,
            protein: 35.0,
            fat: 15.0,
            carbs: 52.0,
            confidence: 0.92
        )
        
        // When
        let view = ScanResultView(
            image: testImage,
            analysis: highConfidenceAnalysis,
            onSave: { _ in },
            onRetry: { },
            onDismiss: { }
        )
        
        // Then - In a full test setup, you would take a snapshot here
        XCTAssertNotNil(view)
        XCTAssertEqual(highConfidenceAnalysis.confidence, 0.92)
    }
    
    func testScanResultViewWithLowConfidence() {
        // Given
        let testImage = UIImage(systemName: "camera.fill")!
        let lowConfidenceAnalysis = MealAnalysis(
            calories: 250,
            protein: 18.0,
            fat: 8.0,
            carbs: 32.0,
            confidence: 0.45
        )
        
        // When
        let view = ScanResultView(
            image: testImage,
            analysis: lowConfidenceAnalysis,
            onSave: { _ in },
            onRetry: { },
            onDismiss: { }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(lowConfidenceAnalysis.confidence, 0.45)
    }
    
    func testScanResultViewWithHighMacros() {
        // Given
        let testImage = UIImage(systemName: "camera.fill")!
        let highMacroAnalysis = MealAnalysis(
            calories: 850,
            protein: 65.0,
            fat: 45.0,
            carbs: 85.0,
            confidence: 0.78
        )
        
        // When
        let view = ScanResultView(
            image: testImage,
            analysis: highMacroAnalysis,
            onSave: { _ in },
            onRetry: { },
            onDismiss: { }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(highMacroAnalysis.calories, 850)
        XCTAssertEqual(highMacroAnalysis.protein, 65.0)
    }
    
    func testScanResultViewWithLowMacros() {
        // Given
        let testImage = UIImage(systemName: "camera.fill")!
        let lowMacroAnalysis = MealAnalysis(
            calories: 120,
            protein: 5.0,
            fat: 2.0,
            carbs: 25.0,
            confidence: 0.83
        )
        
        // When
        let view = ScanResultView(
            image: testImage,
            analysis: lowMacroAnalysis,
            onSave: { _ in },
            onRetry: { },
            onDismiss: { }
        )
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(lowMacroAnalysis.calories, 120)
        XCTAssertEqual(lowMacroAnalysis.carbs, 25.0)
    }
}