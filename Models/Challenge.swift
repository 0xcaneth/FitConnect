import Foundation
import FirebaseFirestore


struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var unit: ChallengeUnit
    var targetValue: Double
    var durationDays: Int
    var isActive: Bool = true // Opsiyonel: Challenge'ın aktif olup olmadığını belirtmek için eklenebilir
    var createdAt: Timestamp? = Timestamp(date: Date()) // Opsiyonel: Oluşturulma tarihi

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case unit
        case targetValue
        case durationDays
        case isActive
        case createdAt
    }
}

enum ChallengeUnit: String, Codable, CaseIterable, Hashable {
    case steps = "steps"
    case water = "water" // Litre cinsinden
    case count = "count" // Genel bir sayaç (örn: tamamlanan antrenman sayısı)
    // İleride eklenebilir:
    // case activeEnergy = "kcal"
    // case workoutMinutes = "minutes"

    var displayName: String {
        switch self {
        case .steps:
            return "Steps"
        case .water:
            return "Liters of Water"
        case .count:
            return "Count"
        }
    }
}
