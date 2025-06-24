import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

@main
@available(iOS 16.0, *)
struct FitConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var session: SessionStore
    @StateObject private var healthKitManager: HealthKitManager
    @StateObject private var postService = PostService.shared

    init() {
        print("🔧 FitConnectApp initializing...")
        
        // CRITICAL: Configure Firebase FIRST before ANY Firebase-related objects
        Self.configureFirebaseSync()
        
        // Only after Firebase is configured, create SessionStore
        let sessionStore = SessionStore()
        _session = StateObject(wrappedValue: sessionStore)
        _healthKitManager = StateObject(wrappedValue: HealthKitManager(sessionStore: sessionStore))
        
        // Configure PostService
        PostService.shared.configure(sessionStore: sessionStore)
        
        print("✅ FitConnectApp initialized successfully")
    }
    
    private static func configureFirebaseSync() {
        print("🔧 Configuring Firebase synchronously...")
        
        // Check if already configured
        if FirebaseApp.app() != nil {
            print("ℹ️ Firebase already configured")
            return
        }
        
        do {
            // Configure Firebase synchronously
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
            
            // Configure Firestore settings with error handling
            let db = Firestore.firestore()
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
            
            db.settings = settings
            print("✅ Firestore configured with offline persistence")
            
        } catch {
            print("❌ Firebase configuration failed: \(error.localizedDescription)")
            // Continue without crashing - Firebase will work without some features
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(healthKitManager)
                .environmentObject(postService)
                .onAppear {
                    print("🚀 FitConnectApp body appeared")
                }
        }
    }
}