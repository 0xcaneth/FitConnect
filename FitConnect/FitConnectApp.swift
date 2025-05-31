import SwiftUI
import Firebase
import FirebaseAuth

@available(iOS 14.0, *)
@main
struct FitConnectApp: App {
  @StateObject private var session = SessionStore()

  init() {
    // 1) Firebase'i gerçek projenize karşı başlat
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(session)  // ← Burada ekli
    }
  }
}
