import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private init() {}
    
    // MARK: - Email/Password Authentication
    
    func signUp(email: String, password: String, fullName: String, role: String = "client") async throws {
        print("[AuthService] Starting signUp with role: \(role)")
        isLoading = true
        errorMessage = nil
        
        do {
            // Create Firebase Auth user
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            print("[AuthService] Firebase Auth user created with UID: \(user.uid)")
            
            // Send email verification
            try await user.sendEmailVerification()
            print("[AuthService] Email verification sent")
            
            // Create Firestore user document with explicit role
            let userData: [String: Any] = [
                "email": email,
                "fullName": fullName,
                "role": role, 
                "isEmailVerified": false,
                "createdAt": FieldValue.serverTimestamp(),
                "lastOnline": FieldValue.serverTimestamp(),
                "xp": 0,
                "level": 1,
                "profileImageUrl": "",
                "assignedDietitianId": role == "client" ? "" : nil
            ]
            
            print("[AuthService] Writing to Firestore with userData: \(userData)")
            
            // CRITICAL: Wait for Firestore write to complete before returning
            try await Firestore.firestore().collection("users").document(user.uid).setData(userData)
            
            print("[AuthService] User document created successfully with role = \(role)")
            
            // Additional delay to ensure Firestore propagation
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            print("[AuthService] Firestore propagation delay completed")
            isLoading = false
            
        } catch {
            print("[AuthService] Error during signUp: \(error.localizedDescription)")
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    func signIn(email: String, password: String, expectedRole: UserRole) async throws {
        print("[AuthService] Starting role-aware signIn for email: \(email), expected role: \(expectedRole.rawValue)")
        isLoading = true
        errorMessage = nil
        
        do {
            // CRITICAL: Ensure we're completely signed out first
            if Auth.auth().currentUser != nil {
                print("[AuthService] Existing user found, signing out first...")
                try Auth.auth().signOut()
                // Add a small delay to ensure complete sign out
                try await Task.sleep(nanoseconds: 500_000_000) 
            }
            
            // Now perform fresh sign in
            print("[AuthService] Performing fresh sign in...")
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = result.user
            
            print("[AuthService] Auth.signIn completed for UID: \(user.uid)")
            
            // Check if email is verified
            if !user.isEmailVerified {
                print("[AuthService] Email not verified for user: \(email)")
                // Sign out the unverified user
                try Auth.auth().signOut()
                throw AuthError.emailNotVerified
            }
            
            // Fetch user data from Firestore to validate role
            let userDoc = try await Firestore.firestore().collection("users").document(user.uid).getDocument()
            
            guard userDoc.exists, let userData = userDoc.data() else {
                print("[AuthService] User data not found in Firestore")
                try Auth.auth().signOut()
                throw AuthError.userDataNotFound
            }
            
            guard let userRoleString = userData["role"] as? String else {
                print("[AuthService] Invalid role data in Firestore")
                try Auth.auth().signOut()
                throw AuthError.invalidUserRole
            }
            
            guard let userRole = UserRole(rawValue: userRoleString) else {
                print("[AuthService] Unknown role value: \(userRoleString)")
                try Auth.auth().signOut()
                throw AuthError.invalidUserRole
            }
            
            // Validate role matches expected role
            if userRole != expectedRole {
                print("[AuthService] Role mismatch - User role: \(userRole.rawValue), Expected: \(expectedRole.rawValue)")
                try Auth.auth().signOut()
                throw AuthError.roleMismatch(correctRole: userRole)
            }
            
            // Update last online in Firestore
            do {
                try await Firestore.firestore().collection("users").document(user.uid).updateData([
                    "lastOnline": FieldValue.serverTimestamp()
                ])
                print("[AuthService] Last online timestamp updated")
            } catch {
                print("[AuthService] Failed to update last online: \(error.localizedDescription)")
                // Don't throw - this is not critical for login
            }
            
            print("[AuthService] User signed in successfully with correct role: \(userRole.rawValue)")
            isLoading = false
            
        } catch {
            print("[AuthService] Error during signIn: \(error.localizedDescription)")
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            
            // Ensure we're signed out on error
            try? Auth.auth().signOut()
            throw error
        }
    }
    
    // KEEP: Original signIn method for backward compatibility
    func signIn(email: String, password: String) async throws {
        print("[AuthService] Starting signIn for email: \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            // CRITICAL: Ensure we're completely signed out first
            if Auth.auth().currentUser != nil {
                print("[AuthService] Existing user found, signing out first...")
                try Auth.auth().signOut()
                // Add a small delay to ensure complete sign out
                try await Task.sleep(nanoseconds: 500_000_000) 
            }
            
            // Now perform fresh sign in
            print("[AuthService] Performing fresh sign in...")
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let user = result.user
            
            print("[AuthService] Auth.signIn completed for UID: \(user.uid)")
            
            // Check if email is verified
            if !user.isEmailVerified {
                print("[AuthService] Email not verified for user: \(email)")
                // Sign out the unverified user
                try Auth.auth().signOut()
                throw AuthError.emailNotVerified
            }
            
            // Update last online in Firestore
            do {
                try await Firestore.firestore().collection("users").document(user.uid).updateData([
                    "lastOnline": FieldValue.serverTimestamp()
                ])
                print("[AuthService] Last online timestamp updated")
            } catch {
                print("[AuthService] Failed to update last online: \(error.localizedDescription)")
                // Don't throw - this is not critical for login
            }
            
            print("[AuthService] User signed in successfully: \(email), UID: \(user.uid)")
            isLoading = false
            
        } catch {
            print("[AuthService] Error during signIn: \(error.localizedDescription)")
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            
            // Ensure we're signed out on error
            try? Auth.auth().signOut()
            throw error
        }
    }
    
    func sendPasswordReset(email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("[AuthService] Password reset email sent to: \(email)")
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await user.sendEmailVerification()
            print("[AuthService] Email verification sent")
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    func checkEmailVerification() async throws -> Bool {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.noCurrentUser
        }
        
        try await user.reload()
        
        if user.isEmailVerified {
            // Update Firestore
            try await Firestore.firestore().collection("users").document(user.uid).updateData([
                "isEmailVerified": true
            ])
            return true
        }
        
        return false
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presenting viewController: UIViewController, expectedRole: UserRole) async throws {
        print("[AuthService] Starting role-aware Google signIn for expected role: \(expectedRole.rawValue)")
        isLoading = true
        errorMessage = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleSignInFailed
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInFailed
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            // Check if user document exists in Firestore
            let userDoc = try await Firestore.firestore().collection("users").document(user.uid).getDocument()
            
            if !userDoc.exists {
                // Create new user document with the selected role from UI
                let userData: [String: Any] = [
                    "email": user.email ?? "",
                    "fullName": user.displayName ?? "Google User",
                    "role": expectedRole.rawValue, 
                    "isEmailVerified": true,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastOnline": FieldValue.serverTimestamp(),
                    "xp": 0,
                    "level": 1,
                    "profileImageUrl": user.photoURL?.absoluteString ?? "",
                    "assignedDietitianId": expectedRole == .client ? "" : nil
                ]
                
                try await Firestore.firestore().collection("users").document(user.uid).setData(userData)
                print("[AuthService] Google user document created with role = \(expectedRole.rawValue)")
            } else {
                // Existing user - validate their role matches expected role
                guard let userData = userDoc.data(),
                      let userRoleString = userData["role"] as? String,
                      let userRole = UserRole(rawValue: userRoleString) else {
                    print("[AuthService] Invalid role data for existing Google user")
                    try Auth.auth().signOut()
                    throw AuthError.invalidUserRole
                }
                
                // Validate role matches expected role
                if userRole != expectedRole {
                    print("[AuthService] Google user role mismatch - User role: \(userRole.rawValue), Expected: \(expectedRole.rawValue)")
                    try Auth.auth().signOut()
                    throw AuthError.roleMismatch(correctRole: userRole)
                }
                
                // Update last online
                try await Firestore.firestore().collection("users").document(user.uid).updateData([
                    "lastOnline": FieldValue.serverTimestamp()
                ])
                print("[AuthService] Existing Google user validated with correct role: \(userRole.rawValue)")
            }
            
            print("[AuthService] Google sign in successful with role validation")
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    // KEEP: Original Google Sign In method for backward compatibility
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleSignInFailed
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInFailed
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let user = authResult.user
            
            // Check if user document exists in Firestore
            let userDoc = try await Firestore.firestore().collection("users").document(user.uid).getDocument()
            
            if !userDoc.exists {
                // Create new user document - Google users default to client
                let userData: [String: Any] = [
                    "email": user.email ?? "",
                    "fullName": user.displayName ?? "Google User",
                    "role": "client", 
                    "isEmailVerified": true,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastOnline": FieldValue.serverTimestamp(),
                    "xp": 0,
                    "level": 1,
                    "profileImageUrl": user.photoURL?.absoluteString ?? "",
                    "assignedDietitianId": ""
                ]
                
                try await Firestore.firestore().collection("users").document(user.uid).setData(userData)
                print("[AuthService] Google user document created with role = client")
            } else {
                // Update last online
                try await Firestore.firestore().collection("users").document(user.uid).updateData([
                    "lastOnline": FieldValue.serverTimestamp()
                ])
            }
            
            print("[AuthService] Google sign in successful")
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        print("[AuthService] Starting sign out process...")
        
        do {
            // Sign out from Firebase Auth
            try Auth.auth().signOut()
            print("[AuthService] Firebase Auth sign out successful")
            
            // Sign out from Google Sign-In
            GIDSignIn.sharedInstance.signOut()
            print("[AuthService] Google Sign-In sign out successful")
            
            // Clear any local state
            isLoading = false
            errorMessage = nil
            showingError = false
            
            print("[AuthService] Sign out process completed")
            
        } catch {
            print("[AuthService] Sign out error: \(error.localizedDescription)")
            errorMessage = handleAuthError(error)
            showingError = true
            throw error
        }
    }
    
    // MARK: - Error Handling
    
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        
        if let authErrorCode = AuthErrorCode(rawValue: (error as NSError).code) {
            switch authErrorCode {
            case .emailAlreadyInUse:
                return "This email is already registered. Please use a different email or sign in."
            case .invalidEmail:
                return "Please enter a valid email address."
            case .weakPassword:
                return "Password should be at least 6 characters long."
            case .userNotFound:
                return "No account found with this email. Please check your email or sign up."
            case .wrongPassword:
                return "Incorrect password. Please try again."
            case .tooManyRequests:
                return "Too many failed attempts. Please try again later."
            case .networkError:
                return "Network error. Please check your internet connection."
            case .userDisabled:
                return "This account has been disabled. Please contact support."
            default:
                return "Authentication error: \(error.localizedDescription)"
            }
        }
        
        return "An unexpected error occurred: \(error.localizedDescription)"
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
}

// MARK: - Custom Auth Errors

enum AuthError: LocalizedError {
    case emailNotVerified
    case noCurrentUser
    case googleSignInFailed
    case userDataNotFound
    case invalidUserRole
    case roleMismatch(correctRole: UserRole)
    
    var errorDescription: String? {
        switch self {
        case .emailNotVerified:
            return "Please verify your email before signing in. Check your inbox for a verification email."
        case .noCurrentUser:
            return "No user is currently signed in."
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .userDataNotFound:
            return "Account data not found. Please contact support."
        case .invalidUserRole:
            return "Invalid account type. Please contact support."
        case .roleMismatch(let correctRole):
            return "You're trying to sign in with the wrong account type. You have a \(correctRole.displayName) account, so please go back and select '\(correctRole.displayName)' to access your account."
        }
    }
}
