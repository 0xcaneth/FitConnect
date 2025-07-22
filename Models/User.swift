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
        print("[FitConnectUser] Starting robust decoding...")
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.email = (try? container.decode(String.self, forKey: .email)) ?? ""
        self.fullName = (try? container.decode(String.self, forKey: .fullName)) ?? ""
        self.role = (try? container.decode(String.self, forKey: .role)) ?? "client"
        
        self.firstName = try container.decodeIfPresent(String.self, forKey: .firstName)?.nilIfEmpty
        self.lastName = try container.decodeIfPresent(String.self, forKey: .lastName)?.nilIfEmpty
        
        if let bioRaw = try? container.decodeIfPresent(String.self, forKey: .bio) {
            self.bio = bioRaw.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        } else {
            self.bio = nil
        }
        
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)?.nilIfEmpty
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)?.nilIfEmpty
        
        self.assignedDietitianId = try container.decodeIfPresent(String.self, forKey: .assignedDietitianId)?.nilIfEmpty
        self.expertId = try container.decodeIfPresent(String.self, forKey: .expertId)?.nilIfEmpty
        
        self.gender = try container.decodeIfPresent(String.self, forKey: .gender)?.nilIfEmpty
        self.fitnessGoal = try container.decodeIfPresent(String.self, forKey: .fitnessGoal)?.nilIfEmpty
        self.activityLevel = try container.decodeIfPresent(String.self, forKey: .activityLevel)?.nilIfEmpty
        
        self.createdAt = (try? container.decode(Timestamp.self, forKey: .createdAt)) ?? Timestamp(date: Date())
        self.updatedAt = try? container.decodeIfPresent(Timestamp.self, forKey: .updatedAt)
        self.lastOnline = try? container.decodeIfPresent(Timestamp.self, forKey: .lastOnline)
        self.dateOfBirth = try? container.decodeIfPresent(Timestamp.self, forKey: .dateOfBirth)
        self.lastLoginAt = try? container.decodeIfPresent(Timestamp.self, forKey: .lastLoginAt)
        
        self.age = try? container.decodeIfPresent(Int.self, forKey: .age)
        self.xp = (try? container.decodeIfPresent(Int.self, forKey: .xp)) ?? 0
        self.level = (try? container.decodeIfPresent(Int.self, forKey: .level)) ?? 1
        
        if let weightInt = try? container.decodeIfPresent(Int.self, forKey: .weight) {
            self.weight = Double(weightInt)
        } else {
            self.weight = try? container.decodeIfPresent(Double.self, forKey: .weight)
        }
        
        if let heightInt = try? container.decodeIfPresent(Int.self, forKey: .height) {
            self.height = Double(heightInt)
        } else {
            self.height = try? container.decodeIfPresent(Double.self, forKey: .height)
        }
        
        if let phoneInt = try? container.decodeIfPresent(Int.self, forKey: .phoneNumber) {
            self.phoneNumber = phoneInt
        } else if let phoneString = try? container.decodeIfPresent(String.self, forKey: .phoneNumber) {
            self.phoneNumber = Int(phoneString)
        } else {
            self.phoneNumber = nil
        }
        
        if let emailVerifiedInt = try? container.decodeIfPresent(Int.self, forKey: .isEmailVerified) {
            self.isEmailVerified = emailVerifiedInt == 1
        } else {
            self.isEmailVerified = (try? container.decodeIfPresent(Bool.self, forKey: .isEmailVerified)) ?? false
        }
        
        if let privateInt = try? container.decodeIfPresent(Int.self, forKey: .isPrivate) {
            self.isPrivate = privateInt == 1
        } else {
            self.isPrivate = (try? container.decodeIfPresent(Bool.self, forKey: .isPrivate)) ?? false
        }
        
        self.subscription = (try? container.decodeIfPresent(SubscriptionStatus.self, forKey: .subscription)) ?? .free
        
        self.providerData = try? container.decodeIfPresent([[String: String]].self, forKey: .providerData)
        
        print("[FitConnectUser] User decoded successfully: \(fullName) (\(role))")
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

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}