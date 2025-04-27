import FirebaseAuth
import Combine

class SessionStore: ObservableObject {
  @Published var user: FirebaseAuth.User? = nil
  private var handle: AuthStateDidChangeListenerHandle?

  init() {
    listen()
  }

  func listen() {
    handle = Auth.auth().addStateDidChangeListener { _, user in
      self.user = user
    }
  }

  deinit {
    if let h = handle {
      Auth.auth().removeStateDidChangeListener(h)
    }
  }
}
