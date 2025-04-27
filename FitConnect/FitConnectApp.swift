//
//  FitConnectApp.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

@main
struct FitConnectApp: App {
    @StateObject var session = SessionStore()

    init() {
        FirebaseApp.configure()

        // ----------------------------------------
        // EMULATOR KODUNUN ÇALIŞTIĞINDAN EMİN OL
        Auth.auth().useEmulator(withHost: "127.0.0.1", port: 9099)
        var settings = Firestore.firestore().settings
        settings.host = "127.0.0.1:8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
        // ----------------------------------------

        print("🔌 Using Auth emulator at 127.0.0.1:9099")
        print("🔌 Using Firestore emulator at 127.0.0.1:8080")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
