import Foundation
import Firebase
import FirebaseAuth
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isEmailVerificationSent = false
    
    private let authService = AuthService.shared
    
    func signUp(email: String, password: String, fullName: String, role: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signUp(email: email, password: password, fullName: fullName, role: role)
            isEmailVerificationSent = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.sendPasswordReset(email: email)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func sendEmailVerification() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await authService.sendEmailVerification()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}