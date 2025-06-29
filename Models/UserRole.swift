import Foundation

enum UserRole: String, CaseIterable, Codable {
    case client = "client"
    case dietitian = "dietitian"
    
    var displayName: String {
        switch self {
        case .client:
            return "User"
        case .dietitian:
            return "Dietitian"
        }
    }
    
    var isClient: Bool {
        return self == .client
    }
    
    var isDietitian: Bool {
        return self == .dietitian
    }
}

extension UserRole {
    static var `default`: UserRole {
        return .client
    }
}