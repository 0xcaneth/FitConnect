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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showHealthKitBanner && !healthKitManager.isAuthorized {
                    healthKitPermissionBanner
                }
                
                motivationalQuoteCard
                
                todaysProgressSection
                
                quickActionsSection
                
                recentActivitySection
                
                Spacer(minLength: 100) // Extra space at bottom for tab bar
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(hex: "0D0F14"))
        .onAppear {
            if healthKitManager.isAuthorized {
                showHealthKitBanner = !healthKitManager.isAuthorized
            }
            // if session.assignedDietitianId.isEmpty {
            //     session.assignedDietitianId = "mock_dietitian_123"
            //     print("[ClientHomeView] Assigned mock dietitian for testing")
            // }
            print("[ClientHomeView] Current user ID: \(session.currentUserId ?? "nil")")
            print("[ClientHomeView] Expert ID: \(session.currentUser?.expertId ?? "nil")")
            print("[ClientHomeView] Assigned dietitian ID: \(session.assignedDietitianId)")
            
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
            if #available(iOS 16.0, *) {
                UserAnalysisView(userId: session.currentUserId ?? "", isCurrentUser: true)
                    .environmentObject(session)
            } else {
                // Fallback for older iOS versions
                VStack {
                    Text("Analytics")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Analytics requires iOS 16 or later")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
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
        .onDisappear {
            progressService.stopListening()
        }
    }
    
    private var healthKitPermissionBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF8E3C"))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit access needed")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Enable to see your live health data")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                Task {
                    await healthKitManager.requestAuthorization()
                    if healthKitManager.isAuthorized {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showHealthKitBanner = false
                        }
                    }
                }
            } label: {
                Text("Enable")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF8E3C"), Color(hex: "FF3C5C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Constants.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF8E3C"), Color(hex: "FF3C5C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    private var motivationalQuoteCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 30))
                .foregroundColor(.white)
            
            Text(motivationalQuotes[currentQuoteIndex])
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHeartFilled.toggle()
                }
                
                currentQuoteIndex = (currentQuoteIndex + 1) % motivationalQuotes.count
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                }
            } label: {
                Image(systemName: isHeartFilled ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .scaleEffect(isHeartFilled ? 1.4 : 1.0)
            }
        }
        .padding(16)
        .frame(height: 95)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    private let motivationalQuotes = [
        "Every step counts towards your goals!",
        "Your health journey starts today!",
        "Small changes lead to big results!",
        "You're stronger than you think!",
        "Progress, not perfection!"
    ]
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with loading indicator
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if progressService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#8F3FFF")))
                        .scaleEffect(0.8)
                } else {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(index == selectedProgressCard ? Color(hex: "#8F3FFF") : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == selectedProgressCard ? 1.2 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedProgressCard)
                        }
                    }
                }
            }
            
            // Progress cards carousel
            TabView(selection: $selectedProgressCard) {
                ModernProgressCard(
                    metric: progressService.stepData,
                    isCenter: selectedProgressCard == 0
                ).tag(0)
                
                ModernProgressCard(
                    metric: progressService.caloriesData,
                    isCenter: selectedProgressCard == 1
                ).tag(1)
                
                ModernProgressCard(
                    metric: progressService.waterData,
                    isCenter: selectedProgressCard == 2
                ).tag(2)
                
                ModernProgressCard(
                    metric: progressService.sleepData,
                    isCenter: selectedProgressCard == 3
                ).tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 280)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Scan Meal",
                        icon: "camera",
                        gradient: GradientColors(start: Color(hex: "FF9800"), end: Color(hex: "FF5722"))
                    ) {
                        showingScanMeal = true
                    }
                    
                    quickActionButton(
                        title: "Log Meal",
                        icon: "fork.knife",
                        gradient: GradientColors(start: Color(hex: "26C6DA"), end: Color(hex: "00ACC1"))
                    ) {
                        print("[ClientHomeView] Log Meal button tapped")
                        showingLogMeal = true
                    }
                }
                
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Workout",
                        icon: "figure.run",
                        gradient: GradientColors(start: Color(hex: "4CAF50"), end: Color(hex: "8BC34A"))
                    ) {
                        showingWorkout = true
                    }
                    
                    quickActionButton(
                        title: "Stats",
                        icon: "chart.bar.fill",
                        gradient: GradientColors(start: Color(hex: "#42A5F5"), end: Color(hex: "#1E88E5"))
                    ) {
                        showingAnalytics = true
                    }
                }
                
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Appointments",
                        icon: "calendar",
                        gradient: GradientColors(start: Color(hex: "AB47BC"), end: Color(hex: "8E24AA")),
                        isDisabled: session.currentUser?.expertId?.isEmpty ?? true
                    ) {
                        openAppointments()
                    }
                    
                    // Placeholder for future feature
                    quickActionButton(
                        title: "Coming Soon",
                        icon: "sparkles",
                        gradient: GradientColors(start: Color.gray.opacity(0.5), end: Color.gray.opacity(0.3)),
                        isDisabled: true
                    ) {
                        // Future feature
                    }
                }
            }
            
            if session.assignedDietitianId.isEmpty {
                Text("No dietitian assigned yet")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
    
    private func openAppointments() {
        guard let expertId = session.currentUser?.expertId, !expertId.isEmpty else {
            errorMessage = "No expert connected yet. Please connect to an expert first."
            showError = true
            return
        }
        
        showingAppointments = true
    }
    
    struct GradientColors {
        let start: Color
        let end: Color
    }
    
    private func quickActionButton(title: String, icon: String, gradient: GradientColors, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
            }
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDisabled ? [Color.gray.opacity(0.5), Color.gray.opacity(0.3)] : [gradient.start, gradient.end],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isDisabled ? .gray : .white)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isDisabled ? .gray : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Constants.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LinearGradient(
                                colors: isDisabled ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] : [gradient.start.opacity(0.7), gradient.end.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(isDisabled ? 1.0 : 1.0) // Will be animated on tap
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8F3FFF"))
            }
            
            RecentActivitiesView()
                .background(Color.clear)
        }
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