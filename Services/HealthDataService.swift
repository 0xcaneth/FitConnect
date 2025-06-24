import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit

final class HealthDataService: ObservableObject {
    static let shared = HealthDataService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Create Health Data Entry
    func createHealthDataEntry(_ healthData: HealthData) async throws {
        guard let userId = healthData.userId.isEmpty ? nil : healthData.userId else {
            throw HealthDataError.invalidUserId
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let docRef = db.collection("users").document(userId).collection("healthData").document()
            var newHealthData = healthData
            newHealthData.id = docRef.documentID
            
            try await docRef.setData(from: newHealthData)
            print("[HealthDataService] Successfully created health data entry: \(docRef.documentID)")
        } catch {
            let errorMessage = "Failed to save health data: \(error.localizedDescription)"
            await MainActor.run {
                self.error = errorMessage
            }
            throw HealthDataError.saveFailed(errorMessage)
        }
    }
    
    // MARK: - Update Health Data Entry
    func updateHealthDataEntry(_ healthData: HealthData) async throws {
        guard let entryId = healthData.id, !entryId.isEmpty else {
            throw HealthDataError.invalidEntryId
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let docRef = db.collection("users").document(healthData.userId).collection("healthData").document(entryId)
            try await docRef.setData(from: healthData, merge: true)
            print("[HealthDataService] Successfully updated health data entry: \(entryId)")
        } catch {
            let errorMessage = "Failed to update health data: \(error.localizedDescription)"
            await MainActor.run {
                self.error = errorMessage
            }
            throw HealthDataError.updateFailed(errorMessage)
        }
    }
    
    // MARK: - Delete Health Data Entry
    func deleteHealthDataEntry(userId: String, entryId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let docRef = db.collection("users").document(userId).collection("healthData").document(entryId)
            try await docRef.delete()
            print("[HealthDataService] Successfully deleted health data entry: \(entryId)")
        } catch {
            let errorMessage = "Failed to delete health data: \(error.localizedDescription)"
            await MainActor.run {
                self.error = errorMessage
            }
            throw HealthDataError.deleteFailed(errorMessage)
        }
    }
    
    // MARK: - Fetch Health Data (for compatibility)
    func fetchHealthData() async throws -> [HealthData] {
        // For now, return empty array - real implementation would fetch from Firestore
        return []
    }
    
    // MARK: - Save Health Data (for compatibility)
    func saveHealthData(_ healthData: HealthData) async throws {
        if healthData.id != nil {
            try await updateHealthDataEntry(healthData)
        } else {
            try await createHealthDataEntry(healthData)
        }
    }
    
    // MARK: - Delete Health Data (for compatibility)
    func deleteHealthData(_ id: String?) async throws {
        guard let id = id else { return }
        // We need userId - this is a simplified version
        // In real implementation, we'd need to get userId from the health data
        throw HealthDataError.invalidEntryId
    }
    
    // MARK: - Real-time Health Data Listener
    func listenToHealthData(for userId: String) -> AnyPublisher<[HealthData], Error> {
        return Future { promise in
            let listener = self.db.collection("users")
                .document(userId)
                .collection("healthData")
                .order(by: "date", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(HealthDataError.fetchFailed(error.localizedDescription)))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let healthDataEntries = documents.compactMap { document -> HealthData? in
                        do {
                            var entry = try document.data(as: HealthData.self)
                            entry.id = document.documentID
                            return entry
                        } catch {
                            print("[HealthDataService] Error decoding health data: \(error)")
                            return nil
                        }
                    }
                    
                    promise(.success(healthDataEntries))
                }
            
            // Store listener for cleanup if needed
            // Note: In production, you'd want to manage listener cleanup
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Get Latest Health Data for Client
    func getLatestHealthData(for userId: String) async throws -> HealthData? {
        do {
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("healthData")
                .order(by: "date", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            guard let document = snapshot.documents.first else {
                return nil
            }
            
            var healthData = try document.data(as: HealthData.self)
            healthData.id = document.documentID
            return healthData
        } catch {
            let errorMessage = "Failed to fetch latest health data: \(error.localizedDescription)"
            await MainActor.run {
                self.error = errorMessage
            }
            throw HealthDataError.fetchFailed(errorMessage)
        }
    }
    
    // MARK: - Upload Images to Firebase Storage
    func uploadImages(_ images: [UIImage], for userId: String, type: ImageType) async throws -> [String] {
        isLoading = true
        defer { isLoading = false }
        
        var uploadedURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            do {
                let url = try await uploadSingleImage(image, for: userId, type: type, index: index)
                uploadedURLs.append(url)
            } catch {
                print("[HealthDataService] Failed to upload image \(index): \(error)")
                // Continue with other images
            }
        }
        
        return uploadedURLs
    }
    
    private func uploadSingleImage(_ image: UIImage, for userId: String, type: ImageType, index: Int) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw HealthDataError.imageProcessingFailed
        }
        
        let fileName = "\(UUID().uuidString)_\(Date().timeIntervalSince1970)_\(index).jpg"
        let path = "\(type.rawValue)/\(userId)/\(fileName)"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw HealthDataError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Clear Error
    func clearError() {
        DispatchQueue.main.async {
            self.error = nil
        }
    }
}

// MARK: - Supporting Types
enum HealthDataError: LocalizedError {
    case invalidUserId
    case invalidEntryId
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case fetchFailed(String)
    case uploadFailed(String)
    case imageProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID provided"
        case .invalidEntryId:
            return "Invalid entry ID provided"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .imageProcessingFailed:
            return "Failed to process image"
        }
    }
}

enum ImageType: String {
    case mealPhotos = "meal_photos"
    case workoutMedia = "workout_media"
    case progressPhotos = "progress_photos"
}
