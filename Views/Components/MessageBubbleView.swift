import SwiftUI
import FirebaseFirestore
import AVFoundation
import AVKit

struct MessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let userRole: String
    
    @State private var thumbnail: UIImage?
    @State private var showVideoPlayer = false
    @State private var isLoadingThumbnail = false
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                if let videoURL = message.videoURL {
                    // Video message
                    videoMessageView(videoURL: videoURL)
                } else {
                    // Text message
                    textMessageView
                }
                
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
        .sheet(isPresented: $showVideoPlayer) {
            if let videoURL = message.videoURL, let url = URL(string: videoURL) {
                VideoPlayerView(videoURL: url)
            }
        }
    }
    
    private var textMessageView: some View {
        Text(message.text)
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
    
    private func videoMessageView(videoURL: String) -> some View {
        Button {
            showVideoPlayer = true
        } label: {
            ZStack {
                // Thumbnail or placeholder
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 150)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(backgroundGradient)
                            .frame(width: 200, height: 150)
                            .overlay(
                                Group {
                                    if isLoadingThumbnail {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        VStack(spacing: 8) {
                                            Image(systemName: "video.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.white)
                                            Text("Workout Video")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            )
                    }
                }
                .cornerRadius(16, corners: cornerMask)
                
                // Play button overlay
                if thumbnail != nil {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .onAppear {
            loadThumbnail(from: videoURL)
        }
    }
    
    private var backgroundGradient: LinearGradient {
        if isFromCurrentUser {
            // Current user's messages - use role-specific colors
            if userRole == "dietitian" {
                return FitConnectColors.dietitianBubble
            } else {
                return FitConnectColors.clientBubble
            }
        } else {
            // Other user's messages - use opposite colors
            if userRole == "dietitian" {
                return FitConnectColors.clientBubble
            } else {
                return FitConnectColors.dietitianBubble
            }
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
    
    private func loadThumbnail(from videoURLString: String) {
        guard let url = URL(string: videoURLString) else { return }
        
        isLoadingThumbnail = true
        
        Task {
            do {
                let thumbnail = try await VideoUploadService.shared.generateThumbnail(from: url)
                await MainActor.run {
                    self.thumbnail = thumbnail
                    self.isLoadingThumbnail = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingThumbnail = false
                }
                print("Failed to generate thumbnail: \(error)")
            }
        }
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let videoURL: URL
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .onAppear {
                        // Auto-play video
                        let player = AVPlayer(url: videoURL)
                        player.play()
                    }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#if DEBUG
struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        let previewMessageSent = ChatMessage(
            id: "msg1",
            chatId: "chat123",
            senderId: "currentUser",
            senderName: "Current User",
            text: "This is a message sent by the current user.",
            timestamp: Timestamp(date: Date()),
            isReadByRecipient: false
        )
        let previewMessageReceived = ChatMessage(
            id: "msg2",
            chatId: "chat123",
            senderId: "otherUser",
            senderName: "Other User",
            text: "This is a message received from another user. It can be a bit longer to see how text wrapping works.",
            timestamp: Timestamp(date: Date(timeIntervalSinceNow: -60)), // 1 minute ago
            isReadByRecipient: true
        )
        
        let previewVideoMessage = ChatMessage(
            id: "msg3",
            chatId: "chat123",
            senderId: "currentUser",
            senderName: "Current User",
            text: "🎥 Workout Video",
            timestamp: Timestamp(date: Date()),
            isReadByRecipient: false,
            videoURL: "https://example.com/video.mp4"
        )

        VStack(spacing: 20) {
            MessageBubbleView(
                message: previewMessageSent,
                isFromCurrentUser: true,
                userRole: "client"
            )
            MessageBubbleView(
                message: previewMessageReceived,
                isFromCurrentUser: false,
                userRole: "client"
            )
            MessageBubbleView(
                message: previewVideoMessage,
                isFromCurrentUser: true,
                userRole: "client"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif
