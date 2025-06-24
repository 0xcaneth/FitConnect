import SwiftUI
import AVFoundation
import Photos

@available(iOS 16.0, *)
struct WorkoutVideoRecorderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showVideoRecorder = false
    @State private var showVideoTrimmer = false
    @State private var recordedVideoURL: URL?
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var showError = false
    @State private var errorMessage = ""
    @Binding var isPresented: Bool
    let onVideoRecorded: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "video.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(FitConnectColors.accentPurple)
                        
                        Text("Record Workout Video")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(FitConnectColors.textPrimary)
                        
                        Text("Share your workout progress with your fitness team")
                            .font(.body)
                            .foregroundColor(FitConnectColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Features
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "timer",
                            title: "Up to 60 seconds",
                            description: "Perfect length for exercise demos"
                        )
                        
                        FeatureRow(
                            icon: "scissors",
                            title: "Trim & Edit",
                            description: "Cut to the perfect moment"
                        )
                        
                        FeatureRow(
                            icon: "icloud.and.arrow.up",
                            title: "Instant Upload",
                            description: "Share directly in your chat"
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Upload progress
                    if isUploading {
                        VStack(spacing: 16) {
                            ProgressView("Processing video...", value: uploadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: FitConnectColors.accentPurple))
                                .padding(.horizontal)
                            
                            Text("\(Int(uploadProgress * 100))% complete")
                                .font(.caption)
                                .foregroundColor(FitConnectColors.textSecondary)
                        }
                    }
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        Button {
                            showVideoRecorder = true
                        } label: {
                            HStack {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start Recording")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(FitConnectColors.accentPurple)
                            .cornerRadius(12)
                        }
                        .disabled(isUploading)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(FitConnectColors.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showVideoRecorder) {
                VideoRecorderView { recordedURL in
                    recordedVideoURL = recordedURL
                    showVideoTrimmer = true
                }
            }
            .fullScreenCover(isPresented: $showVideoTrimmer) {
                if let videoURL = recordedVideoURL {
                    VideoTrimView(videoURL: videoURL) { trimmedURL in
                        Task {
                            await processVideo(trimmedURL)
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func processVideo(_ videoURL: URL) async {
        await MainActor.run {
            isUploading = true
            uploadProgress = 0.0
        }
        
        do {
            // Simulate processing time
            await MainActor.run {
                uploadProgress = 0.3
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                uploadProgress = 0.7
            }
            
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                uploadProgress = 1.0
                isUploading = false
                onVideoRecorded(videoURL)
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = "Failed to process video: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showVideoRecorder = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showVideoRecorder = true
                    } else {
                        self.showPermissionError(for: "camera")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionError(for: "camera")
        @unknown default:
            showPermissionError(for: "camera")
        }
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            // Handle photo library access
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        // Handle successful authorization
                    } else {
                        self.showPermissionError(for: "photo library")
                    }
                }
            }
        case .denied, .restricted:
            showPermissionError(for: "photo library")
        @unknown default:
            showPermissionError(for: "photo library")
        }
    }
    
    private func showPermissionError(for type: String) {
        errorMessage = "\(type.capitalized) access is required. Please enable in Settings."
        showError = true
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(FitConnectColors.accentPurple)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PhotoLibraryVideoPicker: UIViewControllerRepresentable {
    let onVideoPicked: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoPicked: onVideoPicked)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onVideoPicked: (URL?) -> Void
        
        init(onVideoPicked: @escaping (URL?) -> Void) {
            self.onVideoPicked = onVideoPicked
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let videoURL = info[.mediaURL] as? URL
            onVideoPicked(videoURL)
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onVideoPicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct WorkoutVideoRecorderSheet_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutVideoRecorderSheet(isPresented: .constant(true)) { _ in }
            .preferredColorScheme(.dark)
    }
}
#endif
