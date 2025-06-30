import SwiftUI
import FirebaseFirestore

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore
    @StateObject private var challengeService = ChallengeService.shared
    
    @State private var showContent = false
    @State private var particleOffset = 0.0
    @State private var gradientOffset = 0.0
    @State private var isJoined = false
    @State private var userChallenge: UserChallenge?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Background
                premiumAnimatedBackground()
                
                // Floating Particles
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(challenge.category.gradient[0].opacity(0.6))
                        .frame(width: CGFloat.random(in: 2...6))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height) + particleOffset
                        )
                        .animation(
                            .linear(duration: Double.random(in: 20...35))
                            .repeatForever(autoreverses: false),
                            value: particleOffset
                        )
                }
                
                VStack(spacing: 0) {
                    // Custom Header
                    customHeader()
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            // Hero Section
                            heroSection()
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: showContent)
                            
                            // Stats Section
                            statsSection()
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(y: showContent ? 0 : 30)
                                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: showContent)
                            
                            // Progress Section (if joined)
                            if isJoined, let userChallenge = userChallenge {
                                progressSection(userChallenge: userChallenge)
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: showContent)
                            }
                            
                            // Requirements Section
                            if !challenge.requirements.isEmpty {
                                requirementsSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: showContent)
                            }
                            
                            // Tips Section
                            if !challenge.tips.isEmpty {
                                tipsSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: showContent)
                            }
                            
                            Spacer(minLength: 120)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Action Button
                    actionButton()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startAnimations()
            checkJoinStatus()
            
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
            
            // Category-specific gradient overlay
            RadialGradient(
                colors: [
                    challenge.category.gradient[0].opacity(0.1),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3 + gradientOffset * 0.1, y: 0.2 + gradientOffset * 0.05),
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
                
                Text("Challenge Details")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
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
    }
    
    @ViewBuilder
    private func heroSection() -> some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    // Category Badge
                    HStack(spacing: 8) {
                        Image(systemName: challenge.category.icon)
                            .font(.system(size: 14, weight: .bold))
                        
                        Text(challenge.category.title.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(0.5)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: challenge.category.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: challenge.category.gradient[0].opacity(0.4),
                                radius: 8, x: 0, y: 4
                            )
                    )
                    
                    Text(challenge.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(3)
                }
                
                Spacer()
            }
            
            Text(challenge.description)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(Color.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(28)
        .background(
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
                                    challenge.category.gradient[0].opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 20, x: 0, y: 10
                )
        )
    }
    
    @ViewBuilder
    private func statsSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Challenge Stats")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ChallengeStatCard(
                    icon: "target",
                    title: "Target",
                    value: "\(Int(challenge.targetValue))",
                    subtitle: challenge.unit.displayName,
                    gradient: challenge.category.gradient
                )
                
                ChallengeStatCard(
                    icon: "calendar",
                    title: "Duration",
                    value: "\(challenge.durationDays)",
                    subtitle: "Days",
                    gradient: challenge.category.gradient
                )
                
                ChallengeStatCard(
                    icon: "star.fill",
                    title: "XP Reward",
                    value: "\(challenge.xpReward)",
                    subtitle: "Points",
                    gradient: [
                        Color(red: 1.0, green: 0.84, blue: 0.0),
                        Color(red: 1.0, green: 0.65, blue: 0.0)
                    ]
                )
                
                ChallengeStatCard(
                    icon: "person.2.fill",
                    title: "Participants",
                    value: "\(challenge.participantCount)",
                    subtitle: "Joined",
                    gradient: [
                        Color(red: 0.31, green: 0.78, blue: 0.47),
                        Color(red: 0.27, green: 0.64, blue: 0.71)
                    ]
                )
            }
        }
    }
    
    @ViewBuilder
    private func progressSection(userChallenge: UserChallenge) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Progress")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: min(userChallenge.progressValue / (userChallenge.challengeTargetValue ?? 1), 1.0))
                        .stroke(
                            LinearGradient(
                                colors: challenge.category.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .shadow(
                            color: challenge.category.gradient[0].opacity(0.6),
                            radius: 12, x: 0, y: 6
                        )
                    
                    VStack(spacing: 4) {
                        Text("\(Int((userChallenge.progressValue / (userChallenge.challengeTargetValue ?? 1)) * 100))%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                
                // Progress Details
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Text("\(Int(userChallenge.progressValue))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Text("\(Int(userChallenge.challengeTargetValue ?? 0))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(challenge.category.gradient[0])
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(challenge.category.gradient[0].opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func requirementsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Requirements")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(challenge.requirements.enumerated()), id: \.offset) { index, requirement in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(challenge.category.gradient[0])
                        
                        Text(requirement)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.03)
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
    private func tipsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pro Tips")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(Array(challenge.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text(tip)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.03)
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
    private func actionButton() -> some View {
        VStack(spacing: 16) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            Button(action: {
                if isJoined {
                    // Handle leave challenge
                    leaveChallenge()
                } else {
                    // Handle join challenge
                    joinChallenge()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isJoined ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text(isJoined ? "Leave Challenge" : "Join Challenge")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: isJoined ? [
                                    Color(red: 1.0, green: 0.23, blue: 0.19),
                                    Color(red: 0.8, green: 0.2, blue: 0.15)
                                ] : challenge.category.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(
                            color: (isJoined ? Color(red: 1.0, green: 0.23, blue: 0.19) : challenge.category.gradient[0]).opacity(0.4),
                            radius: 12, x: 0, y: 6
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
        }
        .background(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color(red: 0.05, green: 0.06, blue: 0.08).opacity(0.95)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Actions
    
    private func joinChallenge() {
        guard let userId = session.currentUserId else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await challengeService.joinChallenge(challenge, userId: userId)
                
                await MainActor.run {
                    self.isJoined = true
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
                
            } catch {
                print("[ChallengeDetailView] Error joining challenge: \(error)")
                
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func leaveChallenge() {
        guard let userId = session.currentUserId, let challengeId = challenge.id else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        Task {
            do {
                try await challengeService.leaveChallenge(challengeId, userId: userId)
                
                await MainActor.run {
                    self.isJoined = false
                    self.userChallenge = nil
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                }
                
            } catch {
                print("[ChallengeDetailView] Error leaving challenge: \(error)")
                
                // Error haptic feedback
                let errorFeedback = UINotificationFeedbackGenerator()
                errorFeedback.notificationOccurred(.error)
            }
        }
    }
    
    private func checkJoinStatus() {
        guard let challengeId = challenge.id else { return }
        
        // Check if user has joined this challenge
        self.isJoined = challengeService.activeChallenges.contains { userChallenge in
            userChallenge.challengeId == challengeId
        }
        
        // Get user challenge data if joined
        if isJoined {
            self.userChallenge = challengeService.activeChallenges.first { userChallenge in
                userChallenge.challengeId == challengeId
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            particleOffset = -1000
        }
        
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
            gradientOffset = 1.0
        }
    }
}

struct ChallengeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                gradient[0].opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 15,
                            endRadius: 30
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(gradient[0])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gradient[0].opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#if DEBUG
struct ChallengeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeDetailView(
            challenge: Challenge(
                id: "sample_challenge_id",
                title: "10K Steps Daily",
                description: "Walk 10,000 steps every day for a week to boost your cardiovascular health and build a sustainable fitness habit.",
                unit: ChallengeUnit.steps,
                targetValue: 10000,
                durationDays: 7,
                category: ChallengeCategory.fitness,
                difficulty: ChallengeDifficulty.medium,
                xpReward: 150,
                participantCount: 234,
                iconName: "figure.walk",
                colorHex: "#FF6B6B",
                requirements: [
                    "Track your daily steps using Health app",
                    "Maintain consistency for 7 days",
                    "Share progress with the community"
                ],
                tips: [
                    "Take short walks throughout the day",
                    "Use stairs instead of elevators",
                    "Park further away from destinations",
                    "Take walking meetings when possible"
                ],
                lastUpdated: Timestamp(date: Date())
            )
        )
        .environmentObject(SessionStore.previewStore())
        .preferredColorScheme(.dark)
    }
}
#endif
