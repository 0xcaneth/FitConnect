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
    var xp: Int? // Default to nil or 0, depending on preference. Let's start with nil.
    
    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case pro = "pro"
    }
    
    init(email: String, fullName: String, xp: Int? = nil) { 
        self.email = email
        self.fullName = fullName
        self.createdAt = Date()
        self.subscription = .free
        self.xp = xp
    }
}
