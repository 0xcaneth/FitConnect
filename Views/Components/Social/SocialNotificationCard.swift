import SwiftUI
import FirebaseFirestore

/// Social Notification Card - Instagram notification style
@available(iOS 16.0, *)
struct SocialNotificationCard: View {
    let notification: SocialNotification
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Notification icon with user avatar overlay
                ZStack {
                    // Background circle
                    Circle()
                        .fill(notificationTypeColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    // User avatar (smaller, positioned)
                    AsyncImage(url: URL(string: notification.senderAvatar ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            )
                    }
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Notification type icon (bottom-right overlay)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(notificationTypeColor)
                                    .frame(width: 18, height: 18)
                                
                                Image(systemName: notification.type.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 4, y: 4)
                        }
                    }
                }
                
                // Notification content
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text(notification.senderName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(notification.type.displayText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .lineLimit(1)
                    
                    if let content = notification.content, !content.isEmpty {
                        Text(content)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Text(timeAgoDisplay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action button based on notification type
                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(notification.isRead ? .clear : .white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                notification.isRead ? 
                                AnyShapeStyle(.clear) :  
                                AnyShapeStyle(LinearGradient(
                                    colors: [notificationTypeColor.opacity(0.3), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )),
                                lineWidth: 1
                            )
                    )
            )
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
    
    // MARK: - Action Button
    
    @ViewBuilder
    private var actionButton: some View {
        switch notification.type {
        case .follow:
            Button("Follow Back") {
                // Handle follow back action
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#FF6B9D"), Color(hex: "#8E24AA")],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            
        case .challengeInvite:
            Button("Join") {
                // Handle challenge join action
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: [Color.green, Color.teal],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 12)
            )
            
        case .like, .comment:
            Button("View") {
                // Handle view post action
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(notificationTypeColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(notificationTypeColor.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(notificationTypeColor.opacity(0.4), lineWidth: 1)
                    )
            )
            
        case .achievement:
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
                
                Text("Achievement")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.yellow.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(.yellow.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Helper Properties
    
    private var notificationTypeColor: Color {
        switch notification.type {
        case .like: return .red
        case .comment: return .blue
        case .follow: return Color(hex: "#FF6B9D")
        case .challengeInvite: return .green
        case .achievement: return .yellow
        }
    }
    
    private var timeAgoDisplay: String {
        let createdAt = notification.createdAt
        
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
        } else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SocialNotificationCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SocialNotificationCard(
                notification: SocialNotification(
                    recipientId: "user123",
                    senderId: "user456",
                    senderName: "Alex Johnson",
                    senderAvatar: nil,
                    type: .like,
                    activityId: "activity123",
                    content: nil,
                    createdAt: Timestamp(date: Date().addingTimeInterval(-3600)),
                    isRead: false
                )
            ) {
                print("Notification tapped")
            }
            
            SocialNotificationCard(
                notification: SocialNotification(
                    recipientId: "user123",
                    senderId: "user789",
                    senderName: "Sarah Wilson",
                    senderAvatar: nil,
                    type: .comment,
                    activityId: "activity456",
                    content: "Great job on completing that challenge! 💪",
                    createdAt: Timestamp(date: Date().addingTimeInterval(-7200)),
                    isRead: true
                )
            ) {
                print("Comment notification tapped")
            }
            
            SocialNotificationCard(
                notification: SocialNotification(
                    recipientId: "user123",
                    senderId: "user101",
                    senderName: "Mike Chen",
                    senderAvatar: nil,
                    type: .follow,
                    activityId: nil,
                    content: nil,
                    createdAt: Timestamp(date: Date().addingTimeInterval(-86400)),
                    isRead: false
                )
            ) {
                print("Follow notification tapped")
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif