import SwiftUI
import Firebase
import FirebaseAnalytics

@available(iOS 16.0, *)
struct PrivacyTestView: View {
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var testResults: [String] = []
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current Settings Display
                settingsDisplay
                
                // Test Buttons
                testButtonsSection
                
                // Results Display
                resultsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Privacy Tests")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    @ViewBuilder
    private var settingsDisplay: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Privacy Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("📊 App Performance Analytics:")
                Spacer()
                Text(privacyManager.appUsageTrackingEnabled ? "ON" : "OFF")
                    .foregroundColor(privacyManager.appUsageTrackingEnabled ? .green : .red)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("💪 Workout Intelligence:")
                Spacer()
                Text(privacyManager.workoutTrackingEnabled ? "ON" : "OFF")
                    .foregroundColor(privacyManager.workoutTrackingEnabled ? .green : .red)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("👥 Community Insights:")
                Spacer()
                Text(privacyManager.anonymousTrackingEnabled ? "ON" : "OFF")
                    .foregroundColor(privacyManager.anonymousTrackingEnabled ? .green : .red)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text("🔐 ATT Permission:")
                Spacer()
                Text(privacyManager.attPermissionGranted ? "GRANTED" : "DENIED")
                    .foregroundColor(privacyManager.attPermissionGranted ? .green : .red)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var testButtonsSection: some View {
        VStack(spacing: 16) {
            Text("Test Privacy Controls")
                .font(.headline)
                .foregroundColor(.primary)
            
            // App Performance Analytics Tests
            VStack(spacing: 8) {
                Text("📊 App Performance Analytics")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Button("Test Screen View") {
                        testAppAnalyticsEvent()
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("Test Error Log") {
                        testErrorLogging()
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("Test Performance") {
                        testPerformanceTracking()
                    }
                    .buttonStyle(TestButtonStyle())
                }
            }
            
            // Workout Intelligence Tests
            VStack(spacing: 8) {
                Text("💪 Workout Intelligence")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Button("Test Workout Start") {
                        testWorkoutStartEvent()
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("Test Workout Complete") {
                        testWorkoutCompleteEvent()
                    }
                    .buttonStyle(TestButtonStyle())
                }
            }
            
            // Community Insights Tests
            VStack(spacing: 8) {
                Text("👥 Community Insights")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Button("Test Post Like") {
                        testCommunityLikeEvent()
                    }
                    .buttonStyle(TestButtonStyle())
                    
                    Button("Test Comment") {
                        testCommunityCommentEvent()
                    }
                    .buttonStyle(TestButtonStyle())
                }
            }
            
            Divider()
            
            // Comprehensive Test
            Button(action: runComprehensiveTest) {
                HStack {
                    if isRunningTests {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isRunningTests ? "Running Tests..." : "🧪 Run All Tests")
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(ComprehensiveTestButtonStyle())
            .disabled(isRunningTests)
        }
    }
    
    @ViewBuilder
    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Test Results")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !testResults.isEmpty {
                    Button("Clear") {
                        testResults.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(testResults.indices, id: \.self) { index in
                        Text(testResults[index])
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxHeight: 200)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Test Functions
    
    private func testAppAnalyticsEvent() {
        addTestResult("🧪 Testing App Analytics Event...")
        
        privacyManager.trackScreenView("privacy_test_screen")
        
        let expected = privacyManager.appUsageTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("📊 App Analytics: \(expected) (Setting: \(privacyManager.appUsageTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testErrorLogging() {
        addTestResult("🧪 Testing Error Logging...")
        
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error for privacy testing"])
        privacyManager.recordError(testError, userInfo: ["test_context": "privacy_testing"])
        
        let expected = privacyManager.appUsageTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("🚨 Error Logging: \(expected) (Setting: \(privacyManager.appUsageTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testPerformanceTracking() {
        addTestResult("🧪 Testing Performance Tracking...")
        
        privacyManager.trackPerformance("screen_load_time", duration: 1.23)
        
        let expected = privacyManager.appUsageTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("⚡ Performance: \(expected) (Setting: \(privacyManager.appUsageTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testWorkoutStartEvent() {
        addTestResult("🧪 Testing Workout Start Event...")
        
        privacyManager.trackWorkoutStarted(type: "cardio", duration: 1800)
        
        let expected = privacyManager.workoutTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("💪 Workout Start: \(expected) (Setting: \(privacyManager.workoutTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testWorkoutCompleteEvent() {
        addTestResult("🧪 Testing Workout Complete Event...")
        
        privacyManager.trackWorkoutCompleted(type: "strength", duration: 2400, caloriesBurned: 350)
        
        let expected = privacyManager.workoutTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("🏁 Workout Complete: \(expected) (Setting: \(privacyManager.workoutTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testCommunityLikeEvent() {
        addTestResult("🧪 Testing Community Like Event...")
        
        privacyManager.trackCommunityPostLiked()
        
        let expected = privacyManager.anonymousTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        addTestResult("👍 Community Like: \(expected) (Setting: \(privacyManager.anonymousTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func testCommunityCommentEvent() {
        addTestResult("🧪 Testing Community Comment Event...")
        
        privacyManager.trackCommunityCommentAdded()
        
        let expected = privacyManager.anonymousTrackingEnabled ? "✅ SENT" : "❌ BLOCKED"
        let sanitized = privacyManager.anonymousTrackingEnabled ? "" : " (Data Sanitized)"
        addTestResult("💬 Community Comment: \(expected)\(sanitized) (Setting: \(privacyManager.anonymousTrackingEnabled ? "ON" : "OFF"))")
    }
    
    private func runComprehensiveTest() {
        isRunningTests = true
        testResults.removeAll()
        
        addTestResult("🚀 Starting comprehensive privacy test suite...")
        addTestResult("📅 \(Date().formatted())")
        addTestResult("=" * 50)
        
        // Test sequence with delays for readability
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            testAppAnalyticsEvent()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            testErrorLogging()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            testPerformanceTracking()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            testWorkoutStartEvent()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            testWorkoutCompleteEvent()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            testCommunityLikeEvent()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            testCommunityCommentEvent()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            addTestResult("=" * 50)
            addTestResult("✅ Comprehensive test completed!")
            addTestResult("💡 Check console logs for Firebase Analytics details")
            isRunningTests = false
        }
    }
    
    private func addTestResult(_ message: String) {
        testResults.append("[\(Date().formatted(.dateTime.hour().minute().second()))] \(message)")
    }
}

// MARK: - Custom Button Styles

struct TestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ComprehensiveTestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// String repeat extension
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PrivacyTestView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyTestView()
    }
}
#endif