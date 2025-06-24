import Foundation
import FirebaseFirestore

enum ReportType: String, Codable {
    case post
    case comment
}

struct Report: Codable, Identifiable {
    @DocumentID var id: String?
    var reportType: ReportType
    var postId: String? // Relevant if reportType is .post or .comment
    var commentId: String? // Relevant if reportType is .comment
    var reportedContentCreatorId: String // UID of the user who created the post/comment
    var reportedByUserId: String // UID of the user making the report
    var reason: String // User-provided reason for the report
    var timestamp: Timestamp

    // Initializer for Post Report
    init(id: String? = nil, postId: String, reportedContentCreatorId: String, reportedByUserId: String, reason: String, timestamp: Timestamp = Timestamp(date:Date())) {
        self.id = id
        self.reportType = .post
        self.postId = postId
        self.commentId = nil
        self.reportedContentCreatorId = reportedContentCreatorId
        self.reportedByUserId = reportedByUserId
        self.reason = reason
        self.timestamp = timestamp
    }

    // Initializer for Comment Report
    init(id: String? = nil, postId: String, commentId: String, reportedContentCreatorId: String, reportedByUserId: String, reason: String, timestamp: Timestamp = Timestamp(date:Date())) {
        self.id = id
        self.reportType = .comment
        self.postId = postId
        self.commentId = commentId
        self.reportedContentCreatorId = reportedContentCreatorId
        self.reportedByUserId = reportedByUserId
        self.reason = reason
        self.timestamp = timestamp
    }
}