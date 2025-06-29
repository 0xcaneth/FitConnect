import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    @State private var notificationsEnabled = true
    @State private var workoutReminders = true
    @State private var mealReminders = true
    @State private var progressUpdates = true
    @State private var socialNotifications = false
    @State private var emailNotifications = true
    
    @State private var units: String = "Metric"
    @State private var language: String = "English"
    @State private var theme: String = "Dark"
    
    @State private var shareProgress = false
    @State private var showRealName = true
    @State private var allowMessagesFromDietitians = true
    @State private var shareWorkouts = true
    
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showContent = false
    
    private let unitsOptions = ["Metric", "Imperial"]
    private let languageOptions = ["English", "Spanish", "French", "German", "Chinese", "Japanese"]
    private let themeOptions = ["Dark", "Light", "System"]
    
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
                        VStack(spacing: 24) {
                            // Notifications Section
                            premiumPreferenceSection(
                                title: "Notifications",
                                icon: "bell.fill",
                                color: Color(red: 0.49, green: 0.34, blue: 1.0)
                            ) {
                                VStack(spacing: 16) {
                                    PremiumToggleRow(
                                        title: "Push Notifications",
                                        subtitle: "Receive app notifications",
                                        isOn: $notificationsEnabled
                                    )
                                    
                                    PremiumToggleRow(
                                        title: "Workout Reminders",
                                        subtitle: "Daily workout reminders",
                                        isOn: $workoutReminders
                                    )
                                    .disabled(!notificationsEnabled)
                                    
                                    PremiumToggleRow(
                                        title: "Meal Reminders",
                                        subtitle: "Meal logging reminders",
                                        isOn: $mealReminders
                                    )
                                    .disabled(!notificationsEnabled)
                                    
                                    PremiumToggleRow(
                                        title: "Progress Updates",
                                        subtitle: "Weekly progress reports",
                                        isOn: $progressUpdates
                                    )
                                    .disabled(!notificationsEnabled)
                                    
                                    PremiumToggleRow(
                                        title: "Social Notifications",
                                        subtitle: "Likes, comments, and follows",
                                        isOn: $socialNotifications
                                    )
                                    .disabled(!notificationsEnabled)
                                    
                                    PremiumToggleRow(
                                        title: "Email Notifications",
                                        subtitle: "Receive important updates via email",
                                        isOn: $emailNotifications
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                            
                            // App Settings Section
                            premiumPreferenceSection(
                                title: "App Settings",
                                icon: "gear",
                                color: Color(red: 0.31, green: 0.78, blue: 0.47)
                            ) {
                                VStack(spacing: 16) {
                                    PremiumPickerRow(
                                        title: "Units",
                                        subtitle: "Measurement system",
                                        selection: $units,
                                        options: unitsOptions
                                    )
                                    
                                    PremiumPickerRow(
                                        title: "Language",
                                        subtitle: "App language",
                                        selection: $language,
                                        options: languageOptions
                                    )
                                    
                                    PremiumPickerRow(
                                        title: "Theme",
                                        subtitle: "App appearance",
                                        selection: $theme,
                                        options: themeOptions
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                            
                            // Privacy Settings Section
                            premiumPreferenceSection(
                                title: "Privacy",
                                icon: "lock.shield",
                                color: Color(red: 1.0, green: 0.42, blue: 0.42)
                            ) {
                                VStack(spacing: 16) {
                                    PremiumToggleRow(
                                        title: "Share Progress",
                                        subtitle: "Make your progress visible to others",
                                        isOn: $shareProgress
                                    )
                                    
                                    PremiumToggleRow(
                                        title: "Show Real Name",
                                        subtitle: "Display your real name in social features",
                                        isOn: $showRealName
                                    )
                                    
                                    PremiumToggleRow(
                                        title: "Allow Dietitian Messages",
                                        subtitle: "Receive messages from verified dietitians",
                                        isOn: $allowMessagesFromDietitians
                                    )
                                    
                                    PremiumToggleRow(
                                        title: "Share Workouts",
                                        subtitle: "Share your workouts with the community",
                                        isOn: $shareWorkouts
                                    )
                                }
                            }
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                            
                            // Save Button
                            premiumSaveButton()
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                            
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
                        
                        Text("Preferences saved successfully!")
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
            loadPreferences()
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
            
            Text("Preferences")
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
    private func premiumPreferenceSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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
            .padding(20)
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
        Button(action: savePreferences) {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(isSaving ? "Saving Preferences..." : "Save Preferences")
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
            
            Text("Loading preferences...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadPreferences() {
        guard let userId = session.currentUserId else { return }
        
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("preferences").document("settings").getDocument { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = snapshot?.data() {
                    // Load notification preferences
                    self.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? true
                    self.workoutReminders = data["workoutReminders"] as? Bool ?? true
                    self.mealReminders = data["mealReminders"] as? Bool ?? true
                    self.progressUpdates = data["progressUpdates"] as? Bool ?? true
                    self.socialNotifications = data["socialNotifications"] as? Bool ?? false
                    self.emailNotifications = data["emailNotifications"] as? Bool ?? true
                    
                    // Load app settings
                    self.units = data["units"] as? String ?? "Metric"
                    self.language = data["language"] as? String ?? "English"
                    self.theme = data["theme"] as? String ?? "Dark"
                    
                    // Load privacy settings
                    self.shareProgress = data["shareProgress"] as? Bool ?? false
                    self.showRealName = data["showRealName"] as? Bool ?? true
                    self.allowMessagesFromDietitians = data["allowMessagesFromDietitians"] as? Bool ?? true
                    self.shareWorkouts = data["shareWorkouts"] as? Bool ?? true
                }
            }
        }
    }
    
    private func savePreferences() {
        guard let userId = session.currentUserId else {
            errorMessage = "User not logged in"
            showError = true
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isSaving = true
        
        let preferences: [String: Any] = [
            // Notifications
            "notificationsEnabled": notificationsEnabled,
            "workoutReminders": workoutReminders,
            "mealReminders": mealReminders,
            "progressUpdates": progressUpdates,
            "socialNotifications": socialNotifications,
            "emailNotifications": emailNotifications,
            
            // App Settings
            "units": units,
            "language": language,
            "theme": theme,
            
            // Privacy
            "shareProgress": shareProgress,
            "showRealName": showRealName,
            "allowMessagesFromDietitians": allowMessagesFromDietitians,
            "shareWorkouts": shareWorkouts,
            
            "updatedAt": Timestamp()
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("preferences").document("settings").setData(preferences) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                
                if let error = error {
                    self.errorMessage = "Failed to save preferences: \(error.localizedDescription)"
                    self.showError = true
                    
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                } else {
                    self.showSuccess = true
                    
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
            }
        }
    }
}

// MARK: - Premium Preference Components

struct PremiumToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(PremiumToggleStyle())
        }
        .padding(.vertical, 8)
    }
}

struct PremiumPickerRow: View {
    let title: String
    let subtitle: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option)
                        .foregroundColor(.white)
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}

struct PremiumToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    configuration.isOn ?
                    LinearGradient(
                        colors: [
                            Color(red: 0.49, green: 0.34, blue: 1.0),
                            Color(red: 0.31, green: 0.25, blue: 0.84)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: 2, x: 0, y: 1
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isOn)
                )
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif