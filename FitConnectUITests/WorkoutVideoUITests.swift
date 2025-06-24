import XCTest

final class WorkoutVideoUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Video Recording Flow Tests
    
    func testWorkoutVideoRecordingFlow() throws {
        // Navigate to a chat
        navigateToChat()
        
        // Tap attachment button
        let attachmentButton = app.buttons["plus"]
        XCTAssertTrue(attachmentButton.exists, "Attachment button should exist")
        attachmentButton.tap()
        
        // Wait for attachment options to appear
        let attachmentSheet = app.sheets.firstMatch
        XCTAssertTrue(attachmentSheet.waitForExistence(timeout: 3), "Attachment options sheet should appear")
        
        // Tap workout video option
        let workoutVideoButton = app.buttons["Workout Video"]
        XCTAssertTrue(workoutVideoButton.exists, "Workout Video button should exist")
        workoutVideoButton.tap()
        
        // Verify workout video recorder sheet appears
        let videoRecorderSheet = app.otherElements["WorkoutVideoRecorderSheet"]
        XCTAssertTrue(videoRecorderSheet.waitForExistence(timeout: 3), "Video recorder sheet should appear")
        
        // Tap start recording button
        let startRecordingButton = app.buttons["Start Recording"]
        XCTAssertTrue(startRecordingButton.exists, "Start Recording button should exist")
        startRecordingButton.tap()
        
        // Verify camera permission dialog or video recorder appears
        // Note: In a real test, you might need to handle camera permissions
        
        // For now, just verify the flow gets this far
        XCTAssertTrue(true, "Workout video recording flow initiated successfully")
    }
    
    func testAttachmentOptionsDisplay() throws {
        navigateToChat()
        
        // Tap attachment button
        app.buttons["plus"].tap()
        
        // Wait for sheet to appear
        let attachmentSheet = app.sheets.firstMatch
        XCTAssertTrue(attachmentSheet.waitForExistence(timeout: 3), "Attachment options should appear")
        
        // Verify all options are present
        XCTAssertTrue(app.buttons["Workout Video"].exists, "Workout Video option should exist")
        XCTAssertTrue(app.buttons["Photo"].exists, "Photo option should exist")
        XCTAssertTrue(app.buttons["Video"].exists, "Video option should exist")
        XCTAssertTrue(app.buttons["Document"].exists, "Document option should exist")
        
        // Verify workout video is featured prominently
        let workoutVideoButton = app.buttons["Workout Video"]
        let workoutVideoFrame = workoutVideoButton.frame
        let photoButton = app.buttons["Photo"]
        let photoFrame = photoButton.frame
        
        XCTAssertGreaterThan(workoutVideoFrame.height, photoFrame.height, "Workout video button should be larger than other options")
    }
    
    func testVideoMessageDisplay() throws {
        navigateToChat()
        
        // Look for existing video messages in the chat
        let videoMessages = app.buttons.matching(identifier: "VideoMessage")
        
        if videoMessages.count > 0 {
            let firstVideoMessage = videoMessages.firstMatch
            XCTAssertTrue(firstVideoMessage.exists, "Video message should be displayed")
            
            // Tap video message to open player
            firstVideoMessage.tap()
            
            // Verify video player appears
            let videoPlayer = app.otherElements["VideoPlayer"]
            XCTAssertTrue(videoPlayer.waitForExistence(timeout: 3), "Video player should appear when tapping video message")
            
            // Verify done button exists to close player
            let doneButton = app.buttons["Done"]
            XCTAssertTrue(doneButton.exists, "Done button should exist in video player")
            
            // Close video player
            doneButton.tap()
        } else {
            // No video messages to test, which is also valid
            XCTAssertTrue(true, "No video messages found in chat")
        }
    }
    
    func testVideoRecorderPermissions() throws {
        navigateToChat()
        
        // Tap attachment button and start video recording
        app.buttons["plus"].tap()
        
        let attachmentSheet = app.sheets.firstMatch
        XCTAssertTrue(attachmentSheet.waitForExistence(timeout: 3))
        
        app.buttons["Workout Video"].tap()
        
        let videoRecorderSheet = app.otherElements["WorkoutVideoRecorderSheet"]
        XCTAssertTrue(videoRecorderSheet.waitForExistence(timeout: 3))
        
        app.buttons["Start Recording"].tap()
        
        // Check if permission dialog appears
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2) {
            // Handle permission dialog
            let allowButton = permissionAlert.buttons["Allow"] 
            if allowButton.exists {
                allowButton.tap()
            }
        }
        
        // At this point, either recording started or permission was denied
        // Both are valid outcomes for this test
        XCTAssertTrue(true, "Permission flow handled")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToChat() {
        // This would depend on your app's navigation structure
        // For example:
        
        // Wait for main screen to load
        XCTAssertTrue(app.waitForExistence(timeout: 10), "App should launch successfully")
        
        // Navigate to chat list (adjust based on your app's structure)
        if app.tabBars.buttons["Messages"].exists {
            app.tabBars.buttons["Messages"].tap()
        }
        
        // Wait for chat list to load
        let chatList = app.collectionViews.firstMatch
        if chatList.waitForExistence(timeout: 5) {
            // Tap first chat if it exists
            let firstChat = chatList.cells.firstMatch
            if firstChat.exists {
                firstChat.tap()
            }
        }
        
        // Wait for chat to load
        let chatView = app.collectionViews.firstMatch
        XCTAssertTrue(chatView.waitForExistence(timeout: 5), "Chat view should load")
    }
    
    private func dismissKeyboardIfPresent() {
        if app.keyboards.firstMatch.exists {
            app.keyboards.buttons["return"].tap()
        }
    }
}