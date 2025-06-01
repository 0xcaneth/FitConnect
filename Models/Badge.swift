import Foundation
import FirebaseFirestore

struct Badge: Identifiable, Codable, Hashable {
    @DocumentID var id: String? // Firestore document ID, e.g., "10kStepsDaily_20231027"
    var badgeName: String
    var description: String? // Optional: "Achieved 10,000 steps on this day."
    var iconName: String? // Optional: "figure.walk.circle.fill" or a custom asset name
    var earnedAt: Timestamp
    var userId: String // To easily query all badges for a user if not using subcollections as primary query point

    // Potentially add more fields like rarity, points_awarded_for_this_badge, etc. later
}