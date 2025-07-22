import SwiftUI
import FirebaseFirestore

/// 🔥 Trending Challenge Card - TikTok challenge style
@available(iOS 16.0, *)
struct TrendingChallengeCard: View {
    let challenge: Challenge
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var animateGlow = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with trend indicator
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                            .scaleEffect(animateGlow ? 1.2 : 1.0)
                        
                        Text("TRENDING")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(.orange.opacity(0.6), lineWidth: 1)
                            )
                    )
                    
                    Spacer()
                    
                    // Challenge category icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: challenge.category.gradient.map { $0.opacity(0.3) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: challenge.category.icon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: challenge.category.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                
                // Challenge info
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(challenge.description)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                // Challenge stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TARGET")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Text("\(formatTargetValue(challenge.targetValue))")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(challenge.unit.shortName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Color(hex: challenge.colorHex))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("DURATION")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text("\(challenge.durationDays)d")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Participant count with animation
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: challenge.colorHex))
                            
                            Text("\(formatParticipantCount(challenge.participantCount))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("joined")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Difficulty indicator
                        HStack(spacing: 4) {
                            ForEach(0..<difficultyStars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(challenge.difficulty.color)
                            }
                            
                            Text(challenge.difficulty.title.uppercased())
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(challenge.difficulty.color)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(challenge.difficulty.color.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(challenge.difficulty.color.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                }
                
                // Join button
                HStack {
                    Spacer()
                    
                    Button(action: onTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("JOIN CHALLENGE")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: challenge.category.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: challenge.category.gradient.map { $0.opacity(0.6) },
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: challenge.category.gradient.first?.opacity(0.3) ?? .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: challenge.colorHex).opacity(0.4),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: Color(hex: challenge.colorHex).opacity(0.15),
                radius: 15,
                x: 0,
                y: 8
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                    isPressed = false
                }
                onTap()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var difficultyStars: Int {
        switch challenge.difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        case .expert: return 4
        }
    }
    
    private func formatTargetValue(_ value: Double) -> String {
        if value >= 1000000 {
            return String(format: "%.1fM", value / 1000000)
        } else if value >= 1000 {
            return String(format: "%.1fK", value / 1000)
        } else if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
    
    private func formatParticipantCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct TrendingChallengeCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleChallenge = Challenge(
            title: "10K Steps Daily",
            description: "Walk 10,000 steps every day for a week",
            unit: .steps,
            targetValue: 10000,
            durationDays: 7,
            category: .fitness,
            difficulty: .medium,
            xpReward: 500,
            participantCount: 1250,
            colorHex: "#FF6B6B"
        )
        
        return VStack {
            TrendingChallengeCard(challenge: sampleChallenge) {
                print("Challenge tapped")
            }
            .frame(width: 200)
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif