import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Dietitian Profile
struct DietitianProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var bio: String?
    var avatarURL: String?
    var createdAt: Timestamp
    var lastOnline: Timestamp?
    var fcmTokens: [String: Bool]? // deviceId: true
    
    init(name: String, email: String, bio: String? = nil, avatarURL: String? = nil, createdAt: Timestamp = Timestamp(date: Date())) {
        self.name = name
        self.email = email
        self.bio = bio
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.fcmTokens = [:]
    }
}

// MARK: - Client Profile for Dietitian View
struct ClientProfile: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var email: String
    var avatarURL: String?
    var assignedDietitianId: String
    var createdAt: Timestamp
    var lastCheckIn: Timestamp?
    
    var subtitle: String {
        if let lastCheck = lastCheckIn?.dateValue() {
            let days = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
            return days == 0 ? "Checked in today" : "Last Check-In: \(days) days ago"
        }
        return "No recent logs"
    }
    
    init(name: String, email: String, assignedDietitianId: String, avatarURL: String? = nil, createdAt: Timestamp = Timestamp(date: Date())) {
        self.name = name
        self.email = email
        self.assignedDietitianId = assignedDietitianId
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

// MARK: - Appointment
struct Appointment: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var clientId: String
    var clientName: String?
    var startTime: Timestamp
    var endTime: Timestamp
    var notes: String?
    var status: AppointmentStatus
    
    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        return lhs.id == rhs.id &&
               lhs.clientId == rhs.clientId &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               lhs.status == rhs.status
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: startTime.dateValue())
    }
    
    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime.dateValue())
    }
    
    var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: startTime.dateValue())
        let end = formatter.string(from: endTime.dateValue())
        return "\(start) - \(end)"
    }
    
    var durationString: String {
        let duration = endTime.dateValue().timeIntervalSince(startTime.dateValue())
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    func isUpcoming() -> Bool {
        return startTime.dateValue() > Date()
    }
    
    func isToday() -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(startTime.dateValue(), inSameDayAs: Date())
    }
    
    func overlaps(with other: Appointment) -> Bool {
        let thisStart = startTime.dateValue()
        let thisEnd = endTime.dateValue()
        let otherStart = other.startTime.dateValue()
        let otherEnd = other.endTime.dateValue()
        
        return thisStart < otherEnd && thisEnd > otherStart
    }
    
    init(clientId: String, startTime: Date, endTime: Date, notes: String? = nil, status: AppointmentStatus = .pending) {
        self.clientId = clientId
        self.startTime = Timestamp(date: startTime)
        self.endTime = Timestamp(date: endTime)
        self.notes = notes
        self.status = status
    }
    
    init(startTime: Timestamp, endTime: Timestamp, clientId: String, clientName: String?, notes: String? = nil, status: AppointmentStatus = .pending) {
        self.startTime = startTime
        self.endTime = endTime
        self.clientId = clientId
        self.clientName = clientName
        self.notes = notes
        self.status = status
    }
}

enum AppointmentStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case scheduled = "scheduled"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no_show"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .scheduled: return "Scheduled"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return Color.orange
        case .confirmed: return Color.green
        case .scheduled: return Color(hex: "#6E56E9") ?? Color.blue
        case .completed: return Color.purple
        case .cancelled: return Color.red
        case .noShow: return Color.gray
        }
    }
}

// MARK: - Dietitian Activity
struct DietitianActivity: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String?
    var timestamp: Timestamp
    var type: ActivityType
    var clientId: String?
    var clientName: String?
    
    var iconName: String {
        switch type {
        case .messageSent: return "bubble.left.fill"
        case .feedbackGiven: return "checkmark.circle.fill"
        case .appointmentScheduled: return "calendar.badge.plus"
        case .appointmentCompleted: return "checkmark.seal.fill"
        case .clientAssigned: return "person.badge.plus"
        }
    }
    
    var color: Color {
        switch type {
        case .messageSent: return .blue
        case .feedbackGiven: return .green
        case .appointmentScheduled: return .orange
        case .appointmentCompleted: return .purple
        case .clientAssigned: return .cyan
        }
    }
    
    init(title: String, description: String? = nil, type: ActivityType, clientId: String? = nil, clientName: String? = nil, timestamp: Timestamp = Timestamp(date: Date())) {
        self.title = title
        self.description = description
        self.type = type
        self.clientId = clientId
        self.clientName = clientName
        self.timestamp = timestamp
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case messageSent = "message_sent"
    case feedbackGiven = "feedback_given"
    case appointmentScheduled = "appointment_scheduled"
    case appointmentCompleted = "appointment_completed"
    case clientAssigned = "client_assigned"
}

// MARK: - Utility Extensions
extension Color {
    static var fitConnectPurple: Color { Color(hex: "#7C4DFF") ?? .purple }
    static var fitConnectBlue: Color { Color(hex: "#0099FF") ?? .blue }
    static var fitConnectGreen: Color { Color(hex: "#00C851") ?? .green }
    static var fitConnectOrange: Color { Color(hex: "#FF4500") ?? .orange }
}

// MARK: - Helper Functions
func formatTimestamp(_ timestamp: Timestamp) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.amSymbol = "AM"
    formatter.pmSymbol = "PM"
    return formatter.string(from: timestamp.dateValue())
}
