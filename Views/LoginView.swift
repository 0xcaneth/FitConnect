import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    let onLoginComplete: () -> Void
    let onSignUpTap: () -> Void
    let onBack: (() -> Void)?
    
    @EnvironmentObject var session: SessionStore
    @State private var email = ""
    @State private var password = ""
    @State private var showContent = false
    @State private var showingForgotPassword = false
    @State private var isSigningIn = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var googleButtonPressed = false
    @State private var signInButtonPressed = false
    @State private var showResendVerificationOption = false
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    @Environment(\.scenePhase) var scenePhase
    
    init(onLoginComplete: @escaping () -> Void, onSignUpTap: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onLoginComplete = onLoginComplete
        self.onSignUpTap = onSignUpTap
        self.onBack = onBack
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header with back arrow
                        HStack {
                            if let backAction = onBack {
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    backAction()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                        
                        // Title and subtitle
                        VStack(spacing: 12) {
                            Text("Welcome Back!")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue your fitness journey")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
                                .multilineTextAlignment(.center)
                        }
                        
                        // Form fields
                        VStack(spacing: 20) {
                            // Email TextField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white)
                                
                                EnhancedTextField(
                                    placeholder: "Email Address",
                                    text: $email,
                                    isSecure: false,
                                    keyboardType: .emailAddress
                                )
                                .focused($focusedField, equals: .email)
                            }
                            
                            // Password SecureField
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.white)
                                
                                EnhancedTextField(
                                    placeholder: "Password",
                                    text: $password,
                                    isSecure: true
                                )
                                .focused($focusedField, equals: .password)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // "Forgot Password?" link
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                showingForgotPassword = true
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0))
                        }
                        .padding(.horizontal, 24)
                        
                        // Sign In Button
                        Button(action: handleLogin) {
                            Text("Sign In")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                    Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .disabled(!isFormValid || isSigningIn)
                        .opacity((isFormValid && !isSigningIn) ? 1.0 : 0.6)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .scaleEffect(signInButtonPressed ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: signInButtonPressed)
                        
                        // Separator with "or"
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(Color(red: 0.27, green: 0.27, blue: 0.27))
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
                            
                            Rectangle()
                                .fill(Color(red: 0.27, green: 0.27, blue: 0.27))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        
                        // Continue with Google Button
                        Button(action: handleGoogleSignIn) {
                            HStack(spacing: 16) {
                                Image(systemName: "globe")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                                    .padding(.leading, 8)
                                
                                Spacer()
                                
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                            Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                                .background(Color(red: 0.12, green: 0.12, blue: 0.15).cornerRadius(16))
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .scaleEffect(googleButtonPressed ? 0.98 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: googleButtonPressed)
                        
                        // Sign Up Link
                        HStack(spacing: 8) {
                            Text("Don't have an account?")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            
                            Button("Sign Up") {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                onSignUpTap()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0))
                        }
                        .padding(.bottom, max(32, geometry.safeAreaInsets.bottom + 16))
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6), value: showContent)
                
                // Loading Spinner Overlay
                if isSigningIn {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            if showResendVerificationOption {
                Button("OK") { showResendVerificationOption = false } // Reset state
                Button("Resend Email") {
                    resendVerificationEmail()
                    showResendVerificationOption = false // Reset state
                }
            } else {
                Button("OK") { }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        let emailValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && email.contains("@")
        let passwordValid = !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return emailValid && passwordValid
    }
    
    private func handleLogin() {
        guard isFormValid else { return }
        
        focusedField = nil
        
        withAnimation {
            isSigningIn = true
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            signInButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                signInButtonPressed = false
            }
        }
        
        // Call Firebase signIn
        Auth.auth().signIn(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) { result, error in
            if let error = error {
                withAnimation {
                    isSigningIn = false
                }
                alertTitle = "Login Error"
                alertMessage = error.localizedDescription
                showResendVerificationOption = false // Ensure it's false for general errors
                showingAlert = true
                return
            }
            
            guard let user = result?.user else {
                withAnimation {
                    isSigningIn = false
                }
                alertTitle = "Login Error"
                alertMessage = "Authentication failed. Please try again."
                showResendVerificationOption = false // Ensure it's false for general errors
                showingAlert = true
                return
            }
            
            // Check email verification
            if !user.isEmailVerified {
                withAnimation {
                    isSigningIn = false
                }
                alertTitle = "Email Not Verified"
                alertMessage = "Please verify your email before signing in. You can request a new verification email."
                showResendVerificationOption = true
                showingAlert = true
                return
            }
            
            // Fetch Firestore user document
            let uid = user.uid
            Firestore.firestore().collection("users").document(uid).getDocument { snapshot, error in
                withAnimation {
                    isSigningIn = false
                }
                
                guard let data = snapshot?.data(),
                      let role = data["role"] as? String else {
                    alertTitle = "Login Error"
                    alertMessage = "User data missing. Please contact support."
                    showingAlert = true
                    return
                }
                
                // Set SessionStore properties
                session.currentUserId = uid
                session.role = role
                if role == "client" {
                    session.assignedDietitianId = data["assignedDietitianId"] as? String ?? ""
                }
                session.isLoggedIn = true
                
                // Navigate to home screen
                onLoginComplete()
            }
        }
    }
    
    private func handleGoogleSignIn() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            googleButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                googleButtonPressed = false
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Implement Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            alertTitle = "Google Sign-In Error"
            alertMessage = "Could not retrieve Google Client ID from Firebase."
            showingAlert = true
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // Find the top view controller to present the Google Sign-In sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            alertTitle = "Google Sign-In Error"
            alertMessage = "Could not find a view controller to present Google Sign-In."
            showingAlert = true
            return
        }
        
        withAnimation { isSigningIn = true }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                withAnimation { isSigningIn = false }
                alertTitle = "Google Sign-In Failed"
                alertMessage = "Google sign-in failed: \(error.localizedDescription)"
                showingAlert = true
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                withAnimation { isSigningIn = false }
                alertTitle = "Google Sign-In Failed"
                alertMessage = "Could not retrieve ID token from Google."
                showingAlert = true
                return
            }
            
            let accessToken = user.accessToken.tokenString // Might be needed for some scopes

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    withAnimation { isSigningIn = false }
                    alertTitle = "Firebase Google Login Failed"
                    alertMessage = "Firebase Google login failed: \(error.localizedDescription)"
                    showingAlert = true
                } else if let authResultUser = authResult?.user {
                    // Successfully signed in with Google via Firebase
                    // Check if this is a new user or existing user to fetch/create Firestore data
                    self.fetchOrCreateFirestoreUser(firebaseUser: authResultUser, fullName: user.profile?.name, email: user.profile?.email)
                } else {
                    withAnimation { isSigningIn = false }
                    alertTitle = "Login Error"
                    alertMessage = "Unknown error during Google Sign-In with Firebase."
                    showingAlert = true
                }
            }
        }
    }

    // Function to fetch or create user data in Firestore after Google Sign-In
    private func fetchOrCreateFirestoreUser(firebaseUser: FirebaseAuth.User, fullName: String?, email: String?) {
        let uid = firebaseUser.uid
        let userRef = Firestore.firestore().collection("users").document(uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                // User exists, fetch data
                guard let data = document.data(),
                      let role = data["role"] as? String else {
                    withAnimation { self.isSigningIn = false }
                    self.alertTitle = "Login Error"
                    self.alertMessage = "User data missing after Google Sign-In. Please contact support."
                    self.showingAlert = true
                    return
                }
                self.session.currentUserId = uid
                self.session.role = role
                if role == "client" {
                    self.session.assignedDietitianId = data["assignedDietitianId"] as? String ?? ""
                }
                self.session.isLoggedIn = true
                withAnimation { self.isSigningIn = false }
                self.onLoginComplete()
            } else {
                // New user, create Firestore document
                let newUserData: [String: Any] = [
                    "email": email ?? firebaseUser.email ?? "",
                    "fullName": fullName ?? firebaseUser.displayName ?? "Google User",
                    "role": "client", // Default role for new Google Sign-In users
                    "assignedDietitianId": "",
                    "createdAt": Timestamp(date: Date()),
                    "emailVerified": firebaseUser.isEmailVerified // Google emails are usually verified
                ]
                userRef.setData(newUserData) { firestoreError in
                    if let firestoreError = firestoreError {
                        withAnimation { self.isSigningIn = false }
                        self.alertTitle = "Profile Creation Error"
                        self.alertMessage = "Google Sign-In successful, but failed to save profile: \(firestoreError.localizedDescription)"
                        self.showingAlert = true
                        // Potentially sign out the user here if profile save is critical
                        // try? Auth.auth().signOut()
                        return
                    }
                    
                    self.session.currentUserId = uid
                    self.session.role = "client"
                    self.session.assignedDietitianId = ""
                    self.session.isLoggedIn = true
                    withAnimation { self.isSigningIn = false }
                    self.onLoginComplete()
                }
            }
        }
    }
    
    private func resendVerificationEmail() {
        guard let user = Auth.auth().currentUser else {
            alertTitle = "Error"
            alertMessage = "Not signed in. Cannot resend verification email."
            showResendVerificationOption = false
            showingAlert = true
            return
        }

        // Prevent resending if email is already verified (though UI flow should prevent this)
        if user.isEmailVerified {
            alertTitle = "Already Verified"
            alertMessage = "Your email address is already verified."
            showResendVerificationOption = false
            showingAlert = true
            return
        }
        
        user.sendEmailVerification { error in
            if let error = error {
                alertTitle = "Resend Failed"
                alertMessage = "Could not resend verification email: \(error.localizedDescription)"
            } else {
                alertTitle = "Verification Email Sent"
                alertMessage = "A new verification email has been sent to \(user.email ?? "your email address"). Please check your inbox."
            }
            showResendVerificationOption = false // Reset after attempting resend
            showingAlert = true
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(onLoginComplete: {}, onSignUpTap: {}, onBack: {})
            .environmentObject(SessionStore())
            .preferredColorScheme(.dark)
    }
}
#endif
