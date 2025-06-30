import Foundation
import FirebaseFirestore // Ensure Firestore is imported for @DocumentID and Timestamp

struct FitConnectUser: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var firstName: String?
    var lastName: String?
    var createdAt: Timestamp
    var updatedAt: Timestamp?
    var lastOnline: Timestamp?
    var photoURL: String?
    var profileImageUrl: String? 
    var age: Int?
    var weight: Double?
    var height: Double?
    var dateOfBirth: Timestamp? 
    var phoneNumber: Int? 
    var gender: String? 
    var fitnessGoal: String?
    var activityLevel: String?
    var subscription: SubscriptionStatus?
    var xp: Int? 
    var level: Int?
    var isEmailVerified: Bool? 
    var role: String 
    var assignedDietitianId: String?
    var expertId: String?
    var providerData: [[String: String]]? 
    var lastLoginAt: Timestamp?
    var bio: String?
    var isPrivate: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case firstName
        case lastName
        case createdAt
        case updatedAt
        case lastOnline
        case photoURL
        case profileImageUrl
        case age
        case weight
        case height
        case dateOfBirth
        case phoneNumber
        case gender
        case fitnessGoal
        case activityLevel
        case subscription
        case xp
        case level
        case isEmailVerified
        case role
        case assignedDietitianId
        case expertId
        case providerData
        case lastLoginAt
        case bio
        case isPrivate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Initialize all required properties first
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        
        do {
            createdAt = try container.decode(Timestamp.self, forKey: .createdAt)
        } catch {
            print("[FitConnectUser] CreatedAt decode error: \(error)")
            throw error
        }
        
        updatedAt = try container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        lastOnline = try container.decodeIfPresent(Timestamp.self, forKey: .lastOnline)
        
        // Handle photoURL/profileImageUrl inconsistency
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
        
        age = try container.decodeIfPresent(Int.self, forKey: .age)
        
        // Handle weight as either Int or Double
        if let weightInt = try? container.decodeIfPresent(Int.self, forKey: .weight) {
            weight = Double(weightInt)
        } else {
            weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        }
        
        // Handle height as either Int or Double  
        if let heightInt = try? container.decodeIfPresent(Int.self, forKey: .height) {
            height = Double(heightInt)
        } else {
            height = try container.decodeIfPresent(Double.self, forKey: .height)
        }
        
        dateOfBirth = try container.decodeIfPresent(Timestamp.self, forKey: .dateOfBirth)
        
        // Handle phoneNumber as either Int or String
        if let phoneInt = try? container.decodeIfPresent(Int.self, forKey: .phoneNumber) {
            phoneNumber = phoneInt
        } else if let phoneString = try? container.decodeIfPresent(String.self, forKey: .phoneNumber) {
            phoneNumber = Int(phoneString)
        } else {
            phoneNumber = nil
        }
        
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        fitnessGoal = try container.decodeIfPresent(String.self, forKey: .fitnessGoal)
        activityLevel = try container.decodeIfPresent(String.self, forKey: .activityLevel)
        subscription = try container.decodeIfPresent(SubscriptionStatus.self, forKey: .subscription)
        xp = try container.decodeIfPresent(Int.self, forKey: .xp)
        level = try container.decodeIfPresent(Int.self, forKey: .level)
        
        // Handle isEmailVerified as Int (0/1) from Firestore
        if let emailVerifiedInt = try? container.decodeIfPresent(Int.self, forKey: .isEmailVerified) {
            isEmailVerified = emailVerifiedInt == 1
        } else {
            isEmailVerified = try container.decodeIfPresent(Bool.self, forKey: .isEmailVerified)
        }
        
        role = try container.decode(String.self, forKey: .role)
        assignedDietitianId = try container.decodeIfPresent(String.self, forKey: .assignedDietitianId)
        expertId = try container.decodeIfPresent(String.self, forKey: .expertId)
        providerData = try container.decodeIfPresent([[String: String]].self, forKey: .providerData)
        lastLoginAt = try container.decodeIfPresent(Timestamp.self, forKey: .lastLoginAt)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate)
        
        // MOVE: All print statements after initialization
        print("[FitConnectUser] Decoding user from Firestore...")
        print("[FitConnectUser] ID: \(id ?? "nil")")
        print("[FitConnectUser] Email: \(email)")
        print("[FitConnectUser] Full name: \(fullName)")
        print("[FitConnectUser] CreatedAt decoded successfully")
        print("[FitConnectUser] Weight: \(weight ?? 0)")
        print("[FitConnectUser] Height: \(height ?? 0)")
        print("[FitConnectUser] Phone: \(phoneNumber ?? 0)")
        print("[FitConnectUser] EmailVerified: \(isEmailVerified ?? false)")
        print("[FitConnectUser] Role: \(role)")
        print("[FitConnectUser] User decoded successfully!")
    }

    enum SubscriptionStatus: String, Codable {
        case free = "free"
        case premium = "premium"
        case pro = "pro"
    }

    init(id: String? = nil, 
         email: String, 
         fullName: String, 
         firstName: String? = nil,
         lastName: String? = nil,
         photoURL: String? = nil,
         profileImageUrl: String? = nil,
         xp: Int? = 0, 
         level: Int? = 1,
         isEmailVerified: Bool? = false, 
         createdAt: Timestamp = Timestamp(date: Date()),
         updatedAt: Timestamp? = nil,
         lastOnline: Timestamp? = nil,
         dateOfBirth: Timestamp? = nil,
         phoneNumber: Int? = nil,
         gender: String? = nil,
         subscription: SubscriptionStatus = .free,
         role: String = "client",
         assignedDietitianId: String? = nil,
         expertId: String? = nil,
         providerData: [[String: String]]? = nil,
         lastLoginAt: Timestamp? = nil,
         bio: String? = "",
         isPrivate: Bool? = false) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.firstName = firstName
        self.lastName = lastName
        self.photoURL = photoURL
        self.profileImageUrl = profileImageUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOnline = lastOnline
        self.dateOfBirth = dateOfBirth
        self.phoneNumber = phoneNumber
        self.gender = gender
        self.subscription = subscription
        self.xp = xp
        self.level = level
        self.isEmailVerified = isEmailVerified
        self.role = role
        self.assignedDietitianId = assignedDietitianId
        self.expertId = expertId
        self.providerData = providerData
        self.lastLoginAt = lastLoginAt
        self.bio = bio
        self.isPrivate = isPrivate
    }
}