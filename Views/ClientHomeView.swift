import SwiftUI
import FirebaseAuth
import HealthKit
import FirebaseFirestore

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
    @State private var showingProfile = false
    @State private var unreadNotificationCount = 1 // Example
    @State private var currentChatId: String?
    @State private var chatPresentation: ChatPresentationItem? = nil
    @State private var showChatCreationErrorAlert = false
    @State private var showingNotifications: Bool = false 

    struct ChatPresentationItem: Identifiable {
        let id: String // This will be the chatId
    }

    // CORRECTED init block
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    struct MotivationalQuote {
        let text: String
        let author: String?
    }

    @State private var currentMotivation: MotivationalQuote = MotivationalQuote(text: "Loading...", author: nil)
    @State private var motivationTimer: Timer?

    private let motivationalQuotes: [MotivationalQuote] = [
        MotivationalQuote(text: "The only bad workout is the one that didn't happen.", author: "Anonymous"),
        MotivationalQuote(text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt"),
        MotivationalQuote(text: "The body achieves what the mind believes.", author: nil),
        MotivationalQuote(text: "Push yourself, because no one else is going to do it for you.", author: nil),
        MotivationalQuote(text: "Success isn't always about greatness. It's about consistency. Consistent hard work gains success. Greatness will come.", author: "Dwayne Johnson"),
        MotivationalQuote(text: "The pain you feel today will be the strength you feel tomorrow.", author: nil),
        MotivationalQuote(text: "Don't watch the clock; do what it does. Keep going.", author: "Sam Levenson")
    ]

    @State private var recentActivities: [UserActivity] = []
    @State private var isLoadingActivities: Bool = false

    struct UserActivity: Identifiable, Codable { // Codable if fetching from Firestore directly
        @DocumentID var id: String? // Firestore document ID
        var userId: String
        var type: String // e.g., "workout", "achievement", "badge"
        var title: String
        var description: String
        var iconName: String
        var iconColorHex: String? // Optional, can fallback to type-based color
        var timestamp: Timestamp
    }

    var body: some View {
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
                    Button(action: {
                        showingNotifications = true
                        // Optionally reset unread count here or when NotificationsView appears/disappears
                        // unreadNotificationCount = 0 
                    }) {
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
            .sheet(isPresented: $showingNotifications) {
                NotificationsView()
                // Potentially pass environment objects if needed by NotificationsView
                // .environmentObject(session) 
            }
            .sheet(item: $chatPresentation) { item in
                if #available(iOS 16.0, *) {
                    ChatView(chatId: item.id)
                        .environmentObject(session)
                } else {
                    // Fallback for earlier versions
                    Text("Chat feature requires iOS 16 or later.")
                }
            }
            .alert("Chat Error", isPresented: $showChatCreationErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Unable to create or find the chat. Please try again.")
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
                setupMotivation()
                startMotivationTimer()
                if recentActivities.isEmpty { // Fetch only if not already loaded
                    loadRecentActivities()
                }
            }
            .onDisappear {
                stopMotivationTimer()
            }
        }
    }

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
                
                Text(currentMotivation.text)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white)
                    .lineLimit(3) // Allow more lines for longer quotes
                    .fixedSize(horizontal: false, vertical: true) // Ensure text wraps
                
                if let author = currentMotivation.author, !author.isEmpty, author.lowercased() != "anonymous" {
                    Text("— \(author)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
                }
            }
            
            Spacer()
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                updateMotivationQuote()
            }) {
                Image(systemName: "heart") // Or use "arrow.clockwise.circle" for refresh
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19))
            }
        }
        .padding(16)
        .frame(minHeight: 100) // Set a minHeight, but allow it to grow
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
                    findOrCreateChatWithDietitian { success in
                        if success, let confirmedChatId = self.currentChatId {
                            print("[ClientHomeView] Chat prepared successfully. Confirmed Chat ID: \(confirmedChatId). Presenting sheet.")
                            self.chatPresentation = ChatPresentationItem(id: confirmedChatId)
                        } else {
                            print("[ClientHomeView] Failed to prepare chat. currentChatId: \(String(describing: self.currentChatId)). Not showing chat sheet.")
                            self.showChatCreationErrorAlert = true
                        }
                    }
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
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                
                Spacer()
                
                NavigationLink(destination: AllActivitiesView().environmentObject(session)) {
                    Text("See All")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#6E56E9"))
                }
                .simultaneousGesture(TapGesture().onEnded { // Optional: for haptic feedback if needed
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                })
            }
            .padding(.horizontal, 20)
            
            if isLoadingActivities {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#6E56E9")))
                    .padding(.vertical, 20)
            } else if recentActivities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.star")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(Color.gray.opacity(0.5))
                    Text("No recent activity yet.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Color.gray)
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 12) {
                    ForEach(recentActivities.prefix(3)) { activity in // Show max 3 recent activities
                        ActivityRow(
                            icon: activity.iconName,
                            // Use iconColorHex if available, otherwise a default
                            iconColor: activity.iconColorHex != nil ? Color(hex: activity.iconColorHex!) ?? .gray : colorForActivityType(activity.type),
                            title: activity.title,
                            subtitle: activity.description,
                            time: formatTimestamp(activity.timestamp) // Use a helper for relative time
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
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
    
    private func findOrCreateChatWithDietitian(completion: @escaping (Bool) -> Void) {
        print("[DEBUG] findOrCreateChatWithDietitian() called")
        
        guard !session.currentUserId.isEmpty else {
            print("[ClientHomeView] User not logged in, cannot create chat.")
            print("[DEBUG] session.currentUserId is empty: '\(session.currentUserId)'")
            completion(false)
            return
        }
        
        print("[DEBUG] session.currentUserId: '\(session.currentUserId)'")
        
        let clientId = session.currentUserId
        let dietitianId = session.assignedDietitianId.isEmpty ? "defaultDietitianId" : session.assignedDietitianId
        
        print("[DEBUG] clientId: '\(clientId)'")
        print("[DEBUG] dietitianId: '\(dietitianId)'")
        
        let participantIds = [clientId, dietitianId].sorted()
        let chatId = "chat_\(participantIds.joined(separator: "_"))"
        
        print("[DEBUG] Generated chatId: '\(chatId)'")
        
        self.currentChatId = chatId
        print("[DEBUG] currentChatId set to: '\(String(describing: self.currentChatId))'")
        
        let db = Firestore.firestore()
        let chatRef = db.collection("chats").document(chatId)
        
        chatRef.getDocument { document, error in
            if let error = error {
                print("[ClientHomeView] Error checking for existing chat: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if document?.exists == true {
                print("[ClientHomeView] Chat already exists.")
                completion(true)
            } else {
                let newChat = Chat(
                    participants: [clientId, dietitianId],
                    lastMessage: "",
                    updatedAt: Timestamp(date: Date()),
                    createdAt: Timestamp(date: Date())
                )
                
                do {
                    try chatRef.setData(from: newChat) { error in
                        if let error = error {
                            print("[ClientHomeView] Error creating new chat: \(error.localizedDescription)")
                            completion(false)
                        } else {
                            print("[ClientHomeView] Successfully created new chat.")
                            completion(true)
                        }
                    }
                } catch {
                    print("[ClientHomeView] Error encoding new chat: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    private func setupMotivation() {
        updateMotivationQuote() // Set initial quote
    }

    private func updateMotivationQuote() {
        currentMotivation = motivationalQuotes.randomElement() ?? MotivationalQuote(text: "Keep pushing!", author: nil)
    }

    private func startMotivationTimer() {
        // Invalidate existing timer if any
        stopMotivationTimer()
        // Create a new timer that fires every 2 minutes (120 seconds)
        motivationTimer = Timer.scheduledTimer(withTimeInterval: 120.0, repeats: true) { _ in
            withAnimation { // Add animation for a smoother transition
                updateMotivationQuote()
            }
        }
    }

    private func stopMotivationTimer() {
        motivationTimer?.invalidate()
        motivationTimer = nil
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
                HStack {
                    ZStack {
                        if let backgroundColor = iconBackgroundColor {
                            Circle()
                                .fill(backgroundColor)
                                .frame(width: 36, height: 36) // Slightly larger icon background
                        }
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium)) // Adjusted icon size
                            .foregroundColor(iconColor)
                    }
                    Spacer()
                    // Optional: Place percentage here if desired
                    // Text("\(Int(progress * 100))%")
                    //     .font(.system(size: 14, weight: .bold, design: .rounded))
                    //     .foregroundColor(progressColor)
                }
                
                Spacer() 
                
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded)) // SF Pro Rounded Semibold
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(progress * 100))% complete") // More descriptive text
                        .font(.system(size: 12, weight: .medium, design: .rounded)) // SF Pro Rounded Medium
                        .foregroundColor(progressColor.opacity(0.8))

                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4) // More rounded corners for the track
                            .fill(Color.white.opacity(0.15)) // Lighter track color
                            .frame(height: 8) // Thicker bar
                        
                        RoundedRectangle(cornerRadius: 4) // More rounded corners for the progress
                            .fill(progressColor)
                            .frame(width: animateProgress ? (140 - 24) * progress : 0, height: 8) // Calculate width based on parent padding
                            .animation(.easeInOut(duration: 0.8), value: animateProgress) // Slower animation
                    }
                    .frame(height: 8)
                }
            }
            .padding(12)
            .frame(width: 140, height: 110) // Adjusted height to accommodate thicker bar and text
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
                
                withAnimation(.easeInOut(duration: 0.1)) { // Faster press down
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { // Slightly longer before release
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
                
                action()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold)) // Adjusted size and weight
                        .foregroundColor(iconColor)
                        .frame(width: 40, height: 40) // Give icon a fixed frame
                        .background(iconColor.opacity(0.15)) // Subtle background for icon
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) { // Reduced spacing
                        Text(title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded)) // SF Pro Rounded Semibold
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular, design: .rounded)) // SF Pro Rounded Regular
                            .foregroundColor(Color.gray) // More subtle subtitle
                            .lineLimit(2) // Allow subtitle to wrap if needed
                    }
                    Spacer() // Push text to the left if HStack was wider
                }
                .padding(.horizontal, 16) // Consistent padding with other cards
                .padding(.vertical, 12)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(height: 88) // Adjusted height for a more compact card
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.9)) // Slightly different dark shade for card
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(colors: borderGradient, startPoint: .topLeading, endPoint: .bottomTrailing), // Changed gradient direction
                                lineWidth: 1.5 // Slightly thicker border
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3) // Adjusted shadow
            )
            .scaleEffect(isPressed ? 0.96 : 1.0) // Slightly more pronounced scale effect
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isPressed) // Adjusted spring parameters
        }
    }
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }

    private func colorForActivityType(_ type: String) -> Color {
        switch type.lowercased() {
        case "workout", "run", "strength":
            return Color(hex: "#4CAF50") ?? .green // Green for workouts
        case "achievement", "badge":
            return Color(hex: "#FFC107") ?? .yellow // Yellow for achievements
        case "yoga", "meditation":
            return Color(hex: "#9C27B0") ?? .purple // Purple for wellness
        default:
            return Color(hex: "#6E56E9") ?? .blue // Default accent
        }
    }
    
    private func loadRecentActivities() {
        isLoadingActivities = true
        let db = Firestore.firestore()
        
        db.collection("user_activities")
            .whereField("userId", isEqualTo: session.currentUserId)
            .order(by: "timestamp", descending: true)
            .limit(to: 3)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingActivities = false
                    
                    if let error = error {
                        print("[ClientHomeView] Error loading recent activities: \(error.localizedDescription)")
                        // Fallback to mock data if Firebase fails
                        self.setupMockRecentActivities()
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[ClientHomeView] No recent activities found")
                        self.recentActivities = []
                        return
                    }
                    
                    self.recentActivities = documents.compactMap { document in
                        do {
                            return try document.data(as: UserActivity.self)
                        } catch {
                            print("[ClientHomeView] Error decoding activity \(document.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    print("[ClientHomeView] Loaded \(self.recentActivities.count) recent activities from Firebase")
                    
                    // If Firebase returns empty, show mock data for demo purposes
                    if self.recentActivities.isEmpty {
                        self.setupMockRecentActivities()
                    }
                }
            }
    }
    
    private func setupMockRecentActivities() {
        self.recentActivities = [
            UserActivity(
                userId: session.currentUserId,
                type: "workout",
                title: "Morning Run",
                description: "5.2 km · 28 minutes",
                iconName: "figure.run",
                iconColorHex: nil,
                timestamp: Timestamp(date: Date().addingTimeInterval(-2 * 3600)) // 2 hours ago
            ),
            UserActivity(
                userId: session.currentUserId,
                type: "strength",
                title: "Strength Training", 
                description: "Upper body workout",
                iconName: "dumbbell.fill",
                iconColorHex: nil,
                timestamp: Timestamp(date: Date().addingTimeInterval(-5 * 3600)) // 5 hours ago
            ),
            UserActivity(
                userId: session.currentUserId,
                type: "wellness",
                title: "Yoga Session",
                description: "30 min meditation",
                iconName: "heart.circle.fill", 
                iconColorHex: nil,
                timestamp: Timestamp(date: Date().addingTimeInterval(-6 * 3600)) // 6 hours ago
            )
        ]
    }

    struct ActivityRow: View {
        let icon: String
        let iconColor: Color
        let title: String
        let subtitle: String
        let time: String
        
        var body: some View {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light) // Lighter haptic
                impactFeedback.impactOccurred()
                // TODO: Navigate to activity detail or related screen
            }) {
                HStack(spacing: 16) { // Increased spacing
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    .padding(.leading, 4) // Add a bit of leading padding for the icon
                    
                    VStack(alignment: .leading, spacing: 3) { // Reduced spacing
                        Text(title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded)) // SF Pro Rounded Semibold
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98))
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular, design: .rounded)) // SF Pro Rounded Regular
                            .foregroundColor(Color.gray) // More subtle subtitle
                            .lineLimit(2) // Allow subtitle to wrap
                    }
                    
                    Spacer()
                    
                    Text(time)
                        .font(.system(size: 12, weight: .medium, design: .rounded)) // SF Pro Rounded Medium
                        .foregroundColor(Color.gray.opacity(0.8)) // Slightly more subtle time
                        .padding(.trailing, 4) // Add a bit of trailing padding for time
                }
                .padding(.vertical, 10) // Adjusted vertical padding
                .padding(.horizontal, 8) // Adjusted horizontal padding
            }
            .buttonStyle(PlainButtonStyle())
            // Removed explicit frame(height: 60) to allow dynamic height
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#181A1F").opacity(0.9)) // Slightly different row background
                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 1) // Softer shadow for rows
            )
        }
    }
    
    #if DEBUG
    struct ClientHomeView_Previews: PreviewProvider {
        static var previews: some View {
            let mockHealthKitManager = HealthKitManager()
            mockHealthKitManager.activeEnergyBurned = 1250
            mockHealthKitManager.stepCount = 7500
            mockHealthKitManager.waterIntake = 1.5
            mockHealthKitManager.isAuthorized = true
            mockHealthKitManager.permissionStatusDetermined = true

            return NavigationView {
                ClientHomeView()
                    .environmentObject(SessionStore())
                    .environmentObject(mockHealthKitManager)
                    .preferredColorScheme(.dark)
            }
        }
    }
    #endif
}
