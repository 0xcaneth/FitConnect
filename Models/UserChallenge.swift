import Foundation
import FirebaseFirestore


struct UserChallenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // Bu, challengeId ile aynı olacak şekilde ayarlanabilir veya ayrı bir doküman ID'si olabilir.
                               // Genellikle challengeId'yi kullanmak daha pratiktir.
    var challengeId: String // Hangi challenge'a ait olduğunu belirtir
    var userId: String // Hangi kullanıcıya ait olduğunu belirtir
    var progressValue: Double = 0.0
    var isCompleted: Bool = false
    var completedDate: Timestamp?
    var joinedDate: Timestamp? = Timestamp(date: Date())
    var lastUpdated: Timestamp? = Timestamp(date: Date())

    // Challenge detaylarını kolayca çekebilmek için (opsiyonel, denormalizasyon)
    var challengeTitle: String?
    var challengeTargetValue: Double?
    var challengeUnit: String?


    enum CodingKeys: String, CodingKey {
        case id
        case challengeId
        case userId
        case progressValue
        case isCompleted
        case completedDate
        case joinedDate
        case lastUpdated
        case challengeTitle
        case challengeTargetValue
        case challengeUnit
    }
}
