import SwiftUI
import FirebaseFirestore

struct PremiumChallengeCard: View {
    let challenge: Challenge
    let isJoined: Bool
    let onTap: () -> Void
    let onJoin: () -> Void
    let onLeaderboard: () -> Void
    
    @State private var isPressed = false
    @State private var glowIntensity = 0.5
    @State private var rotationAngle = 0.0
    
    private var challengeGradient: LinearGradient {
        let colors: [Color]
        
        switch challenge.title {
        case "10K Steps Master", "10k Steps Master":
            // Neon mavi gradient - daha canlı
            colors = [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)]
        case "Calorie Crusher":
            // Ateş gradient - turuncu-kırmızı-sarı
            colors = [Color(red: 1.0, green: 0.1, blue: 0.0), Color(red: 1.0, green: 0.4, blue: 0.0), Color(red: 1.0, green: 0.7, blue: 0.0)]
        case "Distance Runner":
            // Neon yeşil gradient - elektrik yeşili
            colors = [Color(red: 0.0, green: 0.8, blue: 0.3), Color(red: 0.2, green: 1.0, blue: 0.5), Color(red: 0.0, green: 1.0, blue: 0.8)]
        case "Hydration Hero":
            // Okyanus mavisi gradient - su teması
            colors = [Color(red: 0.0, green: 0.7, blue: 1.0), Color(red: 0.3, green: 0.9, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 0.9)]
        case "Mindful Minutes":
            // Sunset gradient - mor-pembe-turuncu
            colors = [Color(red: 0.6, green: 0.2, blue: 1.0), Color(red: 0.9, green: 0.3, blue: 0.8), Color(red: 1.0, green: 0.5, blue: 0.7)]
        case "Nutrition Navigator":
            // Tropical gradient - yeşil-sarı-turuncu
            colors = [Color(red: 0.5, green: 0.8, blue: 0.0), Color(red: 0.8, green: 1.0, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.0)]
        default:
            colors = challenge.category.gradient
        }
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var challengeIcon: String {
        switch challenge.title {
        case "10K Steps Master", "10k Steps Master":
            return "figure.walk.motion" // Hareket halinde yürüyen figür
        case "Calorie Crusher":
            return "flame.fill" // Ateş ikonu - enerji yakar
        case "Distance Runner":
            return "figure.run.circle.fill" // Koşucu daire içinde
        case "Hydration Hero":
            return "drop.triangle.fill" // Premium su damlası
        case "Mindful Minutes":
            return "brain.head.profile.fill" // Beyin/mindfulness
        case "Nutrition Navigator":
            return "carrot.fill" // Havuç - beslenme teması
        default:
            return challenge.iconName
        }
    }
    
    private var categoryGradient: LinearGradient {
        challengeGradient
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Category Badge
                            HStack(spacing: 6) {
                                Image(systemName: challenge.category.icon)
                                    .font(.system(size: 12, weight: .bold))
                                
                                Text(challenge.category.title.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(categoryGradient.opacity(0.8))
                                    .shadow(
                                        color: challenge.category.gradient[0].opacity(0.4),
                                        radius: 6, x: 0, y: 2
                                    )
                            )
                            
                            // Title
                            Text(challenge.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            // Description
                            Text(challenge.description)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.8))
                                .lineLimit(3)
                        }
                        
                        Spacer()
                        
                        // Challenge Icon with premium effects
                        ZStack {
                            // Outer glow ring
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            challenge.category.gradient[0].opacity(glowIntensity * 0.8),
                                            challenge.category.gradient[1].opacity(glowIntensity * 0.4),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .scaleEffect(isPressed ? 0.85 : 1.0)
                            
                            // Inner circle with gradient
                            Circle()
                                .fill(challengeGradient.opacity(0.2))
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Circle()
                                        .stroke(challengeGradient, lineWidth: 3)
                                        .shadow(color: challenge.category.gradient[0].opacity(0.6), radius: 8, x: 0, y: 4)
                                )
                            
                            // Icon with enhanced styling
                            Image(systemName: challengeIcon)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(challengeGradient)
                                .rotationEffect(.degrees(rotationAngle))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                .scaleEffect(isPressed ? 0.9 : 1.0)
                        }
                    }
                    
                    // Stats Row
                    HStack(spacing: 16) {
                        // Target Value
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TARGET")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            HStack(spacing: 4) {
                                Text("\(Int(challenge.targetValue))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(challenge.unit.shortName)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .frame(height: 30)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DURATION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            HStack(spacing: 4) {
                                Text("\(challenge.durationDays)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("days")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .frame(height: 30)
                        
                        // Difficulty
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DIFFICULTY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.6))
                            
                            Text(challenge.difficulty.title)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(challenge.difficulty.color)
                        }
                        
                        Spacer()
                        
                        // XP Reward
                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16, weight: .bold))
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
                            
                            Text("\(challenge.xpReward) XP")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Action Section
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        // Join/Joined Button
                        Button(action: onJoin) {
                            HStack(spacing: 8) {
                                Image(systemName: isJoined ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                
                                Text(isJoined ? "Joined" : "Join Challenge")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(isJoined ? Color.white.opacity(0.8) : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        isJoined ?
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        categoryGradient
                                    )
                                    .shadow(
                                        color: isJoined ? Color.clear : challenge.category.gradient[0].opacity(0.4),
                                        radius: isJoined ? 0 : 8, x: 0, y: 4
                                    )
                            )
                        }
                        .disabled(isJoined)
                        .buttonStyle(PlainButtonStyle())
                        
                        // Leaderboard Button
                        Button(action: onLeaderboard) {
                            HStack(spacing: 6) {
                                Image(systemName: "list.number")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text("\(challenge.participantCount)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.1),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            ZStack {
                // Main background with glassmorphism
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
                
                // Subtle category glow
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                challenge.category.gradient[0].opacity(0.08),
                                Color.clear
                            ],
                            center: .topTrailing,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
            }
            .shadow(
                color: Color.black.opacity(0.3),
                radius: 20, x: 0, y: 10
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowIntensity = 0.8
            }
            
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

struct ActiveChallengeCard: View {
    let userChallenge: UserChallenge
    let onTap: () -> Void
    let onLeaderboard: () -> Void
    
    @State private var animateProgress = false
    @State private var pulseScale = 1.0
    
    private var progressPercentage: Double {
        guard let target = userChallenge.challengeTargetValue, target > 0 else { return 0 }
        return min(userChallenge.progressValue / target, 1.0)
    }
    
    private var isNearCompletion: Bool {
        progressPercentage >= 0.8
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(userChallenge.challengeTitle ?? "Challenge")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(userChallenge.challengeDescription ?? "")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 6)
                            .frame(width: 70, height: 70)
                        
                        Circle()
                            .trim(from: 0, to: animateProgress ? progressPercentage : 0)
                            .stroke(
                                LinearGradient(
                                    colors: isNearCompletion ? [
                                        Color(red: 1.0, green: 0.84, blue: 0.0),
                                        Color(red: 1.0, green: 0.65, blue: 0.0)
                                    ] : [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                            .shadow(
                                color: isNearCompletion ? 
                                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6) :
                                Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                radius: 8, x: 0, y: 4
                            )
                            .scaleEffect(pulseScale)
                        
                        Text("\(Int(progressPercentage * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                // Progress Details
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("\(Int(userChallenge.progressValue))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("/ \(Int(userChallenge.challengeTargetValue ?? 0)) \(userChallenge.challengeUnit ?? "")")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                    
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: isNearCompletion ? [
                                            Color(red: 1.0, green: 0.84, blue: 0.0),
                                            Color(red: 1.0, green: 0.65, blue: 0.0)
                                        ] : [
                                            Color(red: 0.49, green: 0.34, blue: 1.0),
                                            Color(red: 0.31, green: 0.25, blue: 0.84)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: animateProgress ? geometry.size.width * progressPercentage : 0,
                                    height: 8
                                )
                                .shadow(
                                    color: isNearCompletion ? 
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6) :
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.6),
                                    radius: 6, x: 0, y: 2
                                )
                        }
                    }
                    .frame(height: 8)
                }
                
                // Action Button
                HStack(spacing: 12) {
                    Button(action: onTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("View Details")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.1))
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onLeaderboard) {
                        Image(systemName: "list.number")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 22)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(24)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isNearCompletion ? 
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4) :
                                    Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 15, x: 0, y: 8
                )
        )
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.3)) {
                animateProgress = true
            }
            
            if isNearCompletion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.1
                }
            }
        }
    }
}

struct CompletedChallengeCard: View {
    let userChallenge: UserChallenge
    
    @State private var showCelebration = false
    @State private var glowOpacity = 0.3
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with trophy
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .bold))
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
                        
                        Text("COMPLETED")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .tracking(0.5)
                    }
                    
                    Text(userChallenge.challengeTitle ?? "Challenge")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let completedDate = userChallenge.completedDate {
                        Text("Completed on \(completedDate.dateValue(), style: .date)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Completion Badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(glowOpacity),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 60
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0),
                                    Color(red: 1.0, green: 0.65, blue: 0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(
                            color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6),
                            radius: 12, x: 0, y: 6
                        )
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCelebration ? 1.2 : 1.0)
                }
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TARGET ACHIEVED")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Text("\(Int(userChallenge.challengeTargetValue ?? 0))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(userChallenge.challengeUnit ?? "")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("XP EARNED")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        
                        Text("100 XP")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    }
                }
            }
        }
        .padding(24)
        .background(
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
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                    radius: 20, x: 0, y: 10
                )
        )
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.6).delay(0.2)) {
                showCelebration = true
            }
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }
}

#if DEBUG
struct PremiumChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PremiumChallengeCard(
                challenge: Challenge(
                    title: "10K Steps Daily",
                    description: "Walk 10,000 steps every day for a week to boost your cardiovascular health",
                    unit: .steps,
                    targetValue: 10000,
                    durationDays: 7,
                    category: .fitness,
                    difficulty: .medium,
                    xpReward: 150,
                    participantCount: 234,
                    iconName: "figure.walk"
                ),
                isJoined: false,
                onTap: {},
                onJoin: {},
                onLeaderboard: {}
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif