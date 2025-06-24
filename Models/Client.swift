import Foundation

struct DietitianClient: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let photoURL: String?
    let email: String
    let lastOnline: Date
    let connectedAt: Date?
    
    init(id: String, name: String, photoURL: String? = nil, email: String, lastOnline: Date, connectedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.email = email
        self.lastOnline = lastOnline
        self.connectedAt = connectedAt
    }
    
    // MARK: - Equatable
    static func == (lhs: DietitianClient, rhs: DietitianClient) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.photoURL == rhs.photoURL &&
               lhs.email == rhs.email &&
               lhs.lastOnline == rhs.lastOnline &&
               lhs.connectedAt == rhs.connectedAt
    }
}

// MARK: - Date Extensions for Time Ago
extension Date {
    func minutesAgo() -> Int {
        Int(Date().timeIntervalSince(self) / 60)
    }
    
    func timeAgoString() -> String {
        let minutes = minutesAgo()
        
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else if minutes < 1440 { // Less than 24 hours
            let hours = minutes / 60
            return "\(hours)h ago"
        } else {
            let days = minutes / 1440
            return "\(days)d ago"
        }
    }
    
    var isOnline: Bool {
        // Consider user online if last seen within 5 minutes
        minutesAgo() < 5
    }
}