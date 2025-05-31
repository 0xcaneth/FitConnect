import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var type: WorkoutType
    var duration: TimeInterval
    var caloriesBurned: Int
    var exercises: [Exercise]
    var createdAt: Date
    var videoURL: String?
    
    enum WorkoutType: String, Codable, CaseIterable {
        case cardio = "cardio"
        case strength = "strength"
        case yoga = "yoga"
        case hiit = "hiit"
        case pilates = "pilates"
        case dance = "dance"
        
        var displayName: String {
            switch self {
            case .cardio: return "Cardio"
            case .strength: return "Strength Training"
            case .yoga: return "Yoga"
            case .hiit: return "HIIT"
            case .pilates: return "Pilates"
            case .dance: return "Dance"
            }
        }
        
        var icon: String {
            switch self {
            case .cardio: return "heart.fill"
            case .strength: return "dumbbell.fill"
            case .yoga: return "figure.yoga"
            case .hiit: return "flame.fill"
            case .pilates: return "figure.pilates"
            case .dance: return "music.note"
            }
        }
    }
}

struct Exercise: Identifiable, Codable {
    var id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var restTime: TimeInterval?
}