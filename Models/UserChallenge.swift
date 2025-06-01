import Foundation
import FirebaseFirestore

struct UserChallenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // Bu, challengeId ile aynı olacak şekilde ayarlanabilir veya ayrı bir doküman ID'si olabilir.
                               // Genellikle challengeId'yi kullanmak daha pratiktir.
    var challengeId: String
    var userId: String
    var progressValue: Double = 0.0
    var isCompleted: Bool = false
    var completedDate: Timestamp?
    var joinedDate: Timestamp? = Timestamp(date: Date())
    var lastUpdated: Timestamp? = Timestamp(date: Date())

    var challengeTitle: String?
    var challengeDescription: String? // Optional String defaults to nil
    var challengeTargetValue: Double?
    var challengeUnit: String?

    // KEEP: Memberwise initializer - it's useful and provides defaults
    init(id: String? = nil, challengeId: String, userId: String, progressValue: Double = 0.0, isCompleted: Bool = false, completedDate: Timestamp? = nil, joinedDate: Timestamp? = Timestamp(date:Date()), lastUpdated: Timestamp? = Timestamp(date:Date()), challengeTitle: String?, challengeDescription: String?, challengeTargetValue: Double?, challengeUnit: String?) {
        self.id = id
        self.challengeId = challengeId
        self.userId = userId
        self.progressValue = progressValue
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.joinedDate = joinedDate
        self.lastUpdated = lastUpdated
        self.challengeTitle = challengeTitle
        self.challengeDescription = challengeDescription
        self.challengeTargetValue = challengeTargetValue
        self.challengeUnit = challengeUnit
    }
}
