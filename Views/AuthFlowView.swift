import SwiftUI
import FirebaseAuth

@available(iOS 16.0, *)
struct AuthFlowView: View {
    @EnvironmentObject var session: SessionStore
    
    // Flow states
    @State private var showingSplash = true
    @State private var showingPrivacy = false
    @State private var showingTerms = false
    @State private var showingRoleSelection = false
    @State private var selectedRole: UserRole? = nil
    @State private var showingAuth = false
    @State private var showingSignUp = false
    @State private var showingPasswordReset = false
    @State private var showingEmailVerification = false
    @State private var verificationEmail = ""
    
    var body: some View {
        ZStack {
            if showingSplash {
                SplashView(
                    onContinue: {
                        showingSplash = false
                        showingPrivacy = true
                    }
                )
            } else if showingPrivacy {
                PrivacyAnalyticsView(
                    onContinue: {
                        showingPrivacy = false
                        showingTerms = true
                    },
                    onBack: { 
                        showingPrivacy = false
                        showingSplash = true
                    }
                )
            } else if showingTerms {
                SimpleTermsView(
                    onAccept: {
                        showingTerms = false
                        showingRoleSelection = true
                    },
                    onBack: {
                        showingTerms = false
                        showingPrivacy = true
                    }
                )
            } else if showingRoleSelection {
                RoleSelectionView(
                    onRoleSelected: { role in
                        selectedRole = role
                        showingRoleSelection = false
                        showingAuth = true
                    },
                    onBack: {
                        showingRoleSelection = false
                        showingTerms = true
                    }
                )
            } else if showingAuth {
                LoginScreenView(
                    selectedRole: selectedRole ?? .client,
                    onSignUpTap: {
                        showingAuth = false
                        showingSignUp = true
                    },
                    onForgotPasswordTap: {
                        showingAuth = false
                        showingPasswordReset = true
                    },
                    onBack: {
                        showingAuth = false
                        showingRoleSelection = true
                    }
                )
            } else if showingSignUp {
                SignUpScreenView(
                    selectedRole: selectedRole ?? .client,
                    onLoginTap: {
                        showingSignUp = false
                        showingAuth = true
                    },
                    onBack: {
                        showingSignUp = false
                        showingAuth = true
                    }
                )
            } else if showingPasswordReset {
                ResetPasswordView(
                    onBack: {
                        showingPasswordReset = false
                        showingAuth = true
                    }
                )
            } else if showingEmailVerification {
                EmailVerificationView(
                    email: verificationEmail,
                    onBack: {
                        showingEmailVerification = false
                        showingAuth = true
                    },
                    onVerified: {
                        // User verified, SessionStore will handle the transition
                        showingEmailVerification = false
                    }
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("emailVerificationNeeded"))) { notification in
            if let email = notification.userInfo?["email"] as? String {
                verificationEmail = email
                showingEmailVerification = true
                // Hide other screens
                showingSplash = false
                showingPrivacy = false
                showingTerms = false
                showingRoleSelection = false
                showingAuth = false
                showingSignUp = false
                showingPasswordReset = false
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AuthFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthFlowView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: false))
            .preferredColorScheme(.dark)
    }
}
#endif
