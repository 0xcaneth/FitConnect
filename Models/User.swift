import Foundation
import FirebaseFirestore

struct FitConnectUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var createdAt: Date
    var profileImageURL: String?
    var age: Int?
    var weight: Double?
    var height: Double?
    var fitnessGoal: String?
    var activityLevel: String?
    var subscription: SubscriptionStatus?
    
    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case pro = "pro"
    }
    
    init(email: String, fullName: String) {
        self.email = email
        self.fullName = fullName
        self.createdAt = Date()
        self.subscription = .free
    }
}
