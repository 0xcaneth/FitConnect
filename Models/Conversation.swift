import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String] // user UIDs
    var lastUpdated: Date
    var lastMessageText: String?
    var lastMessageSenderUID: String?
    var lastMessageTimestamp: Date?
    var otherParticipantName: String?
    var otherParticipantPhotoURL: String?
}