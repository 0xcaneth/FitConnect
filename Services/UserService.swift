import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class UserService: ObservableObject {
    static let shared = UserService()
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var searchResults: [FitConnectUser] = []
    @Published var suggestedUsers: [FitConnectUser] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - User Profile
    func getUserProfile(userId: String) async throws -> FitConnectUser {
        let document = try await db.collection("users").document(userId).getDocument()
        
        guard document.exists else {
            throw UserServiceError.userNotFound
        }
        
        var user = try document.data(as: FitConnectUser.self)
        user.id = userId
        return user
    }
    
    func updateUserProfile(_ user: FitConnectUser) async throws {
        guard let userId = user.id else {
            throw UserServiceError.invalidUser
        }
        
        try await db.collection("users").document(userId).setData(from: user, merge: true)
    }
    
    // MARK: - Follow System
    func followUser(userId: String, currentUserId: String) async throws {
        let batch = db.batch()
        
        // Create follow relationship
        let followRef = db.collection("follows").document()
        let follow = UserFollow(followerId: currentUserId, followingId: userId)
        try batch.setData(from: follow, forDocument: followRef)
        
        // Update follower count
        let userRef = db.collection("users").document(userId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(1))], forDocument: userRef)
        
        // Update following count
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(1))], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    func unfollowUser(userId: String, currentUserId: String) async throws {
        // Find follow document
        let followQuery = db.collection("follows")
            .whereField("followerId", isEqualTo: currentUserId)
            .whereField("followingId", isEqualTo: userId)
        
        let followDocs = try await followQuery.getDocuments()
        
        guard let followDoc = followDocs.documents.first else {
            throw UserServiceError.followNotFound
        }
        
        let batch = db.batch()
        
        // Delete follow relationship
        batch.deleteDocument(followDoc.reference)
        
        // Update follower count
        let userRef = db.collection("users").document(userId)
        batch.updateData(["followersCount": FieldValue.increment(Int64(-1))], forDocument: userRef)
        
        // Update following count
        let currentUserRef = db.collection("users").document(currentUserId)
        batch.updateData(["followingCount": FieldValue.increment(Int64(-1))], forDocument: currentUserRef)
        
        try await batch.commit()
    }
    
    func isFollowing(userId: String, currentUserId: String) async throws -> Bool {
        let followQuery = db.collection("follows")
            .whereField("followerId", isEqualTo: currentUserId)
            .whereField("followingId", isEqualTo: userId)
        
        let followDocs = try await followQuery.getDocuments()
        return !followDocs.documents.isEmpty
    }
    
    func getFollowers(userId: String) async throws -> [FitConnectUser] {
        let followQuery = db.collection("follows")
            .whereField("followingId", isEqualTo: userId)
        
        let followDocs = try await followQuery.getDocuments()
        let followerIds = followDocs.documents.compactMap { doc in
            try? doc.data(as: UserFollow.self).followerId
        }
        
        var followers: [FitConnectUser] = []
        for followerId in followerIds {
            if let follower = try? await getUserProfile(userId: followerId) {
                followers.append(follower)
            }
        }
        
        return followers
    }
    
    func getFollowing(userId: String) async throws -> [FitConnectUser] {
        let followQuery = db.collection("follows")
            .whereField("followerId", isEqualTo: userId)
        
        let followDocs = try await followQuery.getDocuments()
        let followingIds = followDocs.documents.compactMap { doc in
            try? doc.data(as: UserFollow.self).followingId
        }
        
        var following: [FitConnectUser] = []
        for followingId in followingIds {
            if let user = try? await getUserProfile(userId: followingId) {
                following.append(user)
            }
        }
        
        return following
    }
    
    // MARK: - Search Users
    func searchUsers(query: String) async throws -> [FitConnectUser] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let usersQuery = db.collection("users")
            .whereField("fullName", isGreaterThanOrEqualTo: query)
            .whereField("fullName", isLessThan: query + "\u{FEFF}")
            .limit(to: 20)
        
        let snapshot = try await usersQuery.getDocuments()
        let users = snapshot.documents.compactMap { doc -> FitConnectUser? in
            var user = try? doc.data(as: FitConnectUser.self)
            user?.id = doc.documentID
            return user
        }
        
        await MainActor.run {
            searchResults = users
        }
        
        return users
    }
    
    func getSuggestedUsers(currentUserId: String) async throws -> [FitConnectUser] {
        isLoading = true
        defer { isLoading = false }
        
        let usersQuery = db.collection("users")
            .whereField("isPrivate", isEqualTo: false)
            .order(by: "followersCount", descending: true)
            .limit(to: 10)
        
        let snapshot = try await usersQuery.getDocuments()
        let users = snapshot.documents.compactMap { doc -> FitConnectUser? in
            guard doc.documentID != currentUserId else { return nil }
            var user = try? doc.data(as: FitConnectUser.self)
            user?.id = doc.documentID
            return user
        }
        
        await MainActor.run {
            suggestedUsers = users
        }
        
        return users
    }
}

enum UserServiceError: Error, LocalizedError {
    case userNotFound
    case invalidUser
    case followNotFound
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidUser:
            return "Invalid user data"
        case .followNotFound:
            return "Follow relationship not found"
        case .firestoreError(let message):
            return "Database error: \(message)"
        }
    }
}