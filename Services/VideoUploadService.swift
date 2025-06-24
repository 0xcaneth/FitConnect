import Foundation
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

class VideoUploadService {
    static let shared = VideoUploadService()
    
    private let storage = Storage.storage()
    private let storageRef: StorageReference
    
    private init() {
        self.storageRef = storage.reference()
    }
    
    // MARK: - Video Upload
    
    func uploadVideo(_ videoURL: URL, for userId: String, chatId: String) async throws -> URL {
        let workoutId = UUID().uuidString
        let fileName = "\(UUID().uuidString).mp4"
        let videoRef = storageRef.child("workout_media/\(userId)/\(workoutId)/\(fileName)")
        
        // Create metadata
        let metadata = StorageMetadata()
        metadata.contentType = "video/mp4"
        metadata.customMetadata = [
            "uploadedBy": userId,
            "chatId": chatId,
            "workoutId": workoutId,
            "uploadDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        // Upload video
        let uploadTask = videoRef.putFile(from: videoURL, metadata: metadata)
        
        // Monitor upload progress (optional)
        uploadTask.observe(.progress) { snapshot in
            guard let progress = snapshot.progress else { return }
            let percentComplete = 100.0 * Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            print("Upload progress: \(percentComplete)%")
        }
        
        // Wait for upload completion
        _ = try await uploadTask
        
        // Get download URL
        let downloadURL = try await videoRef.downloadURL()
        
        return downloadURL
    }
    
    // MARK: - Video Thumbnail Generation
    
    func generateThumbnail(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Generate thumbnail at 1 second mark
        let time = CMTime(seconds: 1.0, preferredTimescale: 600)
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let cgImage = image else {
                    continuation.resume(throwing: NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not generate thumbnail"]))
                    return
                }
                
                let thumbnail = UIImage(cgImage: cgImage)
                continuation.resume(returning: thumbnail)
            }
        }
    }
    
    // MARK: - Video Validation
    
    func validateVideo(at url: URL) async throws -> Bool {
        let asset = AVAsset(url: url)
        
        // Check if video is valid
        guard try await asset.load(.isPlayable) else {
            throw NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video is not playable"])
        }
        
        // Check duration (max 60 seconds)
        let duration = try await asset.load(.duration)
        let durationInSeconds = CMTimeGetSeconds(duration)
        
        guard durationInSeconds <= 60 else {
            throw NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video duration must be 60 seconds or less"])
        }
        
        // Check file size (max 100MB)
        let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let maxSize = 100 * 1024 * 1024 // 100MB
        
        guard fileSize <= maxSize else {
            throw NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video file size must be 100MB or less"])
        }
        
        return true
    }
    
    // MARK: - Video Compression
    
    func compressVideo(at sourceURL: URL) async throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputURL = documentsDirectory.appendingPathComponent("compressed_\(UUID().uuidString).mp4")
        
        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: AVAsset(url: sourceURL), presetName: AVAssetExportPresetMediumQuality) else {
            throw NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create export session"])
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw exportSession.error ?? NSError(domain: "VideoUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Video compression failed"])
        }
        
        return outputURL
    }
}