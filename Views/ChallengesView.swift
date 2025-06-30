import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct ChallengesView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @StateObject private var challengeService = ChallengeService.shared
    
    @State private var selectedTab: ChallengeTab = .discover
    @State private var showingChallengeDetail = false
    @State private var selectedChallenge: Challenge?
    @State private var showingLeaderboard = false
    @State private var selectedLeaderboardChallenge: String?
    @State private var showContent = false
    @State private var particleOffset = 0.0
    @State private var gradientOffset = 0.0
    @State private var pulseScale = 1.0
    @State private var filterCategory: ChallengeCategory = .all
    
    private var filteredChallenges: [Challenge] {
        if filterCategory == .all {
            return challengeService.availableChallenges
        }
        return challengeService.availableChallenges.filter { $0.category == filterCategory }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Animated Background
                premiumAnimatedBackground()
                
                // Floating Particles
                ForEach(0..<20, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                    Color(red: 0.31, green: 0.25, blue: 0.84).opacity(0.3),
                                    Color(red: 0.94, green: 0.58, blue: 0.98).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 3...8))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height) + particleOffset
                        )
                        .animation(
                            .linear(duration: Double.random(in: 25...45))
                            .repeatForever(autoreverses: false),
                            value: particleOffset
                        )
                }
                
                VStack(spacing: 0) {
                    // Premium Header
                    premiumHeader()
                    
                    // Tab Selector
                    premiumTabSelector()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Discover Tab
                        discoverTabContent()
                            .tag(ChallengeTab.discover)
                        
                        // Active Tab
                        activeTabContent()
                            .tag(ChallengeTab.active)
                        
                        // Completed Tab
                        completedTabContent()
                            .tag(ChallengeTab.completed)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
            setupChallengeService()
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            if let userId = session.currentUserId {
                challengeService.stopService()
            }
        }
        .sheet(isPresented: $showingChallengeDetail) {
            if let challenge = selectedChallenge {
                ChallengeDetailView(challenge: challenge)
                    .environmentObject(session)
            }
        }
        .sheet(isPresented: $showingLeaderboard) {
            if let challengeId = selectedLeaderboardChallenge {
                LeaderboardView(challengeId: challengeId)
                    .environmentObject(session)
            }
        }
    }
    
    @ViewBuilder
    private func premiumAnimatedBackground() -> some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.10, green: 0.11, blue: 0.15),
                    Color(red: 0.12, green: 0.13, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dynamic mesh overlays
            RadialGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.12),
                    Color.clear
                ],
                center: UnitPoint(x: 0.2 + gradientOffset * 0.1, y: 0.3 + gradientOffset * 0.05),
                startRadius: 50,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    Color(red: 0.94, green: 0.58, blue: 0.98).opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.8 - gradientOffset * 0.1, y: 0.7 - gradientOffset * 0.05),
                startRadius: 30,
                endRadius: 350
            )
            
            RadialGradient(
                colors: [
                    Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.06),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.1 + gradientOffset * 0.03),
                startRadius: 40,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func premiumHeader() -> some View {
        VStack(spacing: 0) {
            // Status bar spacer
            Spacer()
                .frame(height: 44)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .scaleEffect(pulseScale)
                            
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.65, blue: 0.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Challenges")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Push your limits")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                    
                    // Stats Summary
                    HStack(spacing: 20) {
                        StatsPill(
                            icon: "flame.fill",
                            value: "\(challengeService.activeChallenges.count)",
                            label: "Active",
                            color: Color(red: 1.0, green: 0.42, blue: 0.42)
                        )
                        
                        StatsPill(
                            icon: "checkmark.circle.fill",
                            value: "\(challengeService.completedChallenges.count)",
                            label: "Completed",
                            color: Color(red: 0.31, green: 0.78, blue: 0.47)
                        )
                        
                        StatsPill(
                            icon: "star.fill",
                            value: "\(filteredChallenges.count)",
                            label: "Available",
                            color: Color(red: 1.0, green: 0.84, blue: 0.0)
                        )
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : -30)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showContent)
        }
    }
    
    @ViewBuilder
    private func premiumTabSelector() -> some View {
        HStack(spacing: 0) {
            ForEach(ChallengeTab.allCases, id: \.self) { tab in
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(tab.title)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedTab == tab ? .white : Color.white.opacity(0.5))
                        
                        // Selection indicator
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: selectedTab == tab ? [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84)
                                    ] : [Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
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
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
    }
    
    @ViewBuilder
    private func discoverTabContent() -> some View {
        VStack(spacing: 0) {
            // Category Filter
            categoryFilterView()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            
            if challengeService.isLoading {
                premiumLoadingView()
            } else if filteredChallenges.isEmpty {
                premiumEmptyStateView(
                    icon: "magnifyingglass.circle",
                    title: "No Challenges Found",
                    message: "Try adjusting your filter or check back later for new challenges!"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredChallenges.enumerated()), id: \.element.id) { index, challenge in
                            PremiumChallengeCard(
                                challenge: challenge,
                                isJoined: challengeService.activeChallenges.contains { $0.challengeId == challenge.id },
                                onTap: {
                                    selectedChallenge = challenge
                                    showingChallengeDetail = true
                                },
                                onJoin: {
                                    joinChallenge(challenge)
                                },
                                onLeaderboard: {
                                    selectedLeaderboardChallenge = challenge.id
                                    showingLeaderboard = true
                                }
                            )
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 50)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 0.6),
                                value: showContent
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func activeTabContent() -> some View {
        VStack(spacing: 20) {
            if challengeService.activeChallenges.isEmpty {
                premiumEmptyStateView(
                    icon: "flame.circle",
                    title: "No Active Challenges",
                    message: "Join a challenge from the Discover tab to start your journey!"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(challengeService.activeChallenges.enumerated()), id: \.element.id) { index, userChallenge in
                            ActiveChallengeCard(
                                userChallenge: userChallenge,
                                onTap: {
                                    // Find the original challenge
                                    if let challenge = challengeService.availableChallenges.first(where: { $0.id == userChallenge.challengeId }) {
                                        selectedChallenge = challenge
                                        showingChallengeDetail = true
                                    }
                                },
                                onLeaderboard: {
                                    selectedLeaderboardChallenge = userChallenge.challengeId
                                    showingLeaderboard = true
                                }
                            )
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(
                                .spring(response: 0.8, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 0.2),
                                value: showContent
                            )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func completedTabContent() -> some View {
        VStack(spacing: 20) {
            if challengeService.completedChallenges.isEmpty {
                premiumEmptyStateView(
                    icon: "checkmark.circle",
                    title: "No Completed Challenges",
                    message: "Complete your first challenge to unlock achievements and rewards!"
                )
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(challengeService.completedChallenges.enumerated()), id: \.element.id) { index, userChallenge in
                            CompletedChallengeCard(userChallenge: userChallenge)
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1 + 0.2),
                                    value: showContent
                                )
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func categoryFilterView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ChallengeCategory.allCases, id: \.self) { category in
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            filterCategory = category
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(category.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(filterCategory == category ? .white : Color.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    filterCategory == category ?
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
                                            Color.white.opacity(0.08),
                                            Color.white.opacity(0.04)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .background(
                                    Capsule()
                                        .stroke(
                                            filterCategory == category ?
                                            Color.clear :
                                            Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func premiumLoadingView() -> some View {
        VStack(spacing: 24) {
            ZStack {
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
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            Text("Loading challenges...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func premiumEmptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 50, weight: .medium))
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
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Actions
    
    private func joinChallenge(_ challenge: Challenge) {
        guard let userId = session.currentUserId else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await challengeService.joinChallenge(challenge, userId: userId)
                
                // Success haptic feedback
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
            } catch {
                print("[ChallengesView] Error joining challenge: \(error)")
                
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func setupChallengeService() {
        guard let userId = session.currentUserId else { return }
        challengeService.startService(for: userId)
    }
    
    private func startAnimations() {
        // Start continuous animations
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            particleOffset = -1200
        }
        
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: true)) {
            gradientOffset = 1.0
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Enums

enum ChallengeTab: String, CaseIterable {
    case discover = "discover"
    case active = "active"
    case completed = "completed"
    
    var title: String {
        switch self {
        case .discover: return "Discover"
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
    
    var icon: String {
        switch self {
        case .discover: return "sparkles"
        case .active: return "flame"
        case .completed: return "checkmark.circle"
        }
    }
}

// Remove the duplicate ChallengeCategory enum, using the one from Challenge.swift

#if DEBUG
@available(iOS 16.0, *)
struct ChallengesView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengesView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif

// MARK: - Supporting Views

struct StatsPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.15),
                            color.opacity(0.08)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .background(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
