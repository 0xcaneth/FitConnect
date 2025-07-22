import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseInstallations
import UserNotifications

@main
@available(iOS 16.0, *)
struct FitConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var session: SessionStore
    @StateObject private var healthKitManager: HealthKitManager
    @StateObject private var postService = PostService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    init() {
        print("🔧 FitConnectApp initializing...")
        
        // Add crash detection
        NSSetUncaughtExceptionHandler { exception in
            print("🚨 UNCAUGHT EXCEPTION: \(exception)")
            print("🚨 Stack trace: \(exception.callStackSymbols)")
        }
        
        // CRITICAL: Configure Firebase FIRST before ANY Firebase-related objects
        Self.configureFirebaseWithErrorHandling()
        
        // Only after Firebase is configured, create SessionStore with defensive initialization
        let sessionStore = SessionStore()
        _session = StateObject(wrappedValue: sessionStore)
        _healthKitManager = StateObject(wrappedValue: HealthKitManager(sessionStore: sessionStore))
        
        // Configure PostService
        PostService.shared.configure(sessionStore: sessionStore)
        
        print("✅ FitConnectApp initialized successfully")
    }
    
    private static func configureFirebaseWithErrorHandling() {
        print("🔧 Configuring Firebase with error handling...")
        
        // Check if already configured
        if FirebaseApp.app() != nil {
            print("ℹ️ Firebase already configured")
            return
        }
        
        do {
            // Configure Firebase with error handling
            FirebaseApp.configure()
            print("✅ Firebase configured successfully")
            
            // Only configure Firestore if Firebase configuration succeeded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                configureFirestore()
            }
            
        } catch let error {
            print("❌ CRITICAL: Firebase configuration failed: \(error.localizedDescription)")
            // Log the error but don't crash - app can still work in limited mode
            print("⚠️ App will continue in limited mode without Firebase services")
        }
    }
    
    private static func configureFirestore() {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Cannot configure Firestore - Firebase not initialized")
            return
        }
        
        do {
            let db = Firestore.firestore()
            let settings = FirestoreSettings()
            settings.isPersistenceEnabled = true
            settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
            
            db.settings = settings
            print("✅ Firestore configured with offline persistence")
            
        } catch let error {
            print("❌ Firestore configuration failed: \(error.localizedDescription)")
            print("⚠️ Continuing without optimized Firestore settings")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(healthKitManager)
                .environmentObject(postService)
                .environmentObject(networkMonitor)
                .onAppear {
                    print("🚀 FitConnectApp body appeared")
                }
                .onReceive(networkMonitor.$isConnected) { isConnected in
                    // Only process network changes after monitor has initialized
                    guard networkMonitor.hasInitialized else { return }
                    
                    if isConnected {
                        print("📡 Network connection restored")
                        // Attempt to retry Firebase operations if they failed initially
                        if session.globalError?.contains("network") == true || session.globalError?.contains("connection") == true {
                            session.clearGlobalError()
                        }
                    } else {
                        print("📡 Network connection lost")
                        session.setGlobalError("No internet connection. Some features may be limited.")
                    }
                }
        }
    }
}