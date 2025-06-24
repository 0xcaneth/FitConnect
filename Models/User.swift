import Foundation
import FirebaseFirestore // Ensure Firestore is imported for @DocumentID and Timestamp

struct FitConnectUser: Identifiable, Codable {
    var id: String?
    var email: String
    var fullName: String
    var createdAt: Date 
    var photoURL: String? 
    var age: Int?
    var weight: Double?
    var height: Double?
    var fitnessGoal: String?
    var activityLevel: String?
    var subscription: SubscriptionStatus?
    var xp: Int? 
    var isEmailVerified: Bool? 
    var role: String // "client", "dietitian", etc.
    var assignedDietitianId: String?
    var providerData: [[String: String]]? // Array of dictionaries for provider info
    var lastLoginAt: Timestamp? // Using Firestore Timestamp
    var bio: String?
    var isPrivate: Bool?
    var level: Int?


    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case pro = "pro"
    }
    
    init(id: String? = nil, 
         email: String, 
         fullName: String, 
         photoURL: String? = nil,
         xp: Int? = 0, 
         level: Int? = 1,
         isEmailVerified: Bool? = false, 
         createdAt: Date = Date(), 
         subscription: SubscriptionStatus = .free,
         role: String = "client", // Default role
         assignedDietitianId: String? = nil,
         providerData: [[String: String]]? = nil,
         lastLoginAt: Timestamp? = nil,
         bio: String? = "",
         isPrivate: Bool? = false) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.subscription = subscription
        self.xp = xp
        self.level = level
        self.isEmailVerified = isEmailVerified
        self.role = role
        self.assignedDietitianId = assignedDietitianId
        self.providerData = providerData
        self.lastLoginAt = lastLoginAt
        self.bio = bio
        self.isPrivate = isPrivate
    }
}
