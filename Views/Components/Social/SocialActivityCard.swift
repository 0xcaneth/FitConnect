import SwiftUI
import FirebaseFirestore

/// 📱 Full Social Activity Card - Instagram post style
@available(iOS 16.0, *)
struct SocialActivityCard: View {
    let activity: SocialActivity
    let isGlobal: Bool
    
    @EnvironmentObject private var socialService: SocialService
    @State private var isLiked = false
    @State private var showingComments = false
    @State private var showingShareSheet = false
    @State private var likeAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // User header
            HStack(spacing: 12) {
                // Avatar with activity ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: activity.type.color), Color(hex: activity.type.color).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 46, height: 46)
                    
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
                                    .font(.system(size: 18))
                            )
                    }
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(activity.userName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if isGlobal {
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(activity.type.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: activity.type.color))
                        
                        Text("•")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text(timeAgoDisplay)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // More options button
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(90))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text(activity.content)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                
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
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                    .frame(height: 300)
                    .clipped()
                }
                
                // Achievements
                if !activity.achievements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(activity.achievements, id: \.self) { achievement in
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.yellow)
                                    
                                    Text(achievement)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.yellow.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 20) {
                // Like button
                Button(action: {
                    Task {
                        await handleLikeToggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isLiked ? .red : .white)
                            .scaleEffect(likeAnimation ? 1.3 : 1.0)
                        
                        if activity.likesCount > 0 {
                            Text("\(activity.likesCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Comment button
                Button(action: {
                    showingComments = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if activity.commentsCount > 0 {
                            Text("\(activity.commentsCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Share button
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if activity.sharesCount > 0 {
                            Text("\(activity.sharesCount)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Trending indicator
                if activity.isTrending {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.orange)
                        
                        Text("Trending")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: activity.type.color).opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .task {
            // Check if user has already liked this activity
            if let activityId = activity.id {
                isLiked = await socialService.hasUserLikedActivity(activityId)
            }
        }
        .sheet(isPresented: $showingComments) {
            // Comments view would go here
            Text("Comments Coming Soon")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheetView(activity: activity)
        }
    }
    
    // MARK: - Actions
    
    private func handleLikeToggle() async {
        guard let activityId = activity.id else { return }
        
        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isLiked.toggle()
            likeAnimation = true
        }
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                likeAnimation = false
            }
        }
        
        do {
            if isLiked {
                try await socialService.likeActivity(activityId)
            } else {
                try await socialService.unlikeActivity(activityId)
            }
        } catch {
            print("[SocialActivityCard] Error toggling like: \(error)")
            
            // Revert on error
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isLiked.toggle()
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var timeAgoDisplay: String {
        guard let createdAt = activity.createdAt else { return "now" }
        
        let date = createdAt.dateValue()
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Share Sheet View

struct ShareSheetView: View {
    let activity: SocialActivity
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Share to Social Media")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(SocialPlatform.allCases, id: \.self) { platform in
                        Button(action: {
                            Task {
                                // Handle sharing to specific platform
                                dismiss()
                            }
                        }) {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(platformColor(platform))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: platformIcon(platform))
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(platform.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func platformColor(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .instagram: return Color(hex: "#E4405F")
        case .tiktok: return Color(hex: "#000000")
        case .twitter: return Color(hex: "#1DA1F2")
        case .snapchat: return Color(hex: "#FFFC00")
        case .facebook: return Color(hex: "#1877F2")
        }
    }
    
    private func platformIcon(_ platform: SocialPlatform) -> String {
        switch platform {
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .twitter: return "bird.fill"
        case .snapchat: return "camera.viewfinder"
        case .facebook: return "f.circle.fill"
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SocialActivityCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleActivity = SocialActivity(
            userId: "user123",
            userName: "Alex Johnson",
            userAvatar: nil,
            type: .workoutCompleted,
            content: "Just smashed my personal record! 🔥💪\n\nCompleted a 45-minute HIIT workout and burned 520 calories. Feeling stronger every day!\n\n#FitnessJourney #HIITWorkout #PersonalRecord",
            imageURL: nil,
            challengeId: nil,
            workoutId: "workout123",
            achievements: ["Calorie Crusher", "Speed Demon", "Consistency King"],
            createdAt: Timestamp(date: Date().addingTimeInterval(-7200)),
            isPublic: true,
            engagementScore: 45.0
        )
        
        return ScrollView {
            SocialActivityCard(activity: sampleActivity, isGlobal: false)
                .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .environmentObject(SocialService.shared)
    }
}
#endif