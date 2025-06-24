import SwiftUI
import HealthKit

@available(iOS 16.0, *)
struct HomeView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var homeViewModel = HomeViewModel(healthKitManager: HealthKitManager(sessionStore: SessionStore.previewStore()))
    @State private var showingNotifications = false
    @State private var showingStats = false
    @State private var showingLogMeal = false
    @State private var showingScanMeal = false
    @State private var isFABExpanded = false
    @State private var showingLogMealSheet = false
    @State private var bottomSheetDetent: PresentationDetent = .height(400)

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header with greeting and notification
                        headerView
                        
                        // HealthKit Permission Banner
                        if homeViewModel.showHealthDataBanner {
                            healthKitBannerView
                        }
                        
                        // Motivational Quote Card
                        motivationalQuoteView
                        
                        // Today's Progress Carousel
                        todaysProgressView
                        
                        // Quick Actions Grid
                        quickActionsView
                        
                        // Recent Activity Section
                        recentActivityView
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .background(
                    Color(hex: "#0D0F14")
                        .ignoresSafeArea()
                )
                .refreshable {
                    Task {
                        if let userId = session.currentUserId {
                            await homeViewModel.loadTodayData(for: userId)
                        }
                    }
                }
                
                // Floating Action Button
                HomeFloatingActionButtonView(
                    isExpanded: $isFABExpanded,
                    onLogMeal: { showingLogMeal = true },
                    onStartWorkout: { /* TODO: Start workout */ }
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
        .sheet(isPresented: $showingLogMeal) {
            LogMealView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showingScanMeal) {
            ScanMealView()
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsView()
        }
        .sheet(isPresented: $showingLogMealSheet) {
            LogMealSheetView(
                detectedFood: "",
                estimatedCalories: 0,
                onDismiss: { showingLogMealSheet = false }
            )
            .presentationDetents([.height(400), .height(600), .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
        }
        .onAppear {
            homeViewModel.healthKitManager = healthKitManager
            Task {
                if let userId = session.currentUserId {
                    await homeViewModel.loadTodayData(for: userId)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(homeViewModel.greetingText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Ready to conquer today's goals?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button(action: {
                showingNotifications = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1A1B25") ?? .gray)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    if session.unreadNotificationCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
    }
    
    private var healthKitBannerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(hex: "#FF8C00"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("HealthKit access needed")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Enable to see your live health data")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button("Enable") {
                homeViewModel.requestHealthKitPermission()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FF4500") ?? .orange, Color(hex: "#FF7A00") ?? .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1A1B25") ?? .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#FF8C00") ?? .orange, lineWidth: 2)
                )
        )
        .shadow(color: Color(hex: "#FF8C00").opacity(0.25), radius: 8, x: 0, y: 3)
        .transition(.move(edge: .top))
        .animation(.easeInOut(duration: 0.3), value: homeViewModel.showHealthDataBanner)
    }
    
    private var motivationalQuoteView: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)
            
            Text("Every step counts towards your fitness journey!")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: {
                // Toggle favorite with animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    // homeViewModel.toggleQuoteFavorite()
                }
            }) {
                Image(systemName: "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FF4500") ?? .orange, Color(hex: "#FF7A00") ?? .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(16)
        .shadow(color: Color(hex: "#FF7A00").opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    private var todaysProgressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            TabView {
                // Steps Card
                ProgressCardView(
                    iconName: "figure.walk",
                    value: homeViewModel.todaySteps,
                    goal: 10000,
                    unit: "steps",
                    accentColor: Color(hex: "#00C851") ?? .green,
                    isCenter: true
                )
                
                // Calories Card
                ProgressCardView(
                    iconName: "flame.fill",
                    value: homeViewModel.todayCalories,
                    goal: 500,
                    unit: "kcal",
                    accentColor: Color(hex: "#FF4500") ?? .orange,
                    isCenter: true
                )
                
                // Water Card
                ProgressCardView(
                    iconName: "drop.fill",
                    value: homeViewModel.todayWaterMl,
                    goal: 2000,
                    unit: "mL",
                    accentColor: Color(hex: "#0099FF") ?? .blue,
                    isCenter: true
                )
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 340)
        }
    }
    
    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                HomeQuickActionCard(
                    icon: "camera.fill",
                    title: "Scan Meal",
                    color: Color(hex: "#FF4500") ?? .orange
                ) {
                    showingScanMeal = true
                }
                
                HomeQuickActionCard(
                    icon: "fork.knife",
                    title: "Log Meal",
                    color: Color(hex: "#00E5FF") ?? .cyan
                ) {
                    showingLogMeal = true
                }
                
                HomeQuickActionCard(
                    icon: "chart.bar.fill",
                    title: "Stats",
                    color: Color(hex: "#0099FF") ?? .blue
                ) {
                    showingStats = true
                }
                
                HomeQuickActionCard(
                    icon: "message.fill",
                    title: "Chat w/ Dietitian",
                    color: Color(hex: "#7C4DFF") ?? .purple
                ) {
                    // TODO: Navigate to chat
                }
            }
        }
    }
    
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    // TODO: Show all activities
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#7C4DFF"))
            }
            
            VStack(spacing: 20) {
                Image(systemName: "star")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                
                Text("No recent activity yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text("Complete workouts and log meals to see your activity here.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#0D0F14") ?? .black)
            )
        }
    }
}

struct HomeQuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPressed.toggle()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed.toggle()
                }
            }
            
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.8))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#1A1B25") ?? .gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 1.05 : 1.0)
        }
    }
}

struct HomeFloatingActionButtonView: View {
    @Binding var isExpanded: Bool
    let onLogMeal: () -> Void
    let onStartWorkout: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isExpanded {
                // Start Workout Pill
                Button(action: onStartWorkout) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "#00C851") ?? .green)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "figure.walk")
                                    .foregroundColor(.white)
                            )
                        
                        Text("Start Workout")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 160, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#00C851").opacity(0.9))
                    )
                    .shadow(color: Color(hex: "#00C851").opacity(0.25), radius: 8, x: 0, y: 2)
                }
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isExpanded)
                
                // Log Meal Pill
                Button(action: onLogMeal) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "#00E5FF") ?? .cyan)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "fork.knife")
                                    .foregroundColor(.white)
                            )
                        
                        Text("Log Meal")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#00E5FF").opacity(0.9))
                    )
                    .shadow(color: Color(hex: "#00E5FF").opacity(0.25), radius: 8, x: 0, y: 2)
                }
                .opacity(isExpanded ? 1 : 0)
                .scaleEffect(isExpanded ? 1 : 0.8)
                .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1), value: isExpanded)
            }
            
            // Main FAB
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isExpanded.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#7C4DFF") ?? .purple)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.purple.opacity(0.25), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(.trailing, 16)
        .padding(.bottom, 32)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore()
        let mockHealthKitManager = HealthKitManager(sessionStore: mockSession)
        let mockPostService = PostService.shared
        mockPostService.configure(sessionStore: mockSession)

        return HomeView()
            .environmentObject(mockSession)
            .environmentObject(mockHealthKitManager)
            .environmentObject(mockPostService)
            .preferredColorScheme(.dark)
    }
}
#endif