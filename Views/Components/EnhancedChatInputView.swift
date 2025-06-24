import SwiftUI
import PhotosUI
import AVFoundation
import AVKit

@available(iOS 16.0, *)
struct EnhancedChatInputView: View {
    @Binding var text: String
    @State private var textHeight: CGFloat = 40
    @State private var showingAttachmentOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingVideoPicker = false
    @State private var showingWorkoutVideoRecorder = false
    @State private var showingDocumentPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isRecording = false
    @State private var uploadProgress: Double = 0
    @State private var isUploading = false
    
    let chatId: String
    let sender: ParticipantInfo
    let recipientId: String
    let onSendText: () -> Void
    let onSendImage: (Data) -> Void
    let onSendVideo: (URL) -> Void
    let onTypingChanged: (Bool) -> Void
    
    private var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Upload progress bar
            if isUploading {
                ProgressView(value: uploadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: FitConnectColors.accentPurple))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            
            // Input area
            HStack(alignment: .bottom, spacing: 12) {
                // Attachment button
                attachmentButton
                
                // Text input area
                textInputArea
                
                // Send/Voice button
                actionButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .fill(FitConnectColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
            )
        }
        .sheet(isPresented: $showingAttachmentOptions) {
            AttachmentOptionsView(
                onPhotoSelected: {
                    showingAttachmentOptions = false
                    showingPhotoPicker = true
                },
                onVideoSelected: {
                    showingAttachmentOptions = false
                    showingVideoPicker = true
                },
                onWorkoutVideoSelected: {
                    showingAttachmentOptions = false
                    showingWorkoutVideoRecorder = true
                },
                onFileSelected: {
                    showingAttachmentOptions = false
                    showingDocumentPicker = true
                },
                onCancel: {
                    showingAttachmentOptions = false
                }
            )
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .sheet(isPresented: $showingVideoPicker) {
            VideoPickerView { videoURL in
                Task {
                    await uploadVideo(videoURL)
                }
            }
        }
        .sheet(isPresented: $showingWorkoutVideoRecorder) {
            WorkoutVideoRecorderSheet(
                isPresented: $showingWorkoutVideoRecorder,
                onVideoRecorded: { videoURL in
                    Task {
                        await uploadVideo(videoURL)
                    }
                }
            )
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView { urls in
                // Handle document selection
                print("Selected documents: \(urls)")
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await uploadImage(data)
                    
                    // Success feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            }
        }
        .onChange(of: text) { newText in
            updateTextHeight()
            onTypingChanged(!newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    
    private var attachmentButton: some View {
        Button(action: {
            showingAttachmentOptions = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(FitConnectColors.accentPurple)
                )
        }
        .disabled(isUploading)
    }
    
    private var textInputArea: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Type a message...")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(FitConnectColors.textPrimary)
                    .background(Color.clear)
                    .frame(minHeight: 24, maxHeight: min(textHeight, 100))
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(FitConnectColors.inputBackground)
        )
        .frame(height: max(40, min(textHeight + 16, 116)))
        .animation(.easeInOut(duration: 0.1), value: textHeight)
    }
    
    private var actionButton: some View {
        Button(action: {
            if isEmpty {
                // Toggle voice recording
                isRecording.toggle()
                // TODO: Implement voice recording
            } else {
                onSendText()
                text = ""
                updateTextHeight()
            }
        }) {
            Image(systemName: isEmpty ? (isRecording ? "stop.fill" : "mic.fill") : "paperplane.fill")
                .font(.system(size: isEmpty ? 18 : 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            isEmpty && isRecording ? 
                            LinearGradient(colors: [.red.opacity(0.8), .red], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [FitConnectColors.accentPurple, FitConnectColors.accentPurple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .scaleEffect(isEmpty && isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: isRecording)
        }
        .disabled(isUploading)
    }
    
    // MARK: - Helper Functions
    
    private func updateTextHeight() {
        let font = UIFont.systemFont(ofSize: 17)
        let textView = UITextView()
        textView.font = font
        textView.text = text.isEmpty ? " " : text
        
        let fixedWidth = UIScreen.main.bounds.width - 100 // Account for margins and buttons
        let size = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        withAnimation(.easeInOut(duration: 0.1)) {
            textHeight = max(24, min(size.height, 100))
        }
    }
    
    @MainActor
    private func uploadImage(_ imageData: Data) async {
        isUploading = true
        uploadProgress = 0
        
        // Simulate upload progress
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            uploadProgress = Double(i) / 10.0
        }
        
        onSendImage(imageData)
        
        isUploading = false
        uploadProgress = 0
    }
    
    @MainActor
    private func uploadVideo(_ videoURL: URL) async {
        isUploading = true
        uploadProgress = 0
        
        // Simulate upload progress
        for i in 1...20 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            uploadProgress = Double(i) / 20.0
        }
        
        onSendVideo(videoURL)
        
        isUploading = false
        uploadProgress = 0
    }
}

// MARK: - Supporting Views

@available(iOS 16.0, *)
struct VideoPickerView: UIViewControllerRepresentable {
    let onVideoSelected: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoMaximumDuration = 60 // 60 seconds max
        picker.videoQuality = .typeMedium
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoSelected(videoURL)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct DocumentPickerView: UIViewControllerRepresentable {
    let onDocumentsSelected: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onDocumentsSelected(urls)
            parent.dismiss()
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct EnhancedChatInputView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            EnhancedChatInputView(
                text: .constant(""),
                chatId: "chat123",
                sender: ParticipantInfo(id: "user1", fullName: "John Doe"),
                recipientId: "user2",
                onSendText: {},
                onSendImage: { _ in },
                onSendVideo: { _ in },
                onTypingChanged: { _ in }
            )
        }
        .background(FitConnectColors.backgroundDark)
        .preferredColorScheme(.dark)
    }
}
#endif
