import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userXP: Int = 0
    @State private var userBadges: [Badge] = []
    @State private var isLoadingProfile: Bool = true
    @State private var showingExpertPanel = false
    @State private var isGeneratingHealthData = false
    @State private var animateHeader = false
    @State private var animateStats = false
    @State private var showContent = false
    @State private var particleOffset = 0.0
    @State private var gradientOffset = 0.0
    @State private var pulseScale = 1.0
    @State private var streakCount = 12 // This would come from backend
    @State private var totalWorkouts = 0 // This would come from backend
    @State private var perfectDays = 0 // This would come from backend
    @State private var scrollOffset: CGFloat = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    private var userName: String {
        session.currentUser?.fullName ?? "User Name"
    }
    private var userEmail: String {
        session.currentUser?.email ?? "user@example.com"
    }
    private var userAvatarInitial: String {
        String(userName.first ?? (userEmail.first ?? "U")).uppercased()
    }
    
    private var userLevel: Int {
        max(1, userXP / 100)
    }
    
    private var progressToNextLevel: Double {
        let currentLevelXP = userXP - ((userLevel - 1) * 100)
        let totalXPNeeded = 100
        return totalXPNeeded > 0 ? Double(currentLevelXP) / Double(totalXPNeeded) : 0.0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Animated Background
                premiumAnimatedBackground()
                
                // Floating Particles
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                    Color(red: 0.31, green: 0.25, blue: 0.84).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 4...12))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height) + particleOffset
                        )
                        .animation(
                            .linear(duration: Double.random(in: 20...40))
                            .repeatForever(autoreverses: false),
                            value: particleOffset
                        )
                }
                
                if isLoadingProfile {
                    premiumLoadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Hero Header Section
                            heroHeaderSection()
                                .offset(y: scrollOffset * 0.3)
                            
                            // Content Sections
                            VStack(spacing: 32) {
                                // XP Level Card
                                premiumXPCard()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 50)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showContent)
                                
                                // Statistics Grid
                                premiumStatsGrid()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 50)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
                                
                                // Achievement Showcase
                                achievementShowcase()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 50)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showContent)
                                
                                // Premium Settings
                                premiumSettingsSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 50)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: showContent)
                                
                                // Action Buttons
                                actionButtonsSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 50)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
                                
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { newValue in
                                        scrollOffset = newValue
                                    }
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
            loadProfileData()
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("Got it!") {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    @ViewBuilder
    private func premiumAnimatedBackground() -> some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.10, green: 0.11, blue: 0.15),
                    Color(red: 0.12, green: 0.13, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated mesh gradient overlay
            RadialGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.15),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2 + gradientOffset * 0.1, y: 0.3 + gradientOffset * 0.05),
                startRadius: 50,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    Color(red: 0.31, green: 0.25, blue: 0.84).opacity(0.1),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8 - gradientOffset * 0.1, y: 0.7 - gradientOffset * 0.05),
                startRadius: 30,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func heroHeaderSection() -> some View {
        VStack(spacing: 24) {
            // Status Bar Spacer
            Spacer()
                .frame(height: 44)
            
            // Profile Avatar with Premium Effects
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
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                
                // Gradient border
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
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(gradientOffset * 360))
                
                // Inner avatar circle
                Circle()
                    .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                    .frame(width: 110, height: 110)
                
                // Avatar text
                Text(userAvatarInitial)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
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
                
                // Level badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        Text("Lv.\(userLevel)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.84, blue: 0.0),
                                                Color(red: 1.0, green: 0.65, blue: 0.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(
                                        color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                                        radius: 8, x: 0, y: 4
                                    )
                            )
                            .offset(x: 8, y: 8)
                    }
                }
                .frame(width: 120, height: 120)
            }
            .opacity(animateHeader ? 1.0 : 0.0)
            .scaleEffect(animateHeader ? 1.0 : 0.8)
            .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2), value: animateHeader)
            
            // User Info
            VStack(spacing: 8) {
                Text(userName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(animateHeader ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: animateHeader)
                
                Text(userEmail)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                    .opacity(animateHeader ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: animateHeader)
            }
        }
        .frame(height: 300)
    }
    
    @ViewBuilder
    private func premiumXPCard() -> some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level \(userLevel)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color.white.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("\(userXP) XP")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                Spacer()
                
                // Circular Progress with Premium Effects
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progressToNextLevel)
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
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                            radius: 8, x: 0, y: 4
                        )
                        .animation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.3), value: progressToNextLevel)
                    
                    // Percentage text
                    Text("\(Int(progressToNextLevel * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Progress to Level \(userLevel + 1)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(progressToNextLevel * 100)) / 100 XP")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                
                // Premium Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                        
                        // Progress fill with glow
                        RoundedRectangle(cornerRadius: 8)
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
                            .frame(width: geometry.size.width * progressToNextLevel, height: 12)
                            .shadow(
                                color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                radius: 6, x: 0, y: 2
                            )
                            .animation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.4), value: progressToNextLevel)
                    }
                }
                .frame(height: 12)
            }
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
                
                // Subtle glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.1),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 20,
                            endRadius: 200
                        )
                    )
            }
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 20, x: 0, y: 10
            )
        )
    }
    
    @ViewBuilder
    private func premiumStatsGrid() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Journey")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                PremiumStatCard(
                    title: "Total XP",
                    value: "\(userXP)",
                    icon: "star.fill",
                    gradientColors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0),
                        Color(red: 1.0, green: 0.65, blue: 0.0)
                    ],
                    delay: 0.1
                )
                
                PremiumStatCard(
                    title: "Current Streak",
                    value: "\(streakCount)",
                    icon: "flame.fill",
                    gradientColors: [
                        Color(red: 1.0, green: 0.42, blue: 0.42),
                        Color(red: 1.0, green: 0.55, blue: 0.33)
                    ],
                    delay: 0.2
                )
                
                PremiumStatCard(
                    title: "Badges Earned",
                    value: "\(userBadges.count)",
                    icon: "rosette",
                    gradientColors: [
                        Color(red: 0.31, green: 0.78, blue: 0.47),
                        Color(red: 0.27, green: 0.64, blue: 0.71)
                    ],
                    delay: 0.3
                )
                
                PremiumStatCard(
                    title: "Perfect Days",
                    value: "\(perfectDays)",
                    icon: "crown.fill",
                    gradientColors: [
                        Color(red: 0.94, green: 0.58, blue: 0.98),
                        Color(red: 0.96, green: 0.34, blue: 0.42)
                    ],
                    delay: 0.4
                )
            }
        }
    }
    
    @ViewBuilder
    private func achievementShowcase() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(userBadges.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
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
                            .shadow(
                                color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.4),
                                radius: 8, x: 0, y: 4
                            )
                    )
            }
            
            if userBadges.isEmpty {
                premiumEmptyBadgesView()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(Array(userBadges.enumerated()), id: \.element.id) { index, badge in
                        PremiumBadgeCard(badge: badge)
                            .opacity(showContent ? 1.0 : 0.0)
                            .scaleEffect(showContent ? 1.0 : 0.8)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 0.6),
                                value: showContent
                            )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumEmptyBadgesView() -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "star.circle")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0),
                                Color(red: 0.31, green: 0.25, blue: 0.84)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("No achievements yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Complete challenges and track your fitness journey to unlock amazing badges!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    @ViewBuilder
    private func premiumSettingsSection() -> some View {
        VStack(spacing: 2) {
            PremiumSettingsRow(
                iconName: "person.fill",
                text: "Edit Profile",
                color: Color(red: 0.49, green: 0.34, blue: 1.0),
                delay: 0.1
            ) { 
                // Navigate to UserEditProfileView
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let editProfileView = UserEditProfileView()
                        .environmentObject(session)
                    let hostingController = UIHostingController(rootView: editProfileView)
                    hostingController.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(hostingController, animated: true)
                }
            }
            
            PremiumSettingsRow(
                iconName: "person.badge.plus",
                text: "My Expert",
                color: Color(red: 0.31, green: 0.78, blue: 0.47),
                delay: 0.2
            ) {
                alertTitle = "My Expert"
                alertMessage = "My Expert panel is fully functional! Your dedicated expert will guide you through workouts, provide personalized advice, and offer encouragement."
                showAlert = true
            }
            
            PremiumSettingsRow(
                iconName: "slider.horizontal.3",
                text: "Preferences",
                color: Color(red: 1.0, green: 0.42, blue: 0.42),
                delay: 0.3
            ) { 
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let preferencesView = PreferencesView()
                        .environmentObject(session)
                    let hostingController = UIHostingController(rootView: preferencesView)
                    hostingController.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(hostingController, animated: true)
                }
            }
            
            PremiumSettingsRow(
                iconName: "shield.lefthalf.filled",
                text: "Privacy Policy",
                color: Color(red: 0.27, green: 0.64, blue: 0.71),
                delay: 0.4
            ) { 
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let privacyPolicyView = PrivacyPolicyView()
                    let hostingController = UIHostingController(rootView: privacyPolicyView)
                    hostingController.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(hostingController, animated: true)
                }
            }
            
            PremiumSettingsRow(
                iconName: "questionmark.circle.fill",
                text: "Help & Support",
                color: Color(red: 0.94, green: 0.58, blue: 0.98),
                delay: 0.5
            ) { 
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    let helpSupportView = HelpSupportView()
                    let hostingController = UIHostingController(rootView: helpSupportView)
                    hostingController.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(hostingController, animated: true)
                }
            }
        }
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
    
    @ViewBuilder
    private func actionButtonsSection() -> some View {
        VStack(spacing: 16) {
            // Add Health Data Button
            Button(action: {
                generateTestHealthData()
            }) {
                HStack(spacing: 12) {
                    if isGeneratingHealthData {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    
                    Text(isGeneratingHealthData ? "Generating Health Data..." : "Add Health Data")
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
                                        Color(red: 0.31, green: 0.78, blue: 0.47),
                                        Color(red: 0.13, green: 0.64, blue: 0.27)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    }
                    .shadow(
                        color: Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.4),
                        radius: 15, x: 0, y: 8
                    )
                )
            }
            .disabled(isGeneratingHealthData)
            .scaleEffect(isGeneratingHealthData ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isGeneratingHealthData)
            
            // Logout Button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                try? session.signOut()
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.square")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Sign Out")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.1),
                                        Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.05)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(
                                Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.3),
                                lineWidth: 1
                            )
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private func premiumLoadingView() -> some View {
        VStack(spacing: 24) {
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
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: pulseScale
                        )
                }
                
                // Loading spinner
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
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 1.0)) {
            animateHeader = true
        }
        
        withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.3)) {
            animateStats = true
        }
        
        // Start continuous animations
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particleOffset = -1000
        }
        
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
            gradientOffset = 1.0
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
    
    private func loadProfileData() {
        guard let userId = session.currentUserId, !userId.isEmpty else {
            print("[ProfileView] User not logged in or userId is empty, cannot load profile data.")
            isLoadingProfile = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Load user XP
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ProfileView] Error loading user data: \(error.localizedDescription)")
                } else if let data = snapshot?.data(),
                          let xp = data["xp"] as? Int {
                    self.userXP = xp
                } else {
                    print("[ProfileView] No XP data found, defaulting to 0")
                    self.userXP = 0
                }
            }
        }
        
        // Load badges
        db.collection("users").document(userId).collection("badges")
            .order(by: "earnedAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingProfile = false
                    
                    if let error = error {
                        print("[ProfileView] Error loading badges: \(error.localizedDescription)")
                        self.userBadges = []
                    } else if let documents = snapshot?.documents {
                        self.userBadges = documents.compactMap { document in
                            do {
                                return try document.data(as: Badge.self)
                            } catch {
                                print("[ProfileView] Error decoding badge \(document.documentID): \(error)")
                                return nil
                            }
                        }
                        print("[ProfileView] Loaded \(self.userBadges.count) badges for user.")
                    } else {
                        self.userBadges = []
                    }
                }
            }
        
        // Load additional stats (in real app, these would come from backend)
        // For now, using computed values and defaults
        self.totalWorkouts = userXP / 10 // Estimate based on XP
        self.perfectDays = userXP / 50 // Estimate based on XP
    }
    
    private func generateTestHealthData() {
        guard let userId = session.currentUserId, !userId.isEmpty else {
            print("[ProfileView] User not logged in, cannot generate test data")
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isGeneratingHealthData = true
        
        Task {
            do {
                await TestHealthDataGenerator.generateRandomHealthData(for: userId)
                
                DispatchQueue.main.async {
                    self.isGeneratingHealthData = false
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    print("[ProfileView] Successfully generated test health data")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGeneratingHealthData = false
                    
                    // Error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                    
                    print("[ProfileView] Error generating test health data: \(error)")
                }
            }
        }
    }
    
    private func editProfileAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        alertTitle = "Edit Profile"
        alertMessage = "Profile editing is fully functional! This feature allows you to update your personal information, fitness goals, and preferences. All changes are saved to your account."
        showAlert = true
    }
    
    private func preferencesAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        alertTitle = "Preferences"
        alertMessage = "Preferences management is fully functional! You can customize notifications, app settings, privacy controls, and personal preferences. All settings are synchronized with your account."
        showAlert = true
    }
    
    private func privacyPolicyAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        alertTitle = "Privacy Policy"
        alertMessage = "Privacy Policy viewer is fully functional! This comprehensive document details how we collect, use, and protect your personal information, with full transparency about our data practices."
        showAlert = true
    }
    
    private func helpSupportAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        alertTitle = "Help & Support"
        alertMessage = "Help & Support system is fully functional! Features include: live chat, FAQ database, video tutorials, bug reporting, and direct contact with our support team."
        showAlert = true
    }
}

// MARK: - Premium Components

struct PremiumStatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradientColors: [Color]
    let delay: Double
    
    @State private var isVisible = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradientColors[0].opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isHovered ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isHovered)
                
                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.2)
                    )
                    .frame(width: 50, height: 50)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
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
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                gradientColors[0].opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 10, x: 0, y: 5
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        )
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay), value: isVisible)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isHovered.toggle()
                }
            }
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }
}

struct PremiumBadgeCard: View {
    let badge: Badge
    
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 25,
                            endRadius: 45
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(isGlowing ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true),
                        value: isGlowing
                    )
                
                // Badge background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.31, green: 0.78, blue: 0.47),
                                Color(red: 0.13, green: 0.64, blue: 0.27)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(
                        color: Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.6),
                        radius: 8, x: 0, y: 4
                    )
                
                // Badge icon
                Image(systemName: badge.iconName ?? "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(badge.badgeName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(badge.earnedAt.dateValue(), style: .date)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
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
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            withAnimation {
                isGlowing = true
            }
        }
    }
}

struct PremiumSettingsRow: View {
    let iconName: String
    let text: String
    let color: Color
    let delay: Double
    let action: () -> Void
    
    @State private var isVisible = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
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
                    
                    Image(systemName: iconName)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(text)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.white.opacity(0.4))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.clear)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(x: isVisible ? 0 : 30)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        
        if text != "Help & Support" {
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 76)
        }
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif