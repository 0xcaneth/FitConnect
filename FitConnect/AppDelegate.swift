import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("🔧 AppDelegate configuring...")
        
        // Firebase is configured in FitConnectApp.init() BEFORE this runs
        // We just verify it's configured and proceed with other setup
        if FirebaseApp.app() != nil {
            print("✅ Firebase already configured by FitConnectApp")
        } else {
            print("⚠️ Firebase not configured yet - this should not happen")
            // Emergency fallback - configure Firebase here
            FirebaseApp.configure()
        }
        
        // Configure app settings
        configureAppSettings()
        
        return true
    }
    
    private func configureAppSettings() {
        // Disable idle timer for better user experience during workouts
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Set up appearance
        configureAppAppearance()
    }
    
    private func configureAppAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0) // FitConnect dark background
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
    
    // Handle URL schemes for deep linking
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle Firebase Auth URL schemes
        if Auth.auth().canHandle(url) {
            return true
        }
        
        // Handle other URL schemes
        return false
    }
    
    // Handle notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set APNS token for Firebase Messaging if you're using FCM
        // Messaging.messaging().apnsToken = deviceToken
        print("✅ Successfully registered for remote notifications")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}