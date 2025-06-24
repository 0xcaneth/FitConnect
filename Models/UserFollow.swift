import Foundation
import FirebaseFirestore

struct UserFollow: Identifiable, Codable {
    @DocumentID var id: String?
    var followerId: String // User who follows
    var followingId: String // User being followed
    var createdAt: Timestamp
    
    init(followerId: String, followingId: String) {
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = Timestamp(date: Date())
    }
}