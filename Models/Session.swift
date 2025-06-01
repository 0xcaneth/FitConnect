// SessionStore.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// ObservableObject that publishes the currently signed-in user (or nil).
final class SessionStore: ObservableObject {
  @Published var isLoggedIn = false
  @Published var role: String = ""
  @Published var currentUserId: String = ""
  @Published var assignedDietitianId: String = ""
  @Published var currentUser: User?

  private var authStateListener: AuthStateDidChangeListenerHandle?

  init() {
    listenForAuthState()
  }

  init(forPreview: Bool = false, isLoggedIn: Bool = true, role: String = "Client", userId: String = "previewUserID", dietitianId: String = "previewDietitianID") {
    if forPreview {
        self.isLoggedIn = isLoggedIn
        self.role = role
        self.currentUserId = userId
        self.assignedDietitianId = dietitianId
        // For preview, currentUser can be nil or a mock User object
        // self.currentUser = User(uid: userId, email: "preview@example.com", displayName: "Preview User") // Example, if User struct exists
        self.currentUser = nil // Or keep it simple
    } else {
        listenForAuthState()
    }
  }

  func listenForAuthState() {
    authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
      DispatchQueue.main.async {
        if let user = user {
          // User is logged in, fetch Firestore document
          let uid = user.uid
          self?.currentUser = user

          Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
              if let data = snapshot?.data(),
                 let role = data["role"] as? String {
                self?.currentUserId = uid
                self?.role = role
                self?.assignedDietitianId = data["assignedDietitianId"] as? String ?? ""
                self?.isLoggedIn = true
              } else {
                // Firestore doc missing or role missing: force sign out
                try? Auth.auth().signOut()
                self?.resetSession()
              }
            }
          }
        } else {
          // User is signed out
          self?.resetSession()
        }
      }
    }
  }

  private func resetSession() {
    isLoggedIn = false
    role = ""
    currentUserId = ""
    assignedDietitianId = ""
    currentUser = nil
  }

  func signOut() throws {
    try Auth.auth().signOut()
    resetSession()
  }

  deinit {
    if let listener = authStateListener {
      Auth.auth().removeStateDidChangeListener(listener)
    }
  }
}
