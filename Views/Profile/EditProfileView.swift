import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct UserEditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender = "Prefer not to say"
    @State private var height = ""
    @State private var weight = ""
    @State private var fitnessGoal = "General Fitness"
    @State private var activityLevel = "Moderate"
    @State private var bio = ""
    
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showContent = false
    
    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let fitnessGoalOptions = ["Weight Loss", "Weight Gain", "Muscle Building", "General Fitness", "Endurance", "Strength Training"]
    private let activityLevelOptions = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    
    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.10, green: 0.11, blue: 0.15),
                    Color(red: 0.12, green: 0.13, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                premiumNavigationHeader()
                
                if isLoading {
                    premiumLoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Profile Header
                            premiumProfileHeader()
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                            
                            // Personal Information Section
                            premiumFormSection(
                                title: "Personal Information",
                                icon: "person.fill",
                                color: Color(red: 0.49, green: 0.34, blue: 1.0)
                            ) {
                                VStack(spacing: 20) {
                                    HStack(spacing: 16) {
                                        PremiumFormField(
                                            title: "First Name",
                                            text: $firstName,
                                            placeholder: "Enter first name"
                                        )
                                        
                                        PremiumFormField(
                                            title: "Last Name",
                                            text: $lastName,
                                            placeholder: "Enter last name"
                                        )
                                    }
                                    
                                    PremiumFormField(
                                        title: "Email",
                                        text: $email,
                                        placeholder: "Enter email address",
                                        keyboardType: .emailAddress
                                    )
                                    .disabled(true) // Email typically can't be changed
                                    .opacity(0.6)
                                    
                                    PremiumFormField(
                                        title: "Phone Number",
                                        text: $phoneNumber,
                                        placeholder: "Enter phone number",
                                        keyboardType: .phonePad
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Date of Birth")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                            .datePickerStyle(CompactDatePickerStyle())
                                            .colorScheme(.dark)
                                            .accentColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                                    }
                                    
                                    PremiumPickerField(
                                        title: "Gender",
                                        selection: $gender,
                                        options: genderOptions
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            
                            // Health & Fitness Section
                            premiumFormSection(
                                title: "Health & Fitness",
                                icon: "heart.fill",
                                color: Color(red: 1.0, green: 0.42, blue: 0.42)
                            ) {
                                VStack(spacing: 20) {
                                    HStack(spacing: 16) {
                                        PremiumFormField(
                                            title: "Height (cm)",
                                            text: $height,
                                            placeholder: "175",
                                            keyboardType: .numberPad
                                        )
                                        
                                        PremiumFormField(
                                            title: "Weight (kg)",
                                            text: $weight,
                                            placeholder: "70",
                                            keyboardType: .decimalPad
                                        )
                                    }
                                    
                                    PremiumPickerField(
                                        title: "Fitness Goal",
                                        selection: $fitnessGoal,
                                        options: fitnessGoalOptions
                                    )
                                    
                                    PremiumPickerField(
                                        title: "Activity Level",
                                        selection: $activityLevel,
                                        options: activityLevelOptions
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                            
                            // About Section
                            premiumFormSection(
                                title: "About",
                                icon: "text.alignleft",
                                color: Color(red: 0.31, green: 0.78, blue: 0.47)
                            ) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Bio")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    ZStack(alignment: .topLeading) {
                                        TextEditor(text: $bio)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 12)
                                            .frame(height: 100)
                                            .background(Color.clear)
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .scrollContentBackground(.hidden)
                                        
                                        if bio.isEmpty {
                                            Text("Tell us about yourself, your fitness journey, and goals...")
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 20)
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .allowsHitTesting(false)
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                            
                            // Save Button
                            premiumSaveButton()
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            
            // Success/Error Overlays
            if showSuccess {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Profile updated successfully!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.31, green: 0.78, blue: 0.47),
                                        Color(red: 0.13, green: 0.64, blue: 0.27)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.4),
                                radius: 12, x: 0, y: 6
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showSuccess = false
                    }
                }
            }
            
            if showError {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: { showError = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.23, blue: 0.19),
                                        Color(red: 0.9, green: 0.2, blue: 0.15)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.4),
                                radius: 12, x: 0, y: 6
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showError)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserProfile()
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    @ViewBuilder
    private func premiumNavigationHeader() -> some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text("Edit Profile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private func premiumProfileHeader() -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                
                Text(userInitials)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0),
                                .white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            // TODO: Add photo selection
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(Color(red: 0.49, green: 0.34, blue: 1.0))
                                        .shadow(
                                            color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                            radius: 8, x: 0, y: 4
                                        )
                                )
                                .offset(x: 4, y: 4)
                        }
                    }
                }
                .frame(width: 80, height: 80)
            }
            
            Text("Update your profile information")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private func premiumFormSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                content()
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func premiumSaveButton() -> some View {
        Button(action: saveProfile) {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(isSaving ? "Saving Profile..." : "Save Changes")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0),
                                    Color(red: 0.31, green: 0.25, blue: 0.84)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                .shadow(
                    color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.4),
                    radius: 15, x: 0, y: 8
                )
            )
        }
        .disabled(isSaving)
        .scaleEffect(isSaving ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSaving)
    }
    
    @ViewBuilder
    private func premiumLoadingView() -> some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading profile...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var userInitials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func loadUserProfile() {
        guard let userId = session.currentUserId else {
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load profile: \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.errorMessage = "No profile data found"
                    self.showError = true
                    return
                }
                
                // Load existing data
                self.firstName = data["firstName"] as? String ?? ""
                self.lastName = data["lastName"] as? String ?? ""
                self.email = data["email"] as? String ?? ""
                self.phoneNumber = data["phoneNumber"] as? String ?? ""
                
                if let timestamp = data["dateOfBirth"] as? Timestamp {
                    self.dateOfBirth = timestamp.dateValue()
                }
                
                self.gender = data["gender"] as? String ?? "Prefer not to say"
                self.height = data["height"] as? String ?? ""
                self.weight = data["weight"] as? String ?? ""
                self.fitnessGoal = data["fitnessGoal"] as? String ?? "General Fitness"
                self.activityLevel = data["activityLevel"] as? String ?? "Moderate"
                self.bio = data["bio"] as? String ?? ""
            }
        }
    }
    
    private func saveProfile() {
        guard let userId = session.currentUserId else {
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isSaving = true
        
        let profileData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "dateOfBirth": Timestamp(date: dateOfBirth),
            "gender": gender,
            "height": height,
            "weight": weight,
            "fitnessGoal": fitnessGoal,
            "activityLevel": activityLevel,
            "bio": bio,
            "updatedAt": Timestamp()
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(profileData) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                
                if let error = error {
                    self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    self.showError = true
                    
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                } else {
                    self.showSuccess = true
                    
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    // Update session user data
                    if var currentUser = self.session.currentUser {
                        currentUser.fullName = "\(self.firstName) \(self.lastName)"
                        self.session.currentUser = currentUser
                    }
                }
            }
        }
    }
}

// MARK: - Premium Form Components

struct PremiumFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            TextField(placeholder, text: $text)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
}

struct PremiumPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .foregroundColor(.white)
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct UserEditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserEditProfileView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif