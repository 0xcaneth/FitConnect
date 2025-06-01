import SwiftUI
import FirebaseAuth
import HealthKit

// extension Font {
//     static func sfProRounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
//         return Font.custom("SFProRounded-\(weight.rawValue.capitalized)", size: size)
//     }
// }
// Note: You'll need to ensure "SFProRounded" fonts are actually in your project for the above to work.
// Using .system font with .rounded design for now as a fallback.

struct ClientHomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var showContent = false
    @State private var animateProgress = false
    @State private var showingChat = false
    @State private var showingProfile = false
    @State private var unreadNotificationCount = 1 // Example

    // CORRECTED init block
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        // THE BODY REMAINS UNCHANGED FROM THE LAST KNOWN GOOD STATE
        // BEFORE THE INIT() BLOCK WAS INTRODUCED
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#0D0F14") ?? .black, Color(hex: "#0D0F14") ?? .black]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        if healthKitManager.permissionStatusDetermined && !healthKitManager.isAuthorized {
                            healthKitPermissionBanner()
                        }

                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                greetingSection()
                                dailyMotivationSection()
                                todaysProgressSection()
                                quickActionsSection()
                                recentActivitySection()
                                Spacer().frame(height: 40)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                        .background(Color.clear)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "figure.run.circle.fill")
                            .foregroundColor(Color(hex: "#6E56E9"))
                            .font(.title2)
                        Text("FitConnect")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { /* Notifications */ }) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                            if unreadNotificationCount > 0 {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10)
                            }
                        }
                    }
                    Button(action: { showingProfile = true }) {
                        Circle()
                            .fill(Color(hex: "#444444"))
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color(hex: "#6E56E9"), lineWidth: 2))
                            .overlay(
                                Text(String(session.currentUser?.displayName?.first ?? (session.currentUser?.email?.first ?? "U")).uppercased())
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(session)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { showContent = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.6)) { animateProgress = true }
                }
                healthKitManager.checkAuthorizationStatus() // Re-check status
                if healthKitManager.isAuthorized {
                    healthKitManager.fetchAllTodayData()
                }
            }
            .sheet(isPresented: $showingChat) {
                if !session.assignedDietitianId.isEmpty {
                    let chatVM = ChatViewModel(clientId: session.currentUserId, dietitianId: session.assignedDietitianId, currentUserId: session.currentUserId)
                    ChatView(viewModel: chatVM)
                } else {
                    NoDietitianAssignedView()
                }
            }
        }
    } // END OF BODY

    @ViewBuilder
    private func greetingSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good Morning!") // TODO: Add user's name if available dynamically
                .font(.system(size: 28, weight: .bold, design: .rounded)) // SF Pro Rounded
                .foregroundColor(.white)
            
            Text("Ready to conquer today's fitness goals?")
                .font(.system(size: 16, design: .rounded)) // SF Pro Rounded
                .foregroundColor(Color(hex: "#B0B3BA")) // Light gray
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // .padding(.top, 20) // Removed, main VStack handles top padding
        .padding(.bottom, 16) // Space before next card
        .opacity(showContent ? 1.0 : 0.0)
        .offset(x: showContent ? 0 : -20)
        .animation(.easeOut(duration: 0.4).delay(0.1), value: showContent)
    }
    
    // MARK: - Daily Motivation Section
    @ViewBuilder
    private func dailyMotivationSection() -> some View {
        HStack(spacing: 12) {
            // ... (icon)
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.3))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Motivation")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("The only bad workout is the one that didn't happen.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("— Anonymous")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
            }
            
            Spacer()
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }) {
                Image(systemName: "heart")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
            }
        }
        .padding(16)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.2),
                            Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
    }
    
    // MARK: - Today's Progress Section
    @ViewBuilder
    private func todaysProgressSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                
                Spacer()
                
                NavigationLink(destination: ChallengesView()) {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#6E56E9")) // Accent color
                }
                .simultaneousGesture(TapGesture().onEnded {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                })
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MetricTile(
                        icon: "flame.fill",
                        iconColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                        value: "\(Int(healthKitManager.activeEnergyBurned)) kcal",
                        progress: calculateProgress(current: healthKitManager.activeEnergyBurned, goal: 2000), // Example goal
                        progressColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                        animateProgress: animateProgress
                    )
                    
                    MetricTile(
                        icon: "figure.walk",
                        iconColor: Color(red: 0.96, green: 0.96, blue: 0.98),
                        iconBackgroundColor: Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.2),
                        value: "\(Int(healthKitManager.stepCount)) steps",
                        progress: calculateProgress(current: healthKitManager.stepCount, goal: 10000), // Example goal
                        progressColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                        animateProgress: animateProgress
                    )
                    
                    MetricTile(
                        icon: "drop.fill",
                        iconColor: Color(red: 0.0, green: 0.9, blue: 1.0),
                        value: String(format: "%.1f L", healthKitManager.waterIntake),
                        progress: calculateProgress(current: healthKitManager.waterIntake, goal: 2.5), // Example goal in Liters
                        progressColor: Color(red: 0.0, green: 0.9, blue: 1.0),
                        animateProgress: animateProgress
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.3).delay(0.3), value: showContent)
    }
    
    // MARK: - Quick Actions Grid
    @ViewBuilder
    private func quickActionsSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    iconColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                    borderGradient: [Color(red: 0.49, green: 1.0, blue: 0.0), Color(red: 0.0, green: 0.9, blue: 1.0)],
                    title: "Log Workout",
                    subtitle: "Track your exercise"
                ) {
                    // TODO: Navigate to workout logging
                }
                
                QuickActionCard(
                    icon: "camera.circle.fill",
                    iconColor: Color(red: 1.0, green: 0.62, blue: 0.04),
                    borderGradient: [Color(red: 1.0, green: 0.62, blue: 0.04), Color(red: 1.0, green: 0.23, blue: 0.19)],
                    title: "Scan Meal",
                    subtitle: "Log your nutrition"
                ) {
                    // TODO: Navigate to meal scanning
                }
                
                QuickActionCard(
                    icon: "chart.bar.fill",
                    iconColor: Color(red: 0.0, green: 0.9, blue: 1.0),
                    borderGradient: [Color(red: 0.0, green: 0.9, blue: 1.0), Color(red: 0.43, green: 0.31, blue: 1.0)],
                    title: "View Progress",
                    subtitle: "Check your stats"
                ) {
                    // TODO: Navigate to progress view
                }
                
                QuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: Color(red: 0.78, green: 0.39, blue: 1.0), // #C964FF
                    borderGradient: [Color(red: 0.78, green: 0.39, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)],
                    title: "Chat with Dietitian",
                    subtitle: "Get help & tips"
                ) {
                    showingChat = true
                }
            }
            .padding(.horizontal, 20)
        }
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.3).delay(0.4), value: showContent)
    }
    
    // MARK: - Recent Activity List
    @ViewBuilder
    private func recentActivitySection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                
                Spacer()
                
                Button("See All") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0))
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "figure.run",
                    iconColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                    title: "Morning Run",
                    subtitle: "5.2 km · 28 minutes",
                    time: "2 h ago"
                )
                
                ActivityRow(
                    icon: "dumbbell.fill",
                    iconColor: Color(red: 1.0, green: 0.62, blue: 0.04),
                    title: "Strength Training",
                    subtitle: "Upper body workout",
                    time: "Yesterday"
                )
                
                ActivityRow(
                    icon: "heart.circle.fill",
                    iconColor: Color(red: 0.79, green: 0.39, blue: 1.0),
                    title: "Yoga Session",
                    subtitle: "30 min meditation",
                    time: "2 days ago"
                )
            }
            .padding(.horizontal, 20)
        }
        .opacity(showContent ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.3).delay(0.5), value: showContent)
    }

    private func calculateProgress(current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(max(current / goal, 0), 1) // Ensure progress is between 0 and 1
    }

    @ViewBuilder
    private func healthKitPermissionBanner() -> some View {
        HStack {
            Text("Grant HealthKit permission to see live data")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                healthKitManager.requestAuthorization { success, error in
                    if success {
                        print("Permission granted from banner.")
                    } else {
                        // Optionally, guide user to settings if denied multiple times
                        print("Permission denied/error from banner: \(error?.localizedDescription ?? "Unknown")")
                        // Attempt to open settings if permission was definitively denied
                        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                             UIApplication.shared.open(url)
                        }
                    }
                }
            }) {
                Text("Grant Access →")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#6E56E9")) // Use your app's accent color
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.3)) // A contrasting background
        .cornerRadius(8)
        .padding(.horizontal, 20) // Match overall padding
        .padding(.top, 10) // Space from top or toolbar
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.default, value: healthKitManager.isAuthorized)
    }
}

struct MetricTile: View {
    let icon: String
    let iconColor: Color
    let iconBackgroundColor: Color?
    let value: String
    let progress: Double
    let progressColor: Color
    let animateProgress: Bool
    
    init(
        icon: String,
        iconColor: Color,
        iconBackgroundColor: Color? = nil,
        value: String,
        progress: Double,
        progressColor: Color,
        animateProgress: Bool
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.iconBackgroundColor = iconBackgroundColor
        self.value = value
        self.progress = progress
        self.progressColor = progressColor
        self.animateProgress = animateProgress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let backgroundColor = iconBackgroundColor {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 32, height: 32)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(progressColor)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.6))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: animateProgress ? geo.size.width * 0.7 * progress : 0, height: 6)
                        .animation(.easeInOut(duration: 0.5), value: animateProgress)
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .frame(width: 140, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9))
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
    }
}

struct QuickActionCard: View {
    let icon: String
    let iconColor: Color
    let borderGradient: [Color]
    let title: String
    let subtitle: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = false
                }
            }
            
            action()
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(colors: borderGradient, startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(iconColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                }
                
                Spacer()
                
                Text(time)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct NoDietitianAssignedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.fill.questionmark")
                .font(.system(size: 60))
                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0))
            
            Text("No Dietitian Assigned")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("You haven't been assigned a dietitian yet. Please contact support for assistance.")
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.05, blue: 0.09))
    }
}

#if DEBUG
struct ClientHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockHealthKitManager = HealthKitManager()
        // Simulate some data for preview
        mockHealthKitManager.activeEnergyBurned = 1250
        mockHealthKitManager.stepCount = 7500
        mockHealthKitManager.waterIntake = 1.5
        mockHealthKitManager.isAuthorized = true // or false to test banner
        mockHealthKitManager.permissionStatusDetermined = true

        return NavigationView { // Add NavigationView for toolbar testing
            ClientHomeView()
                .environmentObject(SessionStore())
                .environmentObject(mockHealthKitManager)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
