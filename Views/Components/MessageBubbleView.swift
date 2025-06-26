import SwiftUI
import AVKit

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let onSnapTap: () -> Void
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                messageContent
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            textMessageBubble
        case .photo:
            photoMessageBubble
        case .video:
            videoMessageBubble
        case .snap:
            snapMessageBubble
        }
    }
    
    private var textMessageBubble: some View {
        Text(message.text ?? "")
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .background(
                backgroundGradient
                    .cornerRadius(20, corners: cornerMask)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
    }
    
    private var photoMessageBubble: some View {
        Group {
            if let contentUrl = message.contentUrl, let url = URL(string: contentUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 150)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    private var videoMessageBubble: some View {
        Group {
            if let contentUrl = message.contentUrl, let url = URL(string: contentUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(width: 200, height: 150)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Failed to load video")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    )
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    private var snapMessageBubble: some View {
        Button(action: onSnapTap) {
            if message.isConsumedSnap {
                // Consumed snap
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "eye.slash")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("Snap viewed")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            } else {
                // Unconsumed snap
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "camera.filters")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Tap to view snap")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    )
            }
        }
        .disabled(message.isConsumedSnap)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    private var backgroundGradient: LinearGradient {
        if isFromCurrentUser {
            return LinearGradient(
                colors: [FitConnectColors.accentCyan, FitConnectColors.accentCyan.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [FitConnectColors.accentPurple, FitConnectColors.accentPurple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var cornerMask: UIRectCorner {
        if isFromCurrentUser {
            return [.topLeft, .topRight, .bottomLeft]
        } else {
            return [.topLeft, .topRight, .bottomRight]
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: message.timestamp.dateValue())
    }
}