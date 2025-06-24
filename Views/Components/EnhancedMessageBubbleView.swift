import SwiftUI
import AVFoundation
import AVKit
import FirebaseFirestore

@available(iOS 16.0, *)
struct EnhancedMessageBubbleView: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let userRole: String?
    let onRetry: (() -> Void)?
    let onImageTap: ((String) -> Void)?
    let onVideoTap: ((String) -> Void)?
    
    @State private var videoThumbnail: UIImage?
    @State private var isLoadingThumbnail = false
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
                messageContent
            } else {
                avatarView
                messageContent
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    private var messageContent: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            // Message bubble
            messageBubble
            
            // Timestamp and status
            HStack(spacing: 4) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if isFromCurrentUser {
                    messageStatusView
                }
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: isFromCurrentUser ? .trailing : .leading)
    }
    
    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Attachment content
            if let attachmentType = message.attachmentType {
                attachmentView(for: attachmentType)
            }
            
            // Text content
            if !message.text.isEmpty {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            // Failed message indicator
            Group {
                if message.messageSendStatus == .failed {
                    Button(action: { onRetry?() }) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(8)
                }
            }
        )
    }
    
    @ViewBuilder
    private func attachmentView(for type: AttachmentType) -> some View {
        switch type {
        case .image:
            if let imageURL = message.imageURL {
                imageAttachmentView(url: imageURL)
            }
        case .video:
            if let videoURL = message.videoURL {
                videoAttachmentView(url: videoURL)
            }
        case .file:
            if let fileURL = message.fileURL {
                fileAttachmentView(url: fileURL, fileName: message.fileName)
            }
        }
    }
    
    private func imageAttachmentView(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 150)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    )
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 200, maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        onImageTap?(url)
                    }
            case .failure:
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 150)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func videoAttachmentView(url: String) -> some View {
        ZStack {
            if let thumbnail = videoThumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 150)
                    .overlay(
                        Group {
                            if isLoadingThumbnail {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                            } else {
                                Image(systemName: "video")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        }
                    )
            }
            
            // Play button overlay
            Button(action: {
                onVideoTap?(url)
            }) {
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
        }
        .onAppear {
            if videoThumbnail == nil {
                generateVideoThumbnail(from: url)
            }
        }
    }
    
    private func fileAttachmentView(url: String, fileName: String?) -> some View {
        HStack {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(fileName ?? "File")
                    .font(.body)
                    .foregroundColor(textColor)
                
                if let fileSize = message.fileSize {
                    Text(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    private var avatarView: some View {
        AsyncImage(url: URL(string: message.senderAvatarURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            default:
                Circle()
                    .fill(FitConnectColors.accentPurple)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(message.senderName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
    
    private var bubbleBackground: some View {
        if isFromCurrentUser {
            // Client bubble - purple gradient
            return AnyView(
                LinearGradient(
                    colors: [FitConnectColors.accentPurple, FitConnectColors.accentPurple.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            // Dietitian bubble - gray
            return AnyView(
                LinearGradient(
                    colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    private var textColor: Color {
        return .white
    }
    
    private var messageStatusView: some View {
        Group {
            switch message.messageSendStatus {
            case .sending:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                    .scaleEffect(0.6)
            case .sent:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            case .none:
                if message.isReadByRecipient {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        let date = timestamp.dateValue()
        
        if Calendar.current.isDateInToday(date) {
            formatter.timeStyle = .short
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        
        return formatter.string(from: date)
    }
    
    private func generateVideoThumbnail(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        isLoadingThumbnail = true
        
        Task {
            do {
                let asset = AVAsset(url: url)
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                imageGenerator.maximumSize = CGSize(width: 200, height: 150)
                
                let time = CMTime(seconds: 1, preferredTimescale: 60)
                let cgImage = try await imageGenerator.image(at: time).image
                
                await MainActor.run {
                    self.videoThumbnail = UIImage(cgImage: cgImage)
                    self.isLoadingThumbnail = false
                }
            } catch {
                print("Failed to generate video thumbnail: \(error)")
                await MainActor.run {
                    self.isLoadingThumbnail = false
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EnhancedMessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Text message
            EnhancedMessageBubbleView(
                message: ChatMessage(
                    chatId: "test",
                    senderId: "user1",
                    senderName: "John Doe",
                    text: "Hello, this is a test message",
                    timestamp: Timestamp(date: Date())
                ),
                isFromCurrentUser: true,
                userRole: "client",
                onRetry: nil,
                onImageTap: nil,
                onVideoTap: nil
            )
            
            // Image message
            EnhancedMessageBubbleView(
                message: ChatMessage(
                    chatId: "test",
                    senderId: "user2",
                    senderName: "Dietitian",
                    text: "Check out this meal plan",
                    timestamp: Timestamp(date: Date()),
                    imageURL: "https://example.com/image.jpg"
                ),
                isFromCurrentUser: false,
                userRole: "dietitian",
                onRetry: nil,
                onImageTap: nil,
                onVideoTap: nil
            )
        }
        .padding()
        .background(FitConnectColors.backgroundDark)
        .preferredColorScheme(.dark)
    }
}
#endif
