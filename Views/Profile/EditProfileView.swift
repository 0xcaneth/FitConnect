import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

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
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    
    // Animation states
    @State private var headerScale = 0.8
    @State private var headerOpacity = 0.0
    @State private var particleOffset = 0.0
    
    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let fitnessGoalOptions = ["Weight Loss", "Weight Gain", "Muscle Building", "General Fitness", "Endurance", "Strength Training"]
    private let activityLevelOptions = ["Sedentary", "Light", "Moderate", "Active", "Very Active"]
    
    var body: some View {
        ZStack {
            // Premium Animated Background
            premiumAnimatedBackground()
            
            VStack(spacing: 0) {
                // Premium Navigation Header
                premiumNavigationHeader()
                
                if isLoading {
                    premiumLoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Hero Profile Header
                            heroProfileHeader()
                                .padding(.top, 30)
                                .padding(.bottom, 40)
                            
                            // Form Content
                            VStack(spacing: 32) {
                                // Personal Information Section
                                premiumFormSection(
                                    title: "Personal Information",
                                    icon: "person.circle.fill",
                                    gradient: [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84)
                                    ],
                                    delay: 0.1
                                ) {
                                    personalInformationContent()
                                }
                                
                                // Health & Fitness Section
                                premiumFormSection(
                                    title: "Health & Fitness",
                                    icon: "heart.circle.fill",
                                    gradient: [
                                        Color(red: 1.0, green: 0.42, blue: 0.42),
                                        Color(red: 1.0, green: 0.55, blue: 0.33)
                                    ],
                                    delay: 0.2
                                ) {
                                    healthFitnessContent()
                                }
                                
                                // About Section
                                premiumFormSection(
                                    title: "About Me",
                                    icon: "text.bubble.fill",
                                    gradient: [
                                        Color(red: 0.31, green: 0.78, blue: 0.47),
                                        Color(red: 0.27, green: 0.64, blue: 0.71)
                                    ],
                                    delay: 0.3
                                ) {
                                    aboutMeContent()
                                }
                                
                                // Premium Save Button
                                premiumSaveButton()
                                    .padding(.top, 20)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: showContent)
                                
                                Spacer(minLength: 120)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
            
            // Premium Success/Error Overlays
            premiumOverlays()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingPhotoPicker) {
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select Photo")
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                profileImage = image
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profileImage = UIImage(data: data)
                }
            }
        }
        .onAppear {
            loadUserProfile()
            startAnimations()
        }
    }
    
    @ViewBuilder
    private func premiumAnimatedBackground() -> some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.10, green: 0.11, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated radial gradients
            RadialGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2, y: 0.3),
                startRadius: 50,
                endRadius: 300
            )
            
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.42, blue: 0.42).opacity(0.05),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8, y: 0.7),
                startRadius: 30,
                endRadius: 250
            )
            
            // Floating particles
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3),
                                Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height) + particleOffset
                    )
                    .animation(
                        .linear(duration: Double.random(in: 25...45))
                        .repeatForever(autoreverses: false),
                        value: particleOffset
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func premiumNavigationHeader() -> some View {
        HStack {
            // Enhanced back button - full tap area
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }
            
            Spacer()
            
            Text("Edit Profile")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.white.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .opacity(headerOpacity)
        .animation(.easeOut(duration: 0.6), value: headerOpacity)
    }
    
    @ViewBuilder
    private func heroProfileHeader() -> some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 60,
                            endRadius: 100
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(headerScale)
                
                // Main profile circle
                Circle()
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84),
                                        Color(red: 0.54, green: 0.50, blue: 0.97)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                    )
                    .scaleEffect(headerScale)
                
                // Profile image or initials
                if let profileImage = profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 94, height: 94)
                        .clipShape(Circle())
                        .scaleEffect(headerScale)
                } else {
                    Text(userInitials)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
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
                        .scaleEffect(headerScale)
                }
                
                // Enhanced camera button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Menu {
                            Button(action: {
                                showingPhotoPicker = true
                            }) {
                                Label("Choose from Library", systemImage: "photo.fill")
                            }
                            
                            Button(action: {
                                showingCamera = true
                            }) {
                                Label("Take Photo", systemImage: "camera.fill")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.49, green: 0.34, blue: 1.0),
                                                Color(red: 0.31, green: 0.25, blue: 0.84)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .shadow(
                                        color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                        radius: 8, x: 0, y: 4
                                    )
                                
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 8, y: 8)
                        }
                        .scaleEffect(headerScale)
                    }
                }
                .frame(width: 100, height: 100)
            }
            .opacity(headerOpacity)
            
            VStack(spacing: 8) {
                Text("Update your profile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Keep your information current and personalized")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .opacity(headerOpacity)
            .offset(y: headerOpacity == 1.0 ? 0 : 20)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: headerOpacity)
        }
    }
    
    @ViewBuilder
    private func premiumFormSection<Content: View>(
        title: String,
        icon: String,
        gradient: [Color],
        delay: Double,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced section header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradient[0].opacity(0.2),
                                    gradient[0].opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 35
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Enhanced content container
            VStack(spacing: 0) {
                content()
            }
            .padding(28)
            .background(
                ZStack {
                    // Glassmorphism background
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    // Subtle accent glow
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradient[0].opacity(0.05),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                }
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 20, x: 0, y: 10
                )
            )
        }
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 40)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay), value: showContent)
    }
    
    @ViewBuilder
    private func personalInformationContent() -> some View {
        VStack(spacing: 24) {
            // Name fields row
            HStack(spacing: 16) {
                PremiumFormField(
                    title: "First Name",
                    text: $firstName,
                    placeholder: "Enter first name",
                    icon: "person.fill"
                )
                
                PremiumFormField(
                    title: "Last Name",
                    text: $lastName,
                    placeholder: "Enter last name",
                    icon: "person.fill"
                )
            }
            
            // Email field (disabled)
            PremiumFormField(
                title: "Email Address",
                text: $email,
                placeholder: "Enter email address",
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                isDisabled: true
            )
            
            // Phone field
            PremiumFormField(
                title: "Phone Number",
                text: $phoneNumber,
                placeholder: "Enter phone number",
                icon: "phone.fill",
                keyboardType: .phonePad
            )
            
            // Date picker
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                    
                    Text("Date of Birth")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .colorScheme(.dark)
                    .accentColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
            
            // Gender picker
            PremiumPickerField(
                title: "Gender",
                selection: $gender,
                options: genderOptions,
                icon: "figure.dress.line.vertical.figure"
            )
        }
    }
    
    @ViewBuilder
    private func healthFitnessContent() -> some View {
        VStack(spacing: 24) {
            // Height and Weight row
            HStack(spacing: 16) {
                PremiumFormField(
                    title: "Height (cm)",
                    text: $height,
                    placeholder: "175",
                    icon: "ruler.fill",
                    keyboardType: .numberPad
                )
                
                PremiumFormField(
                    title: "Weight (kg)",
                    text: $weight,
                    placeholder: "70",
                    icon: "scalemass.fill",
                    keyboardType: .decimalPad
                )
            }
            
            PremiumPickerField(
                title: "Fitness Goal",
                selection: $fitnessGoal,
                options: fitnessGoalOptions,
                icon: "target"
            )
            
            PremiumPickerField(
                title: "Activity Level",
                selection: $activityLevel,
                options: activityLevelOptions,
                icon: "bolt.fill"
            )
        }
    }
    
    @ViewBuilder
    private func aboutMeContent() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.31, green: 0.78, blue: 0.47))
                
                Text("Bio")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .frame(height: 120)
                
                TextEditor(text: $bio)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                
                if bio.isEmpty {
                    Text("Share your fitness journey, goals, and what motivates you...")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumSaveButton() -> some View {
        Button(action: saveProfile) {
            HStack(spacing: 16) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(isSaving ? "Saving Changes..." : "Save Changes")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
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
                    
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                .shadow(
                    color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.4),
                    radius: 20, x: 0, y: 10
                )
            )
        }
        .disabled(isSaving)
        .scaleEffect(isSaving ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSaving)
    }
    
    @ViewBuilder
    private func premiumLoadingView() -> some View {
        VStack(spacing: 32) {
            ZStack {
                // Pulsing circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.8),
                                    Color(red: 0.31, green: 0.25, blue: 0.84).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60 + CGFloat(index * 20))
                        .scaleEffect(headerScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: headerScale
                        )
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            Text("Loading your profile...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func premiumOverlays() -> some View {
        ZStack {
            // Success overlay
            if showSuccess {
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Profile updated successfully!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
                                radius: 20, x: 0, y: 10
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showSuccess = false
                    }
                }
            }
            
            // Error overlay
            if showError {
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Button(action: { showError = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
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
                                radius: 20, x: 0, y: 10
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                .transition(.asymmetric(insertion: .move(edge: .top), removal: .opacity))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showError)
            }
        }
    }
    
    private var userInitials: String {
        let firstInitial = firstName.first?.uppercased() ?? ""
        let lastInitial = lastName.first?.uppercased() ?? ""
        if firstInitial.isEmpty && lastInitial.isEmpty {
            return (session.currentUser?.fullName ?? "User").prefix(2).uppercased()
        }
        return "\(firstInitial)\(lastInitial)"
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            headerOpacity = 1.0
        }
        
        withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
            headerScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            showContent = true
        }
        
        // Start particle animation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            particleOffset = -1000
        }
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
                
                // Load existing data with fallbacks
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
            "fullName": "\(firstName) \(lastName)",
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
    var icon: String = "textfield"
    var keyboardType: UIKeyboardType = .default
    var isDisabled: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(isDisabled ? 0.03 : 0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isFocused ? 
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6) :
                                    Color.white.opacity(0.15),
                                    lineWidth: isFocused ? 2 : 1
                                )
                        )
                )
                .foregroundColor(isDisabled ? .white.opacity(0.5) : .white)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(isDisabled)
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
    }
}

struct PremiumPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var icon: String = "list.bullet"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        HStack {
                            Text(option)
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let completion: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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