// SessionStore.swift
import Foundation
import FirebaseAuth
import Combine

/// ObservableObject that publishes the currently signed-in user (or nil).
final class SessionStore: ObservableObject {
  @Published var currentUser: User?

  private var handle: AuthStateDidChangeListenerHandle?

  init() {
    listen()
  }

  deinit {
    stop()
  }

  /// Start listening for auth changes.
  func listen() {
    handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.currentUser = user
    }
  }

  /// Stop listening.
  func stop() {
    if let h = handle {
      Auth.auth().removeStateDidChangeListener(h)
    }
  }

  /// Sign out the current user.
  func signOut() throws {
    try Auth.auth().signOut()
  }
}
