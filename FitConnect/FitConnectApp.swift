// FitConnectApp.swift
import SwiftUI
import Firebase           // Core + Auth + Firestore vs.
import FirebaseAuth
import FirebaseAppCheck   // (opsiyonel, App Check kullanacaksan)

@main
struct FitConnectApp: App {
  @StateObject private var session = SessionStore()

  init() {
    // 1) Firebase'i gerçek projenize karşı başlat
    FirebaseApp.configure()

    // 2) Eğer App Check kullanacaksan (development modda hata alıyorsan)
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())

    // 3) (Üretime geçince bu emulator satırlarını tamamen sil)
    // Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
    // let settings = Firestore.firestore().settings
    // settings.host = "127.0.0.1:8080"
    // settings.isSSLEnabled = false
    // Firestore.firestore().settings = settings

    // DEBUG: isteğe bağlı önceki oturumu temizle
    try? Auth.auth().signOut()
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(session)  // ← Burada ekli
    }
  }
}
