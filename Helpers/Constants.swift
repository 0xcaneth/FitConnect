//
//  Constants.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import Foundation
import SwiftUI

struct Constants {
    // MARK: - API URLs
    static let baseURL = "https://api.fitconnect.com"
    static let vertexAIBaseURL = "https://us-central1-aiplatform.googleapis.com"
    
    // MARK: - Colors
    struct Colors {
        static let primaryGradientStart = Color(hex: "8F3FFF")
        static let primaryGradientEnd = Color(hex: "FF3C5C")
        static let backgroundDark = Color(hex: "0D0F14")
        static let cardBackground = Color(hex: "1A1D23")
        static let textPrimary = Color.white
        static let textSecondary = Color.gray
    }
    
    // MARK: - Dimensions
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
        static let buttonHeight: CGFloat = 50
        static let padding: CGFloat = 16
    }
    
    // MARK: - Animation
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let fastDuration: Double = 0.15
        static let slowDuration: Double = 0.5
    }
    
    // MARK: - Health Goals
    struct HealthGoals {
        static let defaultStepGoal = 10000
        static let defaultCalorieGoal = 500.0
        static let defaultWaterGoal = 2000.0
    }
}