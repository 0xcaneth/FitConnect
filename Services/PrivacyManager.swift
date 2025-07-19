import Foundation
import Firebase
import FirebaseAnalytics

class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    // MARK: - Privacy Settings Keys
    private enum PrivacyKeys {
        static let appUsage = "privacy_app_usage"
        static let workoutTracking = "privacy_workout_tracking"
        static let anonymousTracking = "privacy_anonymous_tracking"
        static let attPermissionGranted = "att_permission_granted"
        static let settingsInitialized = "privacy_settings_initialized"
        static let onboardingComplete = "privacy_onboarding_complete"
    }
    
    // MARK: - Published Properties
    @Published var appUsageTrackingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(appUsageTrackingEnabled, forKey: PrivacyKeys.appUsage)
            print("[PrivacyManager] 🔄 App Usage Tracking changed to: \(appUsageTrackingEnabled ? "ON" : "OFF")")
            configureAnalytics()
        }
    }
    
    @Published var workoutTrackingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(workoutTrackingEnabled, forKey: PrivacyKeys.workoutTracking)
            print("[PrivacyManager] 🔄 Workout Tracking changed to: \(workoutTrackingEnabled ? "ON" : "OFF")")
        }
    }
    
    @Published var anonymousTrackingEnabled: Bool {
        didSet {
            UserDefaults.standard.set(anonymousTrackingEnabled, forKey: PrivacyKeys.anonymousTracking)
            print("[PrivacyManager] 🔄 Anonymous Tracking changed to: \(anonymousTrackingEnabled ? "ON" : "OFF")")
        }
    }
    
    @Published var attPermissionGranted: Bool {
        didSet {
            UserDefaults.standard.set(attPermissionGranted, forKey: PrivacyKeys.attPermissionGranted)
        }
    }
    
    // MARK: - Computed Properties
    var isOnboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: PrivacyKeys.onboardingComplete)
    }
    
    private init() {
        // Initialize from UserDefaults or set defaults
        if UserDefaults.standard.bool(forKey: PrivacyKeys.settingsInitialized) {
            // Load existing settings
            self.appUsageTrackingEnabled = UserDefaults.standard.bool(forKey: PrivacyKeys.appUsage)
            self.workoutTrackingEnabled = UserDefaults.standard.bool(forKey: PrivacyKeys.workoutTracking)
            self.anonymousTrackingEnabled = UserDefaults.standard.bool(forKey: PrivacyKeys.anonymousTracking)
            self.attPermissionGranted = UserDefaults.standard.bool(forKey: PrivacyKeys.attPermissionGranted)
        } else {
            // Set privacy-friendly defaults for first-time users
            self.appUsageTrackingEnabled = false // Default OFF for privacy
            self.workoutTrackingEnabled = false  // Default OFF for privacy
            self.anonymousTrackingEnabled = false // Default OFF for privacy
            self.attPermissionGranted = false
            
            // Save defaults
            UserDefaults.standard.set(false, forKey: PrivacyKeys.appUsage)
            UserDefaults.standard.set(false, forKey: PrivacyKeys.workoutTracking)
            UserDefaults.standard.set(false, forKey: PrivacyKeys.anonymousTracking)
            UserDefaults.standard.set(false, forKey: PrivacyKeys.attPermissionGranted)
            UserDefaults.standard.set(true, forKey: PrivacyKeys.settingsInitialized)
        }
        
        // Configure analytics based on current settings
        configureAnalytics()
    }
    
    // MARK: - Analytics Control
    private func configureAnalytics() {
        // Configure Firebase Analytics based on user preference
        Analytics.setAnalyticsCollectionEnabled(appUsageTrackingEnabled)
        print("[PrivacyManager] 🔧 Firebase Analytics: \(appUsageTrackingEnabled ? "ENABLED" : "DISABLED")")
        
        #if DEBUG
        print("[PrivacyManager] [DEBUG] Analytics collection enabled: \(appUsageTrackingEnabled)")
        #endif
    }
    
    // MARK: - Event Tracking (Respects Privacy Settings)
    func trackEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Only track if user has opted in to app usage tracking
        guard appUsageTrackingEnabled else {
            print("[Privacy] ✋ Event tracking disabled: \(name) (App Usage Tracking is OFF)")
            return
        }
        
        // Send to Firebase Analytics
        Analytics.logEvent(name, parameters: parameters)
        print("[Analytics] ✅ Event tracked: \(name) with params: \(String(describing: parameters))")
    }
    
    func trackWorkoutEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Only track if user has opted in to workout tracking
        guard workoutTrackingEnabled else {
            print("[Privacy] ✋ Workout tracking disabled: \(name) (Workout Intelligence is OFF)")
            return
        }
        
        var sanitizedParams = parameters ?? [:]
        
        // Remove personal identifiers if anonymous tracking is disabled
        if !anonymousTrackingEnabled {
            sanitizedParams = sanitizeParameters(sanitizedParams)
        }
        
        Analytics.logEvent("workout_\(name)", parameters: sanitizedParams)
        print("[Analytics] ✅ Workout event tracked: workout_\(name)")
    }
    
    func trackCommunityEvent(_ name: String, parameters: [String: Any]? = nil) {
        // Only track if user has opted in to anonymous tracking
        guard anonymousTrackingEnabled else {
            print("[Privacy] ✋ Community tracking disabled: \(name) (Community Insights is OFF)")
            return
        }
        
        let sanitizedParams = sanitizeParameters(parameters ?? [:])
        
        Analytics.logEvent("community_\(name)", parameters: sanitizedParams)
        print("[Analytics] ✅ Community event tracked: community_\(name)")
    }
    
    // MARK: - Error Logging and Performance
    func recordError(_ error: Error, userInfo: [String: Any]? = nil) {
        // Only record errors if user has opted in to app usage tracking
        guard appUsageTrackingEnabled else {
            print("[Privacy] ✋ Error reporting disabled (App Usage Tracking is OFF)")
            return
        }
        
        let errorParams: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "user_info": userInfo as Any
        ]
        
        Analytics.logEvent("app_error", parameters: errorParams)
        print("[Analytics] ✅ Error recorded: \(error.localizedDescription)")
    }
    
    func trackPerformance(_ name: String, duration: TimeInterval? = nil) {
        guard appUsageTrackingEnabled else {
            print("[Privacy] ✋ Performance tracking disabled: \(name) (App Usage Tracking is OFF)")
            return
        }
        
        var params: [String: Any] = ["performance_name": name]
        if let duration = duration {
            params["duration_ms"] = Int(duration * 1000)
        }
        
        Analytics.logEvent("performance_metric", parameters: params)
        print("[Analytics] ✅ Performance tracked: \(name)")
    }
    
    // MARK: - Privacy Helpers
    private func sanitizeParameters(_ parameters: [String: Any]) -> [String: Any] {
        var sanitized = parameters
        
        // Remove common personal identifiers
        let keysToRemove = ["user_id", "email", "username", "device_id", "ip_address", "location", "phone_number", "full_name"]
        for key in keysToRemove {
            sanitized.removeValue(forKey: key)
        }
        
        // Also remove any value that looks like an email or phone number
        for (key, value) in sanitized {
            if let stringValue = value as? String {
                // Remove email-like values
                if stringValue.contains("@") && stringValue.contains(".") {
                    sanitized.removeValue(forKey: key)
                }
                // Remove phone-like values
                if stringValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression).count >= 10 {
                    sanitized.removeValue(forKey: key)
                }
            }
        }
        
        return sanitized
    }
    
    // MARK: - Public Methods
    func completeOnboarding() {
        // Prevent multiple completions
        guard !isOnboardingComplete else {
            print("[PrivacyManager] Onboarding already completed")
            return
        }
        
        UserDefaults.standard.set(true, forKey: PrivacyKeys.onboardingComplete)
        
        // Track onboarding completion (respects privacy settings)
        trackEvent("privacy_onboarding_complete", parameters: [
            "app_usage_enabled": appUsageTrackingEnabled,
            "workout_tracking_enabled": workoutTrackingEnabled,
            "anonymous_tracking_enabled": anonymousTrackingEnabled
        ])
    }
    
    func resetPrivacySettings() {
        appUsageTrackingEnabled = false
        workoutTrackingEnabled = false
        anonymousTrackingEnabled = false
        attPermissionGranted = false
        
        UserDefaults.standard.set(false, forKey: PrivacyKeys.onboardingComplete)
        
        configureAnalytics()
    }
    
    // MARK: - Settings Summary
    var privacySettingsSummary: String {
        var summary = "Privacy Settings:\n"
        summary += "• App Usage Tracking: \(appUsageTrackingEnabled ? "ON" : "OFF")\n"
        summary += "• Workout Intelligence: \(workoutTrackingEnabled ? "ON" : "OFF")\n"
        summary += "• Community Insights: \(anonymousTrackingEnabled ? "ON" : "OFF")\n"
        summary += "• iOS ATT Permission: \(attPermissionGranted ? "Granted" : "Denied")"
        return summary
    }
    
    // MARK: - Debug Helper
    func printCurrentStatus() {
        print("=== PRIVACY MANAGER STATUS ===")
        print(privacySettingsSummary)
        print("Onboarding Complete: \(isOnboardingComplete)")
        print("==============================")
    }
    
    // MARK: - Manual Toggle Functions (for debugging)
    func toggleAppUsage() {
        print("🔄 [MANUAL] Toggling App Usage from \(appUsageTrackingEnabled) to \(!appUsageTrackingEnabled)")
        appUsageTrackingEnabled.toggle()
    }
    
    func toggleWorkoutTracking() {
        print("🔄 [MANUAL] Toggling Workout from \(workoutTrackingEnabled) to \(!workoutTrackingEnabled)")
        workoutTrackingEnabled.toggle()
    }
    
    func toggleAnonymousTracking() {
        print("🔄 [MANUAL] Toggling Anonymous from \(anonymousTrackingEnabled) to \(!anonymousTrackingEnabled)")
        anonymousTrackingEnabled.toggle()
    }
    
}

// MARK: - Convenience Extensions (OUTSIDE of class)
extension PrivacyManager {
    // Common event tracking methods that respect privacy settings
    
    func trackScreenView(_ screenName: String) {
        trackEvent("screen_view", parameters: ["screen_name": screenName])
    }
    
    func trackButtonTap(_ buttonName: String, screen: String) {
        trackEvent("button_tap", parameters: [
            "button_name": buttonName,
            "screen": screen
        ])
    }
    
    func trackWorkoutStarted(type: String, duration: TimeInterval? = nil) {
        var params: [String: Any] = ["workout_type": type]
        if let duration = duration {
            params["planned_duration"] = Int(duration)
        }
        
        trackWorkoutEvent("workout_started", parameters: params)
    }
    
    func trackWorkoutCompleted(type: String, duration: TimeInterval, caloriesBurned: Double? = nil) {
        var params: [String: Any] = [
            "workout_type": type,
            "duration": Int(duration)
        ]
        
        if let calories = caloriesBurned {
            params["calories_burned"] = Int(calories)
        }
        
        trackWorkoutEvent("workout_completed", parameters: params)
    }
    
    func trackCommunityPostCreated() {
        trackCommunityEvent("community_post_created", parameters: [
            "timestamp": Int(Date().timeIntervalSince1970)
        ])
    }
    
    func trackCommunityPostLiked() {
        trackCommunityEvent("community_post_liked")
    }
    
    func trackCommunityPostShared() {
        trackCommunityEvent("community_post_shared")
    }
    
    func trackCommunityCommentAdded() {
        trackCommunityEvent("community_comment_added")
    }
    
    // MARK: - App Flow Tracking
    func trackAppLaunch() {
        trackEvent("app_launch")
    }
    
    func trackUserLogin(method: String) {
        trackEvent("user_login", parameters: ["method": method])
    }
    
    func trackUserSignup(method: String) {
        trackEvent("user_signup", parameters: ["method": method])
    }
    
    func trackFeatureUsed(_ featureName: String) {
        trackEvent("feature_used", parameters: ["feature": featureName])
    }
}