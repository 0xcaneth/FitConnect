import SwiftUI
import FirebaseFirestore

/// 🎯 Social Activity Preview Card - Instagram Story style preview
@available(iOS 16.0, *)
struct SocialActivityPreviewCard: View {
    let activity: SocialActivity
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // User header
                HStack(spacing: 12) {
                    // Avatar
                    AsyncImage(url: URL(string: activity.userAvatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 16))
                            )
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: activity.type.color), Color(hex: activity.type.color).opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.userName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(timeAgoDisplay)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Activity type icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: activity.type.color).opacity(0.2))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: activity.type.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: activity.type.color))
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 12) {
                    Text(activity.content)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Activity image if available
                    if let imageURL = activity.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 20))
                                )
                        }
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Achievements if any
                    if !activity.achievements.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(activity.achievements, id: \.self) { achievement in
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.yellow)
                                        
                                        Text(achievement)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Capsule()
                                                    .stroke(.yellow.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Engagement stats
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.red)
                        
                        Text("\(activity.likesCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("\(activity.commentsCount)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    if activity.sharesCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.green)
                            
                            Text("\(activity.sharesCount)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if activity.isTrending {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Text("Trending")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(.orange.opacity(0.5), lineWidth: 1)
                                )
                        )
                    }
                }
                .font(.caption)
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
                                        Color(hex: activity.type.color).opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color(hex: activity.type.color).opacity(0.1), radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.98 : 1.0)
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
    }
    
    private var timeAgoDisplay: String {
        guard let createdAt = activity.createdAt else { return "now" }
        
        let date = createdAt.dateValue()
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SocialActivityPreviewCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleActivity = SocialActivity(
            userId: "user123",
            userName: "Alex Johnson",
            userAvatar: nil,
            type: .workoutCompleted,
            content: "Just completed an amazing HIIT workout! Burned 450 calories in 30 minutes 💪🔥",
            imageURL: nil,
            challengeId: nil,
            workoutId: "workout123",
            achievements: ["Calorie Crusher", "Speed Demon"],
            createdAt: Timestamp(date: Date().addingTimeInterval(-3600)),
            isPublic: true,
            engagementScore: 25.0
        )
        
        return VStack {
            SocialActivityPreviewCard(activity: sampleActivity) {
                print("Activity tapped")
            }
            .frame(width: 280)
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif