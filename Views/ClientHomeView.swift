import SwiftUI
import HealthKit
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct ClientHomeView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var progressService = TodaysProgressService()
    @State private var showChatDetail = false
    @State private var currentChatId: String?
    @State private var showHealthKitBanner = true
    @State private var currentQuoteIndex = 0
    @State private var isHeartFilled = false
    @State private var selectedProgressCard = 0
    @State private var isCreatingChat = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingScanMeal = false
    @State private var showingLogMeal = false
    @State private var showingAppointments = false
    @State private var showingAnalytics = false
    @State private var showingWorkout = false
    
    // Nike-Killer Animation States
    @State private var headerOffset: CGFloat = 0
    @State private var showGreeting = false
    @State private var progressAnimations: [Bool] = Array(repeating: false, count: 4)
    @State private var actionButtonScale: [Double] = Array(repeating: 1.0, count: 6)
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // SMART: Hero section with scroll-aware behavior
                    nikeKillerHeroSection
                        .offset(y: max(-headerOffset * 0.5, -100)) // Parallax with limit
                       
                        .scaleEffect(max(1 - (headerOffset / 1000), 0.9)) // Subtle scale
                    
                    // DYNAMIC: Progress section with smart spacing
                    revolutionaryProgressSection
                        .padding(.top, headerOffset > 150 ? 40 : 0) // More space when hero shrinks
                        .animation(.easeOut(duration: 0.3), value: headerOffset > 150)
                    
                    // NEXT-GEN QUICK ACTIONS (unchanged)
                    nextGenQuickActions
                        .padding(.top, headerOffset > 200 ? 20 : 0)
                        .animation(.easeOut(duration: 0.3), value: headerOffset > 200)
                    
                    // INTELLIGENT INSIGHTS
                    intelligentInsightsSection
                    
                    Spacer(minLength: 120) // Tab bar spacing
                }
                .background(
                    // Nike-killer gradient background
                    LinearGradient(
                        colors: [
                            Color(red: 10/255, green: 10/255, blue: 10/255),
                            Color(red: 26/255, green: 26/255, blue: 30/255).opacity(0.8),
                            Color(red: 13/255, green: 15/255, blue: 20/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self,
                        value: -$0.frame(in: .named("scroll")).origin.y)
                })
                .onPreferenceChange(ViewOffsetKey.self) {
                    headerOffset = $0
                }
            }
            .coordinateSpace(name: "scroll")
            
            // OVERLAY: Smart header that appears on scroll
            if headerOffset > 100 {
                VStack {
                    HStack {
                        Text("FitConnect")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        .ultraThinMaterial.opacity(0.9)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: headerOffset > 100)
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        .onAppear {
            startNikeKillerAnimations()
            if let userId = session.currentUserId {
                progressService.startListening(for: userId)
            }
        }
        .sheet(isPresented: $showingScanMeal) {
            ScanMealView()
        }
        .sheet(isPresented: $showingLogMeal) {
            LogMealView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showingAppointments) {
            ClientAppointmentsView()
                .environmentObject(session)
        }
        .sheet(isPresented: $showingAnalytics) {
            UserAnalysisView(userId: session.currentUserId ?? "", isCurrentUser: true)
                .environmentObject(session)
        }
        .sheet(isPresented: $showingWorkout) {
            NavigationView {
                WorkoutView()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Nike-Killer Hero Section
    
    @ViewBuilder
    private var nikeKillerHeroSection: some View {
        ZStack(alignment: .bottom) {
            // Dynamic background with custom gradient (iOS 16 compatible)
            LinearGradient(
                colors: [
                    Color(red: 10/255, green: 10/255, blue: 10/255),
                    Color(red: 26/255, green: 26/255, blue: 46/255),
                    Color(red: 22/255, green: 19/255, blue: 62/255),
                    Color(red: 15/255, green: 52/255, blue: 96/255),
                    Color(red: 233/255, green: 69/255, blue: 96/255),
                    Color(red: 83/255, green: 52/255, blue: 131/255),
                    Color(red: 26/255, green: 26/255, blue: 46/255),
                    Color(red: 10/255, green: 10/255, blue: 10/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 30)
            .overlay(
                // Additional depth layer
                RadialGradient(
                    colors: [
                        Color(red: 233/255, green: 69/255, blue: 96/255).opacity(0.3),
                        Color.clear,
                        Color(red: 83/255, green: 52/255, blue: 131/255).opacity(0.2)
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 200
                )
            )
            .clipShape(
                // FULLY ROUNDED CORNERS
                RoundedRectangle(cornerRadius: 28)
            )
            
            VStack(alignment: .leading, spacing: 20) {
                // FIXED: Proper safe area spacing - no clash with status bar
                Spacer()
                    .frame(height: 60) // Safe area buffer - prevents clock clash
                
                // Nike-killer greeting - SAFE POSITIONING
                VStack(alignment: .leading, spacing: 8) {
                    Text(getTimeBasedGreeting())
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            // PREMIUM GRADIENT TEXT instead of basic white
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color(red: 233/255, green: 69/255, blue: 96/255).opacity(0.8),
                                    .white.opacity(0.9)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .white.opacity(0.3), radius: 8, x: 0, y: 2) // SOFT GLOW
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1) // DEPTH SHADOW
                        .opacity(showGreeting ? 1 : 0)
                        .offset(y: showGreeting ? 0 : 20)
                    
                    Text(session.currentUser?.firstName ?? "Champion")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 233/255, green: 69/255, blue: 96/255)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(showGreeting ? 1 : 0)
                        .offset(y: showGreeting ? 0 : 30)
                }
                
                // Dynamic motivation with Nike-killer impact
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 233/255, green: 69/255, blue: 96/255), Color(red: 255/255, green: 106/255, blue: 157/255)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .scaleEffect(isHeartFilled ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHeartFilled)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(isHeartFilled ? 1.2 : 1.0)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TODAY'S MISSION")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(1.0)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            
                            Text(shorterMotivationalQuotes[currentQuoteIndex])
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            isHeartFilled.toggle()
                            currentQuoteIndex = (currentQuoteIndex + 1) % shorterMotivationalQuotes.count
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 233/255, green: 69/255, blue: 96/255), .white],
                                    startPoint: .topLeading,
                                    endPoint: .trailing
                                )
                            )
                            .scaleEffect(isHeartFilled ? 1.1 : 1.0)
                            .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2) // ICON SHADOW
                    }
                }
                .padding(18) // REDUCED padding 
                .background(
                    // 3D PREMIUM FLOATING DESIGN - like Take Action Now buttons
                    RoundedRectangle(cornerRadius: 28) // MUCH MORE ROUNDED - premium oval look
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(red: 233/255, green: 69/255, blue: 96/255).opacity(0.6), .white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1 // Visible border for 3D effect
                                )
                        )
                        .shadow(color: Color(red: 233/255, green: 69/255, blue: 96/255).opacity(0.4), radius: 12, x: 0, y: 6) // Colored glow
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10) // Deep shadow
                        .overlay(
                            // SUBTLE HIGHLIGHT for 3D pop
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.1), .clear, .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
                .scaleEffect(showGreeting ? 1.0 : 0.95)
                .opacity(showGreeting ? 1.0 : 0)
                
                Spacer()
                    .frame(height: 20) // Bottom spacing
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 260) // SMALLER - from 280 to 260
        .padding(.horizontal, 20) // FLOATING EFFECT
        .padding(.top, 20) // CRITICAL: Space from status bar
        .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Revolutionary Progress Section
    
    @ViewBuilder
    private var revolutionaryProgressSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR EMPIRE")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                    
                    Text("Today's Conquest")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // FIXED: Dynamic progress indicator that changes with scroll
                HStack(spacing: 6) {
                    ForEach(0..<4) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                index == selectedProgressCard ? 
                                LinearGradient(colors: [Color(red: 233/255, green: 69/255, blue: 96/255), Color(red: 255/255, green: 107/255, blue: 157/255)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.white.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: index == selectedProgressCard ? 32 : 12, height: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedProgressCard)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // FIXED: Proper TabView with working indicators AND MORE PADDING
            TabView(selection: $selectedProgressCard) {
                SeparateFloatingCard(
                    metric: progressService.stepData,
                    animationDelay: 0.1
                )
                .tag(0)
                .padding(.horizontal, 32) // MORE FLOATING - increased from 24
                
                SeparateFloatingCard(
                    metric: progressService.caloriesData,
                    animationDelay: 0.1
                )
                .tag(1)
                .padding(.horizontal, 32) // MORE FLOATING - increased from 24
                
                SeparateFloatingCard(
                    metric: progressService.waterData,
                    animationDelay: 0.1
                )
                .tag(2)
                .padding(.horizontal, 32) // MORE FLOATING - increased from 24
                
                SeparateFloatingCard(
                    metric: progressService.sleepData,
                    animationDelay: 0.1
                )
                .tag(3)
                .padding(.horizontal, 32) // MORE FLOATING - increased from 24
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 320)
        }
    }
    
    // MARK: - Separate Floating Card (Individual Progress Cards)

    struct SeparateFloatingCard: View {
        let metric: ProgressMetric
        let animationDelay: Double
        @State private var progressValue: Double = 0
        @State private var showCard = false
        
        var body: some View {
            VStack(spacing: 18) { 
                // Header with icon - Clean layout
                HStack(spacing: 14) { 
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [metric.color, metric.color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46) 
                            .shadow(color: metric.color.opacity(0.4), radius: 6, x: 0, y: 3) 
                        
                        Image(systemName: metric.icon)
                            .font(.system(size: 21, weight: .semibold)) 
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) { 
                        Text(metric.unit.uppercased())
                            .font(.system(size: 12, weight: .black, design: .rounded)) 
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.0) 
                        
                        Text(metric.subtitle ?? "Today's Progress")
                            .font(.system(size: 17, weight: .bold, design: .rounded)) 
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                // Progress display
                VStack(spacing: 14) { 
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 10) 
                            .frame(width: 145, height: 145) 
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0.0, to: progressValue)
                            .stroke(
                                LinearGradient(
                                    colors: [metric.color, metric.color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round) 
                            )
                            .frame(width: 145, height: 145) 
                            .rotationEffect(.degrees(-90))
                            .shadow(color: metric.color.opacity(0.3), radius: 5, x: 0, y: 2) 
                        
                        // Center value
                        VStack(spacing: 3) { 
                            Text("\(metric.current)")
                                .font(.system(size: 36, weight: .black, design: .rounded)) 
                                .foregroundColor(.white)
                            
                            Text(metric.unit)
                                .font(.system(size: 13, weight: .medium, design: .rounded)) 
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Target info
                    HStack(spacing: 14) { 
                        VStack(alignment: .leading, spacing: 2) { 
                            Text("TARGET")
                                .font(.system(size: 10, weight: .black, design: .rounded)) 
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1.0) 
                            
                            Text("\(metric.goal)")
                                .font(.system(size: 16, weight: .bold, design: .rounded)) 
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) { 
                            Text("REMAINING")
                                .font(.system(size: 10, weight: .black, design: .rounded)) 
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(1.0) 
                            
                            Text("\(max(0, Int(metric.goal) - Int(metric.current)))")
                                .font(.system(size: 16, weight: .bold, design: .rounded)) 
                                .foregroundColor(metric.color)
                        }
                    }
                    .padding(.horizontal, 14) 
                }
                
                Spacer()
            }
            .padding(17) 
            .background(
                // FLOATING CARD DESIGN - Matches Today's Mission style
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24) 
                            .stroke(
                                LinearGradient(
                                    colors: [metric.color.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5 
                            )
                    )
            )
            .shadow(color: metric.color.opacity(0.2), radius: 16, x: 0, y: 8) // FLOATING EFFECT
            .padding(.horizontal, 4) 
            .scaleEffect(showCard ? 1.0 : 0.95)
            .opacity(showCard ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                    showCard = true
                }
                
                withAnimation(.easeOut(duration: 1.2).delay(animationDelay + 0.2)) {
                    progressValue = min(1.0, Double(metric.current) / Double(metric.goal))
                }
            }
        }
    }
    
    // MARK: - Next-Gen Quick Actions
    
    @ViewBuilder
    private var nextGenQuickActions: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POWER MOVES")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                    
                    Text("Take Action Now")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Nike-killer action grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                nikeKillerActionButton(
                    title: "SCAN MEAL",
                    subtitle: "AI Recognition",
                    icon: "viewfinder.circle.fill",
                    gradient: [Color(red: 255/255, green: 138/255, blue: 0/255), Color(red: 255/255, green: 69/255, blue: 0/255)],
                    index: 0
                ) {
                    showingScanMeal = true
                }
                
                nikeKillerActionButton(
                    title: "LOG MEAL",
                    subtitle: "Track Nutrition",
                    icon: "fork.knife.circle.fill",
                    gradient: [Color(red: 0/255, green: 212/255, blue: 255/255), Color(red: 0/255, green: 153/255, blue: 204/255)],
                    index: 1
                ) {
                    showingLogMeal = true
                }
                
                nikeKillerActionButton(
                    title: "WORKOUT",
                    subtitle: "Train Hard",
                    icon: "figure.run.circle.fill",
                    gradient: [Color(red: 0/255, green: 255/255, blue: 136/255), Color(red: 0/255, green: 204/255, blue: 106/255)],
                    index: 2
                ) {
                    showingWorkout = true
                }
                
                nikeKillerActionButton(
                    title: "ANALYTICS",
                    subtitle: "Track Progress",
                    icon: "chart.line.uptrend.xyaxis.circle.fill",
                    gradient: [Color(red: 233/255, green: 69/255, blue: 96/255), Color(red: 255/255, green: 107/255, blue: 157/255)],
                    index: 3
                ) {
                    showingAnalytics = true
                }
                
                nikeKillerActionButton(
                    title: "APPOINTMENTS",
                    subtitle: "Expert Guidance",
                    icon: "calendar.circle.fill",
                    gradient: [Color(red: 156/255, green: 39/255, blue: 176/255), Color(red: 103/255, green: 58/255, blue: 183/255)],
                    isDisabled: session.currentUser?.expertId?.isEmpty ?? true,
                    index: 4
                ) {
                    openAppointments()
                }
                
                nikeKillerActionButton(
                    title: "COMING SOON",
                    subtitle: "Next Feature",
                    icon: "sparkles.rectangle.stack.fill",
                    gradient: [Color(red: 128/255, green: 128/255, blue: 128/255).opacity(0.6), Color(red: 128/255, green: 128/255, blue: 128/255).opacity(0.4)],
                    isDisabled: true,
                    index: 5
                ) {
                    // Future feature
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Intelligent Insights Section
    
    @ViewBuilder
    private var intelligentInsightsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI INSIGHTS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(2)
                    
                    Text("Smart Recommendations")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button("View All") {
                    showingAnalytics = true
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 233/255, green: 69/255, blue: 96/255), Color(red: 255/255, green: 107/255, blue: 157/255)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .padding(.horizontal, 24)
            
            // REAL DATA Smart Insights Carousel
            RealDataInsightsCarousel(
                stepData: progressService.stepData,
                caloriesData: progressService.caloriesData,
                waterData: progressService.waterData,
                sleepData: progressService.sleepData
            )
            .frame(height: 200)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Helper Methods
    
    private func startNikeKillerAnimations() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
            showGreeting = true
        }
        
        for i in 0..<4 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4 + Double(i) * 0.1)) {
                progressAnimations[i] = true
            }
        }
    }
    
    private func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<22: return "GOOD EVENING"
        default: return "LATE NIGHT WARRIOR"
        }
    }
    
    private func nikeKillerActionButton(
        title: String,
        subtitle: String,
        icon: String,
        gradient: [Color],
        isDisabled: Bool = false,
        index: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                actionButtonScale[index] = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    actionButtonScale[index] = 1.0
                }
            }
            
            action()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDisabled ? [Color(red: 128/255, green: 128/255, blue: 128/255).opacity(0.6), Color(red: 128/255, green: 128/255, blue: 128/255).opacity(0.4)] : gradient,
                                startPoint: .topLeading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(color: isDisabled ? .clear : gradient.first?.opacity(0.4) ?? .clear, radius: 12, x: 0, y: 6)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(isDisabled ? .gray : .white)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(isDisabled ? .gray.opacity(0.7) : .white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                // REDUCED padding 
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        // PREMIUM FLOATING DESIGN - Matches Today's Mission style
                        RoundedRectangle(cornerRadius: 24) // MUCH MORE ROUNDED like hero card
                            .stroke(
                                LinearGradient(
                                    colors: isDisabled ? 
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] :
                                        [(gradient.first ?? Color.clear).opacity(0.3), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5 // THINNER stroke
                            )
                    )
            )
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            .scaleEffect(actionButtonScale[safe: index] ?? 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
    
    private func openAppointments() {
        guard let expertId = session.currentUser?.expertId, !expertId.isEmpty else {
            errorMessage = "No expert connected yet. Please connect to an expert first."
            showError = true
            return
        }
        
        showingAppointments = true
    }
    
    private let motivationalQuotes = [
        "Dominate your goals, one rep at a time! ",
        "Champions are made when nobody's watching ",
        "Your only competition is who you were yesterday ",
        "Strength doesn't come from comfort zones ",
        "Every workout is a step closer to greatness "
    ]
    private let shorterMotivationalQuotes = [
        "Dominate today! ",
        "Be unstoppable! ", 
        "Beat yesterday! ",
        "Push limits! ",
        "Stay strong! "
    ]
}

// MARK: - Real Data Smart Insights Carousel

struct RealDataInsightsCarousel: View {
    let stepData: ProgressMetric
    let caloriesData: ProgressMetric
    let waterData: ProgressMetric
    let sleepData: ProgressMetric
    
    @State private var selectedInsight = 0
    
    private var realInsights: [SmartInsight] {
        var insights: [SmartInsight] = []
        
        let waterProgress = Double(waterData.current) / Double(waterData.goal)
        if waterProgress < 0.7 {
            insights.append(SmartInsight(
                title: "Hydration Alert",
                message: "You're \(Int((1.0 - waterProgress) * 100))% below your water goal. Drink up, champion! ",
                type: .warning,
                action: "DRINK NOW"
            ))
        }
        
        let stepsProgress = Double(stepData.current) / Double(stepData.goal)
        if stepsProgress > 0.8 {
            insights.append(SmartInsight(
                title: "Great Progress!",
                message: "Amazing! You've completed \(Int(stepsProgress * 100))% of your daily steps. Keep moving! ",
                type: .achievement,
                action: "KEEP GOING"
            ))
        } else if stepsProgress < 0.3 {
            insights.append(SmartInsight(
                title: "Move More",
                message: "Time to get moving! Just \(stepData.goal - stepData.current) more steps to go. ",
                type: .warning,
                action: "START WALKING"
            ))
        }
        
        let caloriesProgress = Double(caloriesData.current) / Double(caloriesData.goal)
        if caloriesProgress > 0.9 {
            insights.append(SmartInsight(
                title: "Calorie Goal Reached!",
                message: "Excellent work! You've nearly hit your calorie goal for today. ",
                type: .achievement,
                action: "VIEW STATS"
            ))
        }
        
        if insights.isEmpty {
            insights.append(SmartInsight(
                title: "Keep Building Momentum",
                message: "Every step counts towards your goals. You're doing great! ",
                type: .positive,
                action: "NEXT WORKOUT"
            ))
        }
        
        return insights
    }
    
    var body: some View {
        TabView(selection: $selectedInsight) {
            ForEach(Array(realInsights.enumerated()), id: \.offset) { index, insight in
                SmartInsightCard(insight: insight)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedInsight = (selectedInsight + 1) % realInsights.count
                }
            }
        }
    }
}

// MARK: - Smart Insights

struct SmartInsight {
    let title: String
    let message: String
    let type: InsightType
    let action: String
    
    enum InsightType {
        case warning, positive, achievement
        
        var colors: [Color] {
            switch self {
            case .warning: return [Color(red: 255/255, green: 138/255, blue: 0/255), Color(red: 255/255, green: 69/255, blue: 0/255)]
            case .positive: return [Color(red: 0/255, green: 255/255, blue: 136/255), Color(red: 0/255, green: 204/255, blue: 106/255)]
            case .achievement: return [Color(red: 233/255, green: 69/255, blue: 96/255), Color(red: 255/255, green: 107/255, blue: 157/255)]
            }
        }
    }
}

struct SmartInsightCard: View {
    let insight: SmartInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(insight.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: insight.type.colors,
                                startPoint: .topLeading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getInsightIcon(for: insight.type))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(insight.message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
            
            Spacer()
            
            Button(action: {}) {
                Text(insight.action)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: insight.type.colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: insight.type.colors.first?.opacity(0.3) ?? .clear, radius: 6, x: 0, y: 3)
            }
        }
        .padding(20)
        .background(
            // REDUCED padding
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    // PREMIUM FLOATING DESIGN - Matches Today's Mission style
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [insight.type.colors.first?.opacity(0.4) ?? .clear, .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
    }
    
    private func getInsightIcon(for type: SmartInsight.InsightType) -> String {
        switch type {
        case .warning: return "exclamationmark.triangle.fill"
        case .positive: return "checkmark.circle.fill"
        case .achievement: return "crown.fill"
        }
    }
}

// MARK: - Supporting Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let previewSession = SessionStore.previewStore(isLoggedIn: true, role: "client")
        var previewUser = FitConnectUser(id: "clientPreviewUser", email: "client@example.com", fullName: "Client Preview")
        previewUser.assignedDietitianId = "dietitianPreviewUser123"
        previewSession.currentUser = previewUser
        previewSession.currentUserId = previewUser.id

        return ClientHomeView()
            .environmentObject(previewSession)
            .preferredColorScheme(.dark)
    }
}
#endif