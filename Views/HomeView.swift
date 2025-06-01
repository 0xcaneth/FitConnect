import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @State private var showContent = false
    @State private var animateProgress = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background (#0B0D17 → #1A1B25)
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top Bar & Greeting
                        topBarSection(geometry: geometry)
                        
                        // Daily Motivation Card
                        dailyMotivationSection()
                        
                        // Today's Progress Section
                        todaysProgressSection()
                        
                        // Quick Actions Grid
                        quickActionsSection()
                        
                        // Recent Activity List
                        recentActivitySection()
                        
                        // Bottom spacing
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateProgress = true
                }
            }
        }
    }
    
    // MARK: - Top Bar & Greeting
    @ViewBuilder
    private func topBarSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 16) {
            // Header (Safe-area top)
            HStack {
                // Left: circular "Run" icon in purple-blue gradient
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.43, green: 0.31, blue: 1.0), // #6E4EFF
                                        Color(red: 0.0, green: 0.9, blue: 1.0)   // #00E5FF
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text("FitConnect")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                }
                
                Spacer()
                
                // Right: notification bell + circular avatar
                HStack(spacing: 16) {
                    // Notification bell with coral red dot
                    Button(action: {}) {
                        ZStack {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                            
                            // Coral red dot for unread
                            Circle()
                                .fill(Color(red: 1.0, green: 0.23, blue: 0.19)) // #FF3B30
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                        }
                    }
                    
                    // Circular avatar placeholder
                    Button(action: {}) {
                        Circle()
                            .fill(Color(red: 0.27, green: 0.27, blue: 0.27)) // #444444
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color(red: 0.43, green: 0.31, blue: 1.0), lineWidth: 2) // #6E4EFF
                            )
                            .overlay(
                                Text("C")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3), value: showContent)
            
            // Greeting Section
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Good Morning, Catherine! 🌅")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                    
                    Text("Ready to conquer today's fitness goals?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(x: showContent ? 0 : -10)
            .animation(.easeOut(duration: 0.3).delay(0.1), value: showContent)
        }
    }
    
    // MARK: - Daily Motivation Card
    @ViewBuilder
    private func dailyMotivationSection() -> some View {
        // Card with gradient from #FF9F0A (@20%) → #FF3B30 (@20%) → transparent
        HStack(spacing: 12) {
            // Left Icon: quote bubble in #FF9F0A
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.3)) // #FF9F0A @30%
                    .frame(width: 44, height: 44)
                
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.62, blue: 0.04)) // #FF9F0A
            }
            
            // Text content
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
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
            }
            
            Spacer()
            
            // Right Icon: heart outline - toggle to heart.fill on tap
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                // TODO: Toggle heart state
            }) {
                Image(systemName: "heart")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 1.0, green: 0.23, blue: 0.19)) // #FF3B30
            }
        }
        .padding(16)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.62, blue: 0.04).opacity(0.2), // #FF9F0A @20%
                            Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.2), // #FF3B30 @20%
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 1.0, green: 0.23, blue: 0.19), lineWidth: 1) // #FF3B30
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(0.2), value: showContent)
    }
    
    // MARK: - Today's Progress Section
    @ViewBuilder
    private func todaysProgressSection() -> some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                
                Spacer()
                
                Button("View All") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.3), value: showContent)
            
            // Horizontal scroll of metric tiles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Calories Tile
                    MetricTile(
                        icon: "flame.fill",
                        iconColor: Color(red: 0.49, green: 1.0, blue: 0.0), // #7CFF00 Neon-Green
                        value: "1,347 kcal",
                        progress: 0.73,
                        progressColor: Color(red: 0.49, green: 1.0, blue: 0.0),
                        animateProgress: animateProgress
                    )
                    
                    // Steps Tile
                    MetricTile(
                        icon: "figure.walk",
                        iconColor: Color(red: 0.96, green: 0.96, blue: 0.98), // #F5F5F7 Soft White
                        iconBackgroundColor: Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.2), // #6E4EFF @20%
                        value: "8,420 steps",
                        progress: 0.84,
                        progressColor: Color(red: 0.49, green: 1.0, blue: 0.0), // Neon-Green
                        animateProgress: animateProgress
                    )
                    
                    // Water Tile
                    MetricTile(
                        icon: "drop.fill",
                        iconColor: Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF Azure Blue
                        value: "2.1 liters",
                        progress: 0.52,
                        progressColor: Color(red: 0.0, green: 0.9, blue: 1.0), // Azure Blue
                        animateProgress: animateProgress
                    )
                }
                .padding(.horizontal, 16)
            }
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.4), value: showContent)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Quick Actions Grid
    @ViewBuilder
    private func quickActionsSection() -> some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.5), value: showContent)
            
            // 2×2 Grid of Action Cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                QuickActionCard(
                    icon: "plus.circle.fill",
                    iconColor: Color(red: 0.49, green: 1.0, blue: 0.0), // #7CFF00
                    borderGradient: [Color(red: 0.49, green: 1.0, blue: 0.0), Color(red: 0.0, green: 0.9, blue: 1.0)],
                    title: "Log Workout",
                    subtitle: "Track your exercise"
                )
                
                QuickActionCard(
                    icon: "camera.circle.fill",
                    iconColor: Color(red: 1.0, green: 0.62, blue: 0.04), // #FF9F0A
                    borderGradient: [Color(red: 1.0, green: 0.62, blue: 0.04), Color(red: 1.0, green: 0.23, blue: 0.19)],
                    title: "Scan Meal",
                    subtitle: "Log your nutrition"
                )
                
                QuickActionCard(
                    icon: "chart.bar.fill",
                    iconColor: Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                    borderGradient: [Color(red: 0.0, green: 0.9, blue: 1.0), Color(red: 0.43, green: 0.31, blue: 1.0)],
                    title: "View Progress",
                    subtitle: "Check your stats"
                )
                
                QuickActionCard(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: Color(red: 0.79, green: 0.39, blue: 1.0), // #C964FF
                    borderGradient: [Color(red: 0.79, green: 0.39, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)],
                    title: "Chat Support",
                    subtitle: "Get help & tips"
                )
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.6), value: showContent)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Recent Activity List
    @ViewBuilder
    private func recentActivitySection() -> some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                
                Spacer()
                
                Button("See All") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.7), value: showContent)
            
            // Vertical List of 3 Items
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "figure.run",
                    iconColor: Color(red: 0.49, green: 1.0, blue: 0.0), // #7CFF00
                    title: "Morning Run",
                    subtitle: "5.2 km · 28 minutes",
                    time: "2 h ago"
                )
                
                ActivityRow(
                    icon: "dumbbell.fill",
                    iconColor: Color(red: 1.0, green: 0.62, blue: 0.04), // #FF9F0A
                    title: "Strength Training",
                    subtitle: "Upper body workout",
                    time: "Yesterday"
                )
                
                ActivityRow(
                    icon: "heart.circle.fill",
                    iconColor: Color(red: 0.79, green: 0.39, blue: 1.0), // #C964FF
                    title: "Yoga Session",
                    subtitle: "30 min meditation",
                    time: "2 days ago"
                )
            }
            .padding(.horizontal, 16)
            .opacity(showContent ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.3).delay(0.8), value: showContent)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Metric Tile Component
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
                // Icon (top-left)
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
                
                // Value
                Text(value)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                
                // Progress percentage
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(progressColor)
                
                // Mini Progress Bar (6pt high, ~tileWidth×0.7)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.6)) // #333 @60%
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
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9)) // #1E1E26 @90%
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Quick Action Card Component
    struct QuickActionCard: View {
        let icon: String
        let iconColor: Color
        let borderGradient: [Color]
        let title: String
        let subtitle: String
        
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
                                .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text(subtitle)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                            
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
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9)) // #1E1E26 @90%
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
    
    // MARK: - Activity Row Component
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
                    // Icon (left, 12pt inset)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.96, green: 0.96, blue: 0.98)) // #F5F5F7
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                    }
                    
                    Spacer()
                    
                    // Time (right)
                    Text(time)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color(red: 0.53, green: 0.53, blue: 0.53)) // #888888
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.9)) // #1E1E26 @90%
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
#endif
