import SwiftUI

@available(iOS 16.0, *)
struct SignUpScreenView: View {
    let selectedRole: UserRole
    let onLoginTap: () -> Void
    let onBack: () -> Void
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var showContent = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var successMessage = ""
    
    var body: some View {
        ZStack {
            ZStack {
                Color(hex: "#0A0B0F")
                    .ignoresSafeArea()
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        roleGradientColor.opacity(0.15),
                        roleGradientColor.opacity(0.1),
                        Color.clear
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.3),
                    startRadius: 80,
                    endRadius: 300
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                premiumNavigationHeader()
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4), value: showContent)
                
                ScrollView {
                    VStack(spacing: 32) {
                        premiumHeaderSection()
                        
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                TextField("Enter your full name", text: $fullName)
                                    .textFieldStyle(PremiumTextFieldStyle())
                                    .autocapitalization(.words)
                                    .autocorrectionDisabled()
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.4), value: showContent)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                TextField("Enter your email address", text: $email)
                                    .textFieldStyle(PremiumTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.5), value: showContent)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(PremiumTextFieldStyle())
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.6), value: showContent)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.leading, 4)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(PremiumTextFieldStyle())
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.7), value: showContent)
                            
                            roleBenefitsSection()
                                .opacity(showContent ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.4).delay(0.8), value: showContent)
                            
                            CheckboxRow(
                                text: "I agree to the Terms & Conditions",
                                isChecked: $agreedToTerms
                            )
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(0.9), value: showContent)
                        }
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 20) {
                            Button(action: {
                                signUpWithRole()
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Create \(selectedRole.displayName) Account")
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            roleGradientColor,
                                            roleGradientColor.opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(28)
                                .shadow(
                                    color: roleGradientColor.opacity(0.3),
                                    radius: 12, x: 0, y: 4
                                )
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(1.0), value: showContent)
                            
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Button("Sign In") {
                                    onLoginTap()
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(roleGradientColor)
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.4).delay(1.1), value: showContent)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            
            if showError {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showError = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(0.9), Color.red.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showError)
            }
            
            if showSuccess {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        
                        Text(successMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showSuccess = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.9), Color.green.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showSuccess)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    private var roleGradientColor: Color {
        selectedRole == .client ? Color(hex: "#4A7BFF") : Color(hex: "#4AFFA1")
    }
    
    @ViewBuilder
    private func premiumNavigationHeader() -> some View {
        HStack {
            Button(action: onBack) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
            
            HStack(spacing: 8) {
                Circle()
                    .fill(roleGradientColor)
                    .frame(width: 8, height: 8)
                
                Text(selectedRole.displayName)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.trailing, 20)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func premiumHeaderSection() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(roleGradientColor.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .blur(radius: 8)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                roleGradientColor,
                                roleGradientColor.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                Image(systemName: selectedRole == .client ? "figure.run.circle.fill" : "stethoscope.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
            
            VStack(spacing: 8) {
                Text("Create \(selectedRole.displayName) Account")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
                
                Text("Join FitConnect as a \(selectedRole.displayName.lowercased()) and start your journey")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: showContent)
            }
        }
        .padding(.top, 40)
    }
    
    @ViewBuilder
    private func roleBenefitsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("As a \(selectedRole.displayName), you'll get:")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(roleBenefits, id: \.self) { benefit in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(roleGradientColor)
                            .frame(width: 6, height: 6)
                            .opacity(0.8)
                        
                        Text(benefit)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(roleGradientColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var roleBenefits: [String] {
        if selectedRole == .client {
            return [
                "Track workouts and nutrition",
                "Connect with professional dietitians",
                "Personal health insights and analytics",
                "Goal setting and progress monitoring"
            ]
        } else {
            return [
                "Manage client relationships",
                "Create custom meal plans",
                "Professional client analytics",
                "Schedule and manage appointments"
            ]
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && 
        !email.isEmpty && 
        email.contains("@") &&
        password.count >= 8 && 
        password == confirmPassword && 
        agreedToTerms
    }
    
    private func signUpWithRole() {
        guard isFormValid else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        Task {
            do {
                print("[SignUpView] Starting signup process for role: \(selectedRole.rawValue)")
                
                try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    fullName: fullName,
                    role: selectedRole.rawValue
                )
                
                print("[SignUpView] Signup completed successfully")
                
                await MainActor.run {
                    isLoading = false
                    successMessage = "\(selectedRole.displayName) account created! Please check your email to verify your account before signing in."
                    showSuccess = true
                    
                    fullName = ""
                    email = ""
                    password = ""
                    confirmPassword = ""
                    agreedToTerms = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showSuccess = false
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onLoginTap()
                        }
                    }
                }
            } catch {
                print("[SignUpView] Signup failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        showError = false
                    }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SignUpScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpScreenView(
            selectedRole: .client,
            onLoginTap: {},
            onBack: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
