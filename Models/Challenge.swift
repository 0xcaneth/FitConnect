import Foundation
import SwiftUI
import FirebaseFirestore

struct Challenge: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var unit: ChallengeUnit
    var targetValue: Double
    var durationDays: Int
    var isActive: Bool = true
    var createdAt: Timestamp? = Timestamp(date: Date())
    var category: ChallengeCategory = .fitness
    var difficulty: ChallengeDifficulty = .medium
    var xpReward: Int = 100
    var participantCount: Int = 0
    var iconName: String = "target"
    var colorHex: String = "#6E56E9"
    var requirements: [String] = []
    var tips: [String] = []
    var lastUpdated: Timestamp? = Timestamp(date: Date())

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case unit
        case targetValue
        case durationDays
        case isActive
        case createdAt
        case category
        case difficulty
        case xpReward
        case participantCount
        case iconName
        case colorHex
        case requirements
        case tips
        case lastUpdated
    }
}

enum ChallengeUnit: String, Codable, CaseIterable, Hashable {
    case steps = "steps"
    case water = "water"
    case count = "count"
    case calories = "calories"
    case minutes = "minutes"
    case kilometers = "kilometers"

    var displayName: String {
        switch self {
        case .steps:
            return "Steps"
        case .water:
            return "Liters"
        case .count:
            return "Count"
        case .calories:
            return "Calories"
        case .minutes:
            return "Minutes"
        case .kilometers:
            return "Kilometers"
        }
    }
    
    var shortName: String {
        switch self {
        case .steps:
            return "steps"
        case .water:
            return "L"
        case .count:
            return "x"
        case .calories:
            return "kcal"
        case .minutes:
            return "min"
        case .kilometers:
            return "km"
        }
    }
}

enum ChallengeCategory: String, Codable, CaseIterable, Hashable {
    case fitness = "fitness"
    case nutrition = "nutrition"
    case wellness = "wellness"
    case social = "social"
    case all = "all"
    
    var title: String {
        switch self {
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .wellness: return "Wellness"
        case .social: return "Social"
        case .all: return "All"
        }
    }
    
    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .nutrition: return "leaf"
        case .wellness: return "heart"
        case .social: return "person.2"
        case .all: return "grid"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .fitness:
            return [
                Color(red: 1.0, green: 0.42, blue: 0.42),
                Color(red: 1.0, green: 0.55, blue: 0.33)
            ]
        case .nutrition:
            return [
                Color(red: 0.31, green: 0.78, blue: 0.47),
                Color(red: 0.27, green: 0.64, blue: 0.71)
            ]
        case .wellness:
            return [
                Color(red: 0.94, green: 0.58, blue: 0.98),
                Color(red: 0.96, green: 0.34, blue: 0.42)
            ]
        case .social:
            return [
                Color(red: 0.49, green: 0.34, blue: 1.0),
                Color(red: 0.31, green: 0.25, blue: 0.84)
            ]
        case .all:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 1.0, green: 0.65, blue: 0.0)
            ]
        }
    }
}

enum ChallengeDifficulty: String, Codable, CaseIterable, Hashable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return Color(red: 0.31, green: 0.78, blue: 0.47)
        case .medium: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .hard: return Color(red: 1.0, green: 0.42, blue: 0.42)
        case .expert: return Color(red: 0.94, green: 0.58, blue: 0.98)
        }
    }
    
    var xpMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 3.0
        }
    }
}