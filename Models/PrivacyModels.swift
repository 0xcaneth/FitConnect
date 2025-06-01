import SwiftUI

// MARK: - Privacy & Analytics Models
struct TrackingItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct PrivacyItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Data Constants
let trackingItems: [TrackingItem] = [
    TrackingItem(
        title: "App Usage & Performance",
        description: "How you interact with features",
        icon: "chart.line.uptrend.xyaxis",
        color: .green
    ),
    TrackingItem(
        title: "Goal Completion Patterns",
        description: "Anonymous progress insights",
        icon: "target",
        color: .blue
    ),
    TrackingItem(
        title: "Anonymous Usage Insights",
        description: "Aggregated user behavior",
        icon: "eye.fill",
        color: .purple
    ),
    TrackingItem(
        title: "No Personal Data Collected",
        description: "Your privacy is protected",
        icon: "shield.checkered",
        color: .red
    )
]

let privacyItems: [PrivacyItem] = [
    PrivacyItem(
        title: "App Usage & Performance",
        description: "How you interact with features",
        icon: "chart.line.uptrend.xyaxis",
        color: Color(red: 0.0, green: 0.90, blue: 1.0) // #00E5FF
    ),
    PrivacyItem(
        title: "Goal Completion Patterns",
        description: "Anonymous progress insights",
        icon: "target",
        color: Color(red: 0.0, green: 0.90, blue: 1.0) // #00E5FF
    ),
    PrivacyItem(
        title: "Anonymous Usage Insights",
        description: "Aggregated user behavior",
        icon: "eye.fill",
        color: Color(red: 0.0, green: 0.90, blue: 1.0) // #00E5FF
    ),
    PrivacyItem(
        title: "No Personal Data Collected",
        description: "Your privacy is protected",
        icon: "shield.checkered",
        color: Color(red: 0.0, green: 0.90, blue: 1.0) // #00E5FF
    )
]