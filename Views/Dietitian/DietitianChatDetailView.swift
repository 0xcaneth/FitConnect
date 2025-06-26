import SwiftUI
import FirebaseFirestore
import PhotosUI
import AVFoundation

@available(iOS 16.0, *)
struct DietitianChatDetailView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) var dismiss
    @StateObject private var messagingService = MessagingService.shared
    
    let recipientId: String
    let recipientName: String
    let recipientAvatarUrl: String?
    
    @State private var messages: [Message] = []
    @State private var newMessageText: String = ""
    @State private var isLoading = true
    @State private var showAttachmentOptions = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isSnapMode = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedVideo: PhotosPickerItem?
    @State private var selectedSnapPhoto: PhotosPickerItem?
    @State private var showingPhotoLibrary = false
    @State private var showingVideoLibrary = false
    @State private var showingSnapLibrary = false
    @State private var showCamera = false
    @State private var showVideoRecorder = false

    var body: some View {
        VStack(spacing: 0) {
            customHeader
            
            if isLoading {
                loadingView
            } else if messages.isEmpty {
                emptyStateView
            } else {
                messagesView
            }
            
            messageInputView
        }
        .background(FitConnectColors.backgroundDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            loadMessages()
        }
        .onChange(of: selectedPhoto) { newPhoto in
            if let newPhoto = newPhoto {
                Task {
                    await handlePhotoSelection(newPhoto)
                    selectedPhoto = nil
                }
            }
        }
        .onChange(of: selectedVideo) { newVideo in
            if let newVideo = newVideo {
                Task {
                    await handleVideoSelection(newVideo)
                    selectedVideo = nil
                }
            }
        }
        .onChange(of: selectedSnapPhoto) { newSnap in
            if let newSnap = newSnap {
                Task {
                    await handleSnapPhotoSelection(newSnap)
                    selectedSnapPhoto = nil
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .photosPicker(
            isPresented: $showingPhotoLibrary,
            selection: $selectedPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .photosPicker(
            isPresented: $showingVideoLibrary,
            selection: $selectedVideo,
            matching: .videos,
            photoLibrary: .shared()
        )
        .photosPicker(
            isPresented: $showingSnapLibrary,
            selection: $selectedSnapPhoto,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $showCamera) {
            CameraCaptureView { image in
                Task {
                    if isSnapMode {
                        await handleSnapCapture(image)
                        isSnapMode = false
                    } else {
                        await handleImageCapture(image)
                    }
                }
            }
        }
        .sheet(isPresented: $showVideoRecorder) {
            VideoRecorderView { videoUrl in
                Task {
                    await handleVideoCapture(videoUrl)
                }
            }
        }
    }
    
    private var customHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            HStack(spacing: 12) {
                AsyncImage(url: URL(string: recipientAvatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(FitConnectColors.accentCyan)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipientName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Client")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FitConnectColors.backgroundDark)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
            Text("Loading conversation...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(FitConnectColors.accentCyan)
            
            Text("Start the conversation!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Send a message to begin chatting with your client.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.senderId == session.currentUserId,
                            onSnapTap: {
                                Task {
                                    await handleSnapTap(message)
                                }
                            }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessageId = messages.last?.id {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        proxy.scrollTo(lastMessageId, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(spacing: 12) {
                // Attachment button
                Button {
                    showAttachmentOptions = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(FitConnectColors.accentCyan)
                }
                .confirmationDialog("Send...", isPresented: $showAttachmentOptions) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Photo", systemImage: "photo")
                    }
                    PhotosPicker(selection: $selectedVideo, matching: .videos) {
                        Label("Video", systemImage: "video.fill")
                    }
                    Button("Camera") {
                        checkCameraPermissionAndOpen()
                    }
                    Button("Video") {
                        checkCameraPermissionAndOpenVideo()
                    }
                    Button("Snap") {
                        isSnapMode = true
                        checkCameraPermissionAndOpen()
                    }
                    Button("Cancel", role: .cancel) {}
                }
                
                TextField("Message \(recipientName)…", text: $newMessageText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                Button {
                    Task {
                        await sendTextMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(
                                    newMessageText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.gray.opacity(0.3)
                                        : FitConnectColors.accentCyan
                                )
                        )
                        .scaleEffect(
                            newMessageText.trimmingCharacters(in: .whitespaces).isEmpty
                                ? 0.9 : 1.0
                        )
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, safeAreaBottomInset())
            .background(FitConnectColors.backgroundDark)
        }
    }
    
    private func loadMessages() {
        Task {
            do {
                for try await messageList in messagingService.getMessages(with: recipientId) {
                    await MainActor.run {
                        self.messages = messageList
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func sendTextMessage() async {
        let text = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        newMessageText = ""
        
        do {
            try await messagingService.sendTextMessage(
                to: recipientId,
                text: text,
                senderName: session.currentUser?.fullName ?? "Dietitian",
                senderAvatarUrl: session.currentUser?.photoURL
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                try await messagingService.sendPhotoMessage(
                    to: recipientId,
                    image: image,
                    senderName: session.currentUser?.fullName ?? "Dietitian",
                    senderAvatarUrl: session.currentUser?.photoURL
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleImageCapture(_ image: UIImage) async {
        do {
            try await messagingService.sendPhotoMessage(
                to: recipientId,
                image: image,
                senderName: session.currentUser?.fullName ?? "Dietitian",
                senderAvatarUrl: session.currentUser?.photoURL
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleVideoSelection(_ item: PhotosPickerItem) async {
        do {
            if let url = try await item.loadTransferable(type: URL.self) {
                try await messagingService.sendVideoMessage(
                    to: recipientId,
                    videoUrl: url,
                    senderName: session.currentUser?.fullName ?? "Dietitian",
                    senderAvatarUrl: session.currentUser?.photoURL
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleSnapPhotoSelection(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                try await messagingService.sendSnapMessage(
                    to: recipientId,
                    image: image,
                    senderName: session.currentUser?.fullName ?? "Dietitian",
                    senderAvatarUrl: session.currentUser?.photoURL
                )
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleVideoCapture(_ videoUrl: URL) async {
        do {
            try await messagingService.sendVideoMessage(
                to: recipientId,
                videoUrl: videoUrl,
                senderName: session.currentUser?.fullName ?? "Dietitian",
                senderAvatarUrl: session.currentUser?.photoURL
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleSnapTap(_ message: Message) async {
        guard message.type == .snap, !(message.isConsumed ?? false) else { return }
        
        do {
            try await messagingService.markSnapAsConsumed(message)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func checkCameraPermissionAndOpen() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        errorMessage = "Camera access is required to take photos"
                        showError = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is denied. Please enable it in Settings."
            showError = true
        @unknown default:
            errorMessage = "Camera access is not available"
            showError = true
        }
    }
    
    private func checkCameraPermissionAndOpenVideo() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showVideoRecorder = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showVideoRecorder = true
                    } else {
                        errorMessage = "Camera access is required to record videos"
                        showError = true
                    }
                }
            }
        case .denied, .restricted:
            errorMessage = "Camera access is denied. Please enable it in Settings."
            showError = true
        @unknown default:
            errorMessage = "Camera access is not available"
            showError = true
        }
    }
    
    private func handleSnapCapture(_ image: UIImage) async {
        do {
            try await messagingService.sendSnapMessage(
                to: recipientId,
                image: image,
                senderName: session.currentUser?.fullName ?? "Dietitian",
                senderAvatarUrl: session.currentUser?.photoURL
            )
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

private func safeAreaBottomInset() -> CGFloat {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return 0
    }
    return window.safeAreaInsets.bottom
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianChatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let mockSession = SessionStore.previewStore(isLoggedIn: true, role: "dietitian")
        return DietitianChatDetailView(
            recipientId: "client123",
            recipientName: "John Smith",
            recipientAvatarUrl: nil
        )
        .environmentObject(mockSession)
        .preferredColorScheme(.dark)
    }
}
#endif