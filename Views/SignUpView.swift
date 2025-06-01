import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    let onSignUpComplete: () -> Void // This will be called to show the EmailVerificationView
    let onLoginTap: () -> Void
    let onBack: (() -> Void)?
    
    @EnvironmentObject var session: SessionStore
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "client"
    @State private var agreedToTerms = false
    @State private var showContent = false
    @State private var showingTerms = false
    @State private var isSigningUp = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var fullNameError: String? = nil
    @State private var emailError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var termsError: String? = nil
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case fullName, email, password, confirmPassword
    }
    
    init(onSignUpComplete: @escaping () -> Void, onLoginTap: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self.onSignUpComplete = onSignUpComplete
        self.onLoginTap = onLoginTap
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
                        // Header with back button (no large rectangle)
                        HStack {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                if let backAction = onBack {
                                    backAction()
                                } else {
                                    onLoginTap()
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                        
                        // Semi-transparent holographic glass card
                        VStack(spacing: 24) {
                            // Title & Subtitle
                            VStack(spacing: 8) {
                                Text("Create Account")
                                    .font(.system(size: 28, weight: .semibold)) // SF Pro Semibold 28pt
                                    .foregroundColor(.white)
                                
                                Text("Join FitConnect and start your fitness journey")
                                    .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) // #AAAAAA
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Form Fields
                            VStack(spacing: 16) { // Adjusted spacing
                                // Full Name Field
                                VStack(alignment: .leading, spacing: 4) { // Adjusted spacing
                                    Text("Full Name")
                                        .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                        .foregroundColor(.white)
                                    
                                    EnhancedTextField(
                                        placeholder: "Full Name",
                                        text: $fullName,
                                        isSecure: false
                                    )
                                    .focused($focusedField, equals: .fullName)
                                    .autocapitalization(.words) // Or .none if preferred
                                    .disableAutocorrection(true)
                                    if let fullNameError {
                                        Text(fullNameError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                // Email Address Field
                                VStack(alignment: .leading, spacing: 4) { // Adjusted spacing
                                    Text("Email Address")
                                        .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                        .foregroundColor(.white)
                                    
                                    EnhancedTextField(
                                        placeholder: "Email Address",
                                        text: $email,
                                        isSecure: false,
                                        keyboardType: .emailAddress
                                    )
                                    .focused($focusedField, equals: .email)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    if let emailError {
                                        Text(emailError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                // Password Field with eye toggle inside
                                VStack(alignment: .leading, spacing: 4) { // Adjusted spacing
                                    Text("Password")
                                        .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                        .foregroundColor(.white)
                                    
                                    EnhancedTextField(
                                        placeholder: "Password",
                                        text: $password,
                                        isSecure: true
                                    )
                                    .focused($focusedField, equals: .password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    if let passwordError {
                                        Text(passwordError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }
                                
                                // Confirm Password Field with eye toggle inside
                                VStack(alignment: .leading, spacing: 4) { // Adjusted spacing
                                    Text("Confirm Password")
                                        .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                        .foregroundColor(.white)
                                    
                                    EnhancedTextField(
                                        placeholder: "Confirm Password",
                                        text: $confirmPassword,
                                        isSecure: true
                                    )
                                    .focused($focusedField, equals: .confirmPassword)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    if let confirmPasswordError {
                                        Text(confirmPasswordError)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .padding(.top, 2)
                                    }
                                }
                            }
                            
                            // Account Type Picker (segmented)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Account Type")
                                    .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                                    .foregroundColor(.white)
                                
                                Picker("", selection: $selectedRole) {
                                    Text("Client").tag("client")
                                    Text("Dietitian").tag("dietitian")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 12)
                            }
                            
                            // Terms & Conditions Checkbox
                            VStack(alignment: .leading, spacing: 4) { // Wrap in VStack for error message
                                HStack(spacing: 12) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            agreedToTerms.toggle()
                                            termsError = nil // Clear error on interaction
                                        }
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(agreedToTerms ? Color(red: 0.43, green: 0.31, blue: 1.0) : Color.gray) // #6E4EFF when checked
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("I agree to the ")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.white)
                                        
                                        Button(action: {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                            impactFeedback.impactOccurred()
                                            showingTerms = true
                                        }) {
                                            Text("Terms & Conditions")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 8)

                                if let termsError {
                                    Text(termsError)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 36) // Align with text
                                }
                            }
                            
                            // Create Account Button (horizontal gradient)
                            Button(action: performSignUp) {
                                if isSigningUp {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Creating Account...")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                (canAttemptSignUp && !isSigningUp) ?
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                        Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient( // Disabled/Invalid state gradient
                                    colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .disabled(!canAttemptSignUp || isSigningUp)
                            .opacity((canAttemptSignUp && !isSigningUp) ? 1.0 : 0.6)
                            
                            // Already have account link
                            HStack(spacing: 8) {
                                Text("Already have an account?")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                                
                                Button("Log In") {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    onLoginTap()
                                }
                                .font(.system(size: 14, weight: .semibold)) // SF Pro Semibold 14pt
                                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                            }
                        }
                        .padding(24)
                        .background(
                            // Semi-transparent holographic glass card style
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.85)) // #1E1E26 @85% opacity
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(red: 0.43, green: 0.31, blue: 1.0), lineWidth: 1) // Thin neon-blue border #6E4EFF
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1.0 : 0.0)
                        .scaleEffect(showContent ? 1.0 : 0.95)
                        
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.bottom + 20))
                    }
                }
                
                // Loading Spinner Overlay
                if isSigningUp {
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsView(onAccept: {
                showingTerms = false
                agreedToTerms = true
            }, onBack: {
                showingTerms = false
            })
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if alertTitle == "Account Created" {
                    onSignUpComplete()
                }
                // For other errors, just dismiss
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var canAttemptSignUp: Bool {
        // This checks basic non-emptiness and terms agreement for button UI state.
        // Detailed validation (email format, password length/match) happens in performSignUp.
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        agreedToTerms
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func performSignUp() {
        // Reset previous errors
        fullNameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        termsError = nil
        
        var validationPassed = true
        
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fullNameError = "Full name cannot be empty."
            validationPassed = false
        }
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty {
            emailError = "Email cannot be empty."
            validationPassed = false
        } else if !isValidEmail(trimmedEmail) {
            emailError = "Invalid email address format."
            validationPassed = false
        }
        
        if password.isEmpty {
            passwordError = "Password cannot be empty."
            validationPassed = false
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters."
            validationPassed = false
        }
        
        if confirmPassword.isEmpty {
            confirmPasswordError = "Confirm password cannot be empty."
            validationPassed = false
        } else if password != confirmPassword {
            confirmPasswordError = "Passwords do not match."
            validationPassed = false
        }
        
        if !agreedToTerms {
            termsError = "Please accept Terms & Conditions."
            validationPassed = false
        }
        
        guard validationPassed else {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.prepare()
            notificationFeedback.notificationOccurred(.error)
            return
        }
        
        // If local validation passes, proceed to Firebase
        handleCreateAccountWithFirebase()
    }

    private func handleCreateAccountWithFirebase() {
        focusedField = nil // Dismiss keyboard
        
        withAnimation {
            isSigningUp = true
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Auth.auth().createUser(withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password) { authResult, error in
            if let error = error {
                withAnimation { isSigningUp = false }
                if let nsError = error as NSError? {
                    handleFirebaseAuthError(nsError)
                } else {
                    // Generic error handling if it's not an NSError
                    alertTitle = "Sign Up Error"
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.prepare()
                    notificationFeedback.notificationOccurred(.error)
                }
                return
            }
            
            guard let user = authResult?.user else {
                withAnimation { isSigningUp = false }
                alertTitle = "Sign Up Error"
                alertMessage = "Account creation failed. Unknown error."
                showingAlert = true
                return
            }
            
            // Save user details to Firestore
            saveUserDetailsToFirestore(user: user)
        }
    }

    private func handleFirebaseAuthError(_ error: NSError) {
        switch error.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            emailError = "This email is already registered."
        case AuthErrorCode.weakPassword.rawValue:
            passwordError = "Password is too weak. Please choose a stronger one."
        default:
            alertTitle = "Sign Up Error"
            alertMessage = error.localizedDescription // Or a generic "Unable to create account. Please try again."
            showingAlert = true
        }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.prepare()
        notificationFeedback.notificationOccurred(.error)
    }

    private func saveUserDetailsToFirestore(user: User) {
        let uid = user.uid
        let userData: [String: Any] = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "fullName": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "role": selectedRole,
            "assignedDietitianId": "", // Default value
            "createdAt": Timestamp(date: Date()),
            "emailVerified": false // Initially false
        ]
        
        // Ensure isSigningUp is true before this async operation
        // It should have been set by handleCreateAccountWithFirebase
        
        Firestore.firestore().collection("users").document(uid).setData(userData) { firestoreError in
            // This is the first completion handler after createUser succeeded.
            
            if let firestoreError = firestoreError {
                // Firestore failed, but Auth user was created.
                // We should still attempt to send verification or guide the user.
                // For now, alert and ensure UI is reset.
                withAnimation { isSigningUp = false }
                alertTitle = "Profile Save Error"
                alertMessage = "Account created, but failed to save profile details: \(firestoreError.localizedDescription). Please try logging in, or contact support if issues persist."
                showingAlert = true
                // Do NOT return here if you want to attempt email verification anyway.
                // However, if profile save is critical before verification, then return is appropriate.
                // Based on previous logic, we stop here.
                return
            }
            
            // Firestore save succeeded. Now update profile and send verification.
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            changeRequest.commitChanges { profileUpdateError in
                // This is a nested async call.
                if let profileUpdateError {
                    print("Error updating profile display name: \(profileUpdateError.localizedDescription)")
                    // Non-critical, so we don't necessarily stop isSigningUp or show a blocking alert.
                }
                
                // Now, send verification email. This is another async call.
                user.sendEmailVerification { emailVerificationError in
                    // CRITICAL: This is the final step in this chain for resetting isSigningUp.
                    withAnimation { isSigningUp = false } // Ensure isSigningUp is reset
                    
                    if let emailVerificationError = emailVerificationError {
                        alertTitle = "Verification Email Failed"
                        alertMessage = "Could not send verification email: \(emailVerificationError.localizedDescription). Please try again later or contact support."
                        showingAlert = true
                    } else {
                        alertTitle = "Account Created"
                        alertMessage = "A verification email has been sent to your inbox. Please confirm your email before logging in."
                        showingAlert = true // This will trigger the alert and then onSignUpComplete()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(onSignUpComplete: {}, onLoginTap: {}, onBack: {})
            .environmentObject(SessionStore())
            .preferredColorScheme(.dark)
    }
}
#endif
