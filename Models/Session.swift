import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import Combine

/// ObservableObject that publishes the currently signed-in user (or nil).
final class SessionStore: ObservableObject {
  @Published var isLoggedIn = false
  @Published var isLoadingUser = false
  @Published var role: String = ""
  @Published var currentUserId: String?
  @Published var assignedDietitianId: String = ""
  @Published var currentUser: FitConnectUser?
  @Published var unreadNotificationCount: Int = 0
  @Published var userPreferences: UserPreferences = .default
  @Published var globalError: String? = nil
  @Published var isInitializing: Bool = true
  
  private var authStateListener: AuthStateDidChangeListenerHandle?
  private var notificationListener: ListenerRegistration?

  var isAuthenticated: Bool {
    return currentUserId != nil && isLoggedIn
  }

  var isReadyForNavigation: Bool {
    return !isLoadingUser && isLoggedIn
  }

  var currentUserRole: String? {
    return role.isEmpty ? nil : role
  }

  var userRole: UserRole? {
    return UserRole(rawValue: role)
  }
  
  var isDietitian: Bool {
    return userRole == .dietitian
  }
  
  var isClient: Bool {
    return userRole == .client
  }

  init() {
    print("[SessionStore] Initializing SessionStore...")
    
    // CRITICAL: Ensure Firebase is configured before accessing Auth
    guard FirebaseApp.app() != nil else {
      print("[SessionStore] FATAL: Firebase not configured!")
      fatalError("Firebase must be configured before SessionStore initialization")
    }
    
    setupAuthStateListener()
  }

  private func setupAuthStateListener() {
    print("[SessionStore] Setting up auth state listener...")
    
    // IMPORTANT: Remove existing listener first if it exists
    if let existingListener = authStateListener {
        Auth.auth().removeStateDidChangeListener(existingListener)
        authStateListener = nil
        print("[SessionStore] Removed existing auth state listener")
    }
    
    // Wait a tiny bit to ensure Firebase is fully ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      
      do {
        self.authStateListener = Auth.auth().addStateDidChangeListener { [weak self] auth, firebaseAuthUser in
          guard let self = self else { return }
          
          DispatchQueue.main.async {
            self.isInitializing = false
            
            if let fbUser = firebaseAuthUser {
              print("[SessionStore] Auth state changed: User signed in (\(fbUser.uid))")
              self.handleAuthenticatedUser(fbUser)
            } else {
              print("[SessionStore] Auth state changed: No authenticated user")
              self.resetSession()
            }
          }
        }
        print("[SessionStore] Auth state listener configured successfully")
      } catch {
        print("[SessionStore] Failed to setup auth listener: \(error)")
        DispatchQueue.main.async {
          self.isInitializing = false
          self.resetSession()
        }
      }
    }
  }
  
  private func handleAuthenticatedUser(_ firebaseUser: User) {
    let uid = firebaseUser.uid
    print("[SessionStore] Authenticated user: \(uid), email verified: \(firebaseUser.isEmailVerified)")
    
    self.isLoadingUser = true
    self.currentUserId = uid
    
    // Create a basic user first, then enhance with Firestore data
    let basicUser = FitConnectUser(
        id: uid,
        email: firebaseUser.email ?? "",
        fullName: firebaseUser.displayName ?? "User",
        isEmailVerified: firebaseUser.isEmailVerified,
        createdAt: Timestamp(date: firebaseUser.metadata.creationDate ?? Date())
    )
    
    // CRITICAL: Remove premature updateData call - wait until user is fetched
    
    // Fetch complete user data from Firestore with retry logic
    fetchUserFromFirestore(uid: uid, fallbackUser: basicUser) { [weak self] user in
      guard let self = self else { return }
      
      DispatchQueue.main.async {
        self.currentUser = user
        self.role = user.role
        self.assignedDietitianId = user.assignedDietitianId ?? ""
        
        print("[SessionStore] User fully loaded - Role: '\(self.role)', Logged in: \(self.isLoggedIn)")
        
        // CRITICAL: Set isLoggedIn = true ONLY after role is determined
        self.isLoggedIn = true
        self.isLoadingUser = false
        
        print("[SessionStore] Navigation ready - Role: '\(self.role)', Logged in: \(self.isLoggedIn)")
        
        // Setup other services after user is fully loaded
        self.setupNotificationListener()
        
        // NOW update lastOnline after user document is confirmed to exist
        self.updateLastOnline()
        
        Task {
          await PreferenceService.shared.fetchPreferences(for: user.id ?? "")
        }
      }
    }
  }
  
  private func fetchUserFromFirestore(uid: String, fallbackUser: FitConnectUser, completion: @escaping (FitConnectUser) -> Void) {
    let db = Firestore.firestore()
    
    // Retry logic for handling signup race conditions
    func attemptFetch(retryCount: Int = 0, maxRetries: Int = 5) {
        let delay = Double(retryCount) * 0.5 // Exponential backoff: 0, 0.5, 1.0, 1.5, 2.0 seconds
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            print("[SessionStore] Fetching user document (attempt \(retryCount + 1)/\(maxRetries + 1))...")
            
            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("[SessionStore] Error fetching user from Firestore: \(error.localizedDescription)")
                    
                    if retryCount < maxRetries {
                        print("[SessionStore] Retrying fetch in \(delay + 0.5) seconds...")
                        attemptFetch(retryCount: retryCount + 1, maxRetries: maxRetries)
                        return
                    }
                    
                    // Final fallback after all retries
                    print("[SessionStore] All fetch attempts failed. Using fallback with client role.")
                    var fallback = fallbackUser
                    fallback.role = "client"
                    completion(fallback)
                    return
                }
                
                guard let document = snapshot, document.exists else {
                    print("[SessionStore] User document not found (attempt \(retryCount + 1)).")
                    
                    if retryCount < maxRetries {
                        print("[SessionStore] Document may not be propagated yet. Retrying in \(delay + 0.5) seconds...")
                        attemptFetch(retryCount: retryCount + 1, maxRetries: maxRetries)
                        return
                    }
                    
                    print("[SessionStore] Document not found after all retries. Using fallback with client role.")
                    var fallback = fallbackUser
                    fallback.role = "client"
                    completion(fallback)
                    return
                }
                
                print("[SessionStore] Raw Firestore document data: \(document.data() ?? [:])")
                
                do {
                    var user = try document.data(as: FitConnectUser.self)
                    user.id = uid
                    user.isEmailVerified = fallbackUser.isEmailVerified
                    
                    print("[SessionStore] User decoded from Firestore - Role: '\(user.role)'")
                    completion(user)
                    
                } catch {
                    print("[SessionStore] Error decoding user from Firestore: \(error.localizedDescription)")
                    
                    if retryCount < maxRetries {
                        print("[SessionStore] Decode error, retrying in \(delay + 0.5) seconds...")
                        attemptFetch(retryCount: retryCount + 1, maxRetries: maxRetries)
                        return
                    }
                    
                    // Final fallback after all retries
                    print("[SessionStore] Decode failed after all retries. Using fallback with client role.")
                    var fallback = fallbackUser
                    fallback.role = "client"
                    completion(fallback)
                }
            }
        }
    }
    
    // Start the fetch with retry logic
    attemptFetch()
  }

  private func resetSession() {
    print("[SessionStore] Resetting session state...")
    
    // Reset all published properties
    isLoggedIn = false
    isLoadingUser = false
    role = ""
    currentUserId = nil
    assignedDietitianId = ""
    currentUser = nil
    userPreferences = .default
    globalError = nil
    unreadNotificationCount = 0
    isInitializing = false
    
    // Remove notification listener if still active
    removeNotificationListener()
    
    print("[SessionStore] Session reset completed")
  }

  func signOut() {
    print("[SessionStore] Starting SessionStore sign out...")
    
    // First, remove listeners to prevent interference
    removeNotificationListener()
    
    do {
        // Sign out through AuthService (which handles Firebase + Google)
        try AuthService.shared.signOut()
        print("[SessionStore] AuthService sign out successful")
        
    } catch {
        print("[SessionStore] AuthService sign out error: \(error.localizedDescription)")
        // Continue with session reset even if sign out fails
    }
    
    // Always reset the session state (including isLoadingUser)
    resetSession()
    
    print("[SessionStore] SessionStore sign out completed")
  }

  func updateLastOnline() {
    guard let uid = currentUserId, !uid.isEmpty else { return }
    
    let userRef = Firestore.firestore().collection("users").document(uid)
    userRef.updateData(["lastOnline": FieldValue.serverTimestamp()]) { error in
        if let error = error {
            print("[SessionStore] Error updating lastOnline: \(error.localizedDescription)")
        } else {
            print("[SessionStore] Last online timestamp updated")
        }
    }
  }

  func setupNotificationListener() {
      guard let userId = self.currentUserId, !userId.isEmpty else {
          print("[SessionStore] Cannot setup notification listener: userId is nil or empty.")
          return
      }
      
      removeNotificationListener()
      
      let db = Firestore.firestore()
      notificationListener = db.collection("notifications")
          .whereField("userId", isEqualTo: userId)
          .whereField("isRead", isEqualTo: false)
          .addSnapshotListener { [weak self] querySnapshot, error in
              guard let self = self else { return }
              
              DispatchQueue.main.async {
                if let error = error {
                    print("[SessionStore] Error listening for notifications: \(error.localizedDescription)")
                    self.unreadNotificationCount = 0
                    return
                }
                
                self.unreadNotificationCount = querySnapshot?.documents.count ?? 0
                print("[SessionStore] Unread notifications: \(self.unreadNotificationCount)")
              }
          }
      print("[SessionStore] Notification listener setup for user: \(userId)")
  }
  
  func removeNotificationListener() {
      notificationListener?.remove()
      notificationListener = nil
      unreadNotificationCount = 0
  }

  func clearGlobalError() {
    DispatchQueue.main.async {
        self.globalError = nil
    }
  }

  func setGlobalError(_ message: String) {
    DispatchQueue.main.async {
        self.globalError = message
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.globalError == message {
                self.clearGlobalError()
            }
        }
    }
  }

  deinit {
    print("[SessionStore] Deinitializing...")
    
    // Remove auth state listener
    if let listener = authStateListener {
      Auth.auth().removeStateDidChangeListener(listener)
      authStateListener = nil
      print("[SessionStore] Auth state listener removed in deinit")
    }
    
    // Remove notification listener
    removeNotificationListener()
    
    print("[SessionStore] Deinitialized")
  }

  static func previewStore(isLoggedIn: Bool = true, role: String = "client", unreadNotifications: Int = 0) -> SessionStore {
      let store = SessionStore()
      
      if let handle = store.authStateListener {
          Auth.auth().removeStateDidChangeListener(handle)
          store.authStateListener = nil
      }
      store.removeNotificationListener()

      store.isLoggedIn = isLoggedIn
      if isLoggedIn {
          var previewUser = FitConnectUser(id: "previewUserID", email: "preview@example.com", fullName: "Preview User", createdAt: Timestamp(date: Date())) 
          previewUser.xp = 100
          previewUser.isEmailVerified = true
          previewUser.role = role

          store.currentUser = previewUser
          store.currentUserId = "previewUserID"
          store.role = role
      } else {
          store.currentUser = nil
          store.currentUserId = nil
          store.role = ""
      }
      store.unreadNotificationCount = unreadNotifications
      
      return store
  }
}