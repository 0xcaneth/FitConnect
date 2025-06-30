import SwiftUI

struct LeaderboardView: View {
    let challengeId: String
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @StateObject private var challengeService = ChallengeService.shared
    
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    @State private var isLoading = true
    @State private var showContent = false
    @State private var particleOffset = 0.0
    @State private var gradientOffset = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Background
                premiumAnimatedBackground()
                
                // Floating Particles
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                                    Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 2...5))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height) + particleOffset
                        )
                        .animation(
                            .linear(duration: Double.random(in: 15...25))
                            .repeatForever(autoreverses: false),
                            value: particleOffset
                        )
                }
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader()
                    
                    if isLoading {
                        premiumLoadingView()
                    } else if leaderboardEntries.isEmpty {
                        premiumEmptyStateView()
                    } else {
                        leaderboardContent()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
            loadLeaderboard()
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
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
                    Color(red: 0.10, green: 0.11, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Golden gradient overlay for leaderboard theme
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.3 + gradientOffset * 0.1),
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func customHeader() -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 44)
            
            HStack {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 20, weight: .bold))
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
                    
                    Text("Leaderboard")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    loadLeaderboard()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .background(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .opacity(showContent ? 1.0 : 0.0)
        .offset(y: showContent ? 0 : -20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: showContent)
    }
    
    @ViewBuilder
    private func leaderboardContent() -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top 3 Podium
                if leaderboardEntries.count >= 3 {
                    podiumSection()
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 50)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: showContent)
                }
                
                // Full Leaderboard List
                leaderboardList()
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: showContent)
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder
    private func podiumSection() -> some View {
        VStack(spacing: 24) {
            Text("Top Performers")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 16) {
                // 2nd Place
                if leaderboardEntries.count > 1 {
                    podiumCard(entry: leaderboardEntries[1], rank: 2, height: 100)
                }
                
                // 1st Place (Taller)
                podiumCard(entry: leaderboardEntries[0], rank: 1, height: 130)
                
                // 3rd Place
                if leaderboardEntries.count > 2 {
                    podiumCard(entry: leaderboardEntries[2], rank: 3, height: 80)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func podiumCard(entry: LeaderboardEntry, rank: Int, height: CGFloat) -> some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(rankGradient(for: rank))
                    .frame(width: 60, height: 60)
                    .shadow(
                        color: rankColor(for: rank).opacity(0.6),
                        radius: 12, x: 0, y: 6
                    )
                
                if let firstLetter = entry.userName.first {
                    Text(String(firstLetter).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // Name
            Text(entry.userName)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Progress
            Text("\(Int(entry.progress))")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(rankColor(for: rank))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(rankColor(for: rank).opacity(0.3), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 10, x: 0, y: 5
                )
        )
        .overlay(
            // Rank badge
            VStack {
                HStack {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(rankGradient(for: rank))
                            .frame(width: 28, height: 28)
                            .shadow(
                                color: rankColor(for: rank).opacity(0.6),
                                radius: 6, x: 0, y: 3
                            )
                        
                        Text("\(rank)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .offset(x: 8, y: -8)
                }
                
                Spacer()
            }
        )
    }
    
    @ViewBuilder
    private func leaderboardList() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("All Participants")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardRow(entry: entry, rank: index + 1, isCurrentUser: entry.userId == session.currentUserId)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : 30)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05 + 0.7),
                            value: showContent
                        )
                }
            }
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
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                                    Color(red: 1.0, green: 0.65, blue: 0.0).opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60 + CGFloat(index * 20))
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: particleOffset
                        )
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            Text("Loading leaderboard...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func premiumEmptyStateView() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.circle")
                    .font(.system(size: 50, weight: .medium))
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
            
            VStack(spacing: 12) {
                Text("No Rankings Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Be the first to make progress in this challenge!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helper Functions
    
    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20) // Bronze
        default: return Color(red: 0.49, green: 0.34, blue: 1.0) // Purple
        }
    }
    
    private func rankGradient(for rank: Int) -> LinearGradient {
        switch rank {
        case 1:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.84, blue: 0.0),
                    Color(red: 1.0, green: 0.65, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [
                    Color(red: 0.75, green: 0.75, blue: 0.75),
                    Color(red: 0.60, green: 0.60, blue: 0.60)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [
                    Color(red: 0.80, green: 0.50, blue: 0.20),
                    Color(red: 0.65, green: 0.35, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 1.0),
                    Color(red: 0.31, green: 0.25, blue: 0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        Task {
            do {
                let entries = try await challengeService.fetchLeaderboard(for: challengeId)
                
                await MainActor.run {
                    self.leaderboardEntries = entries
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("[LeaderboardView] Error loading leaderboard: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particleOffset = -800
        }
        
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: true)) {
            gradientOffset = 1.0
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool
    
    @State private var glowIntensity = 0.3
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankGradient)
                    .frame(width: 40, height: 40)
                    .shadow(
                        color: isCurrentUser ? 
                        Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6) :
                        Color.black.opacity(0.2),
                        radius: isCurrentUser ? 8 : 4, 
                        x: 0, y: 2
                    )
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .stroke(
                                isCurrentUser ? 
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6) :
                                Color.white.opacity(0.2), 
                                lineWidth: 2
                            )
                    )
                
                if let firstLetter = entry.userName.first {
                    Text(String(firstLetter).uppercased())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.userName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.49, green: 0.34, blue: 1.0))
                    }
                }
                
                Text("Last updated: \(entry.lastUpdated.dateValue(), style: .relative) ago")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(entry.progress))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrentUser ? Color(red: 0.49, green: 0.34, blue: 1.0) : .white)
                
                Text("progress")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: isCurrentUser ? [
                            Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.1),
                            Color(red: 0.31, green: 0.25, blue: 0.84).opacity(0.05)
                        ] : [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isCurrentUser ? 
                            Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3) :
                            Color.white.opacity(0.1), 
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isCurrentUser ? 
                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.2) :
                    Color.black.opacity(0.1),
                    radius: isCurrentUser ? 12 : 6, 
                    x: 0, y: 4
                )
        )
        .scaleEffect(isCurrentUser ? 1.02 : 1.0)
        .onAppear {
            if isCurrentUser {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
        }
    }
    
    private var rankGradient: LinearGradient {
        if isCurrentUser {
            return LinearGradient(
                colors: [
                    Color(red: 0.49, green: 0.34, blue: 1.0),
                    Color(red: 0.31, green: 0.25, blue: 0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        switch rank {
        case 1:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.84, blue: 0.0),
                    Color(red: 1.0, green: 0.65, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 2:
            return LinearGradient(
                colors: [
                    Color(red: 0.75, green: 0.75, blue: 0.75),
                    Color(red: 0.60, green: 0.60, blue: 0.60)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case 3:
            return LinearGradient(
                colors: [
                    Color(red: 0.80, green: 0.50, blue: 0.20),
                    Color(red: 0.65, green: 0.35, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.3),
                    Color.white.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

#if DEBUG
struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView(challengeId: "sample_challenge_id")
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif