import Foundation
import FirebaseFirestore

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    let postId: String
    let authorId: String
    let authorName: String
    let authorPhotoURL: String?
    let text: String
    let timestamp: Timestamp
    
    init(postId: String, authorId: String, authorName: String, authorPhotoURL: String? = nil, text: String, timestamp: Timestamp = Timestamp(date: Date())) {
        self.postId = postId
        self.authorId = authorId
        self.authorName = authorName
        self.authorPhotoURL = authorPhotoURL
        self.text = text
        self.timestamp = timestamp
    }
}