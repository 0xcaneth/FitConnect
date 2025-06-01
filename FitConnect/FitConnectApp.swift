import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn

@main
struct FitConnectApp: App {
  @StateObject private var session = SessionStore()
  @StateObject private var healthKitManager = HealthKitManager()

  init() {
    // 1) Firebase'i gerçek projenize karşı başlat
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(session)  // ← Burada ekli
        .environmentObject(healthKitManager)
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if !healthKitManager.permissionStatusDetermined && !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization { success, error in
                    if success {
                        print("HealthKit authorized from App launch.")
                    } else {
                        print("HealthKit authorization failed from App launch: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            } else if healthKitManager.isAuthorized {
                healthKitManager.fetchAllTodayData()
            }
        }
    }
  }
}
