// FitConnectColors.swift
import SwiftUI

struct FitConnectColors {
    // MARK: - Primary Colors
    static let accentCyan = Color(hex: "#00D9FF")
    static let accentPurple = Color(hex: "#8F3FFF")
    static let accentBlue = Color(hex: "#3C9CFF")
    static let accentGreen = Color(hex: "#3CD76B")
    static let accentOrange = Color(hex: "#FF8E3C")
    static let accentPink = Color(hex: "#FF5C9C")
    
    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.6)
    static let textBody = Color.white.opacity(0.85)
    
    // MARK: - Background Colors
    static let backgroundDark = Color(hex: "#0D0F14")
    static let backgroundSecondary = Color(hex: "#1A1B25")
    static let gradientTop = Color(hex: "#122A5C")
    static let gradientBottom = Color(hex: "#0D1A40")
    static let fieldBackground = Color.white.opacity(0.15)
    static let cardBackground = Color.white.opacity(0.12)
    static let glassCard = Color.white.opacity(0.12)
    static let glassCardBackground = Color.white.opacity(0.12)
    static let glassCardStrong = Color.white.opacity(0.18)
    static let inputBackground = Color.white.opacity(0.15)
    
    // MARK: - Interactive Elements
    static let buttonPrimary = Color.white
    static let buttonPrimaryText = gradientBottom
    static let buttonPrimaryBackground = Color.white
    static let buttonPrimaryTextColor = gradientBottom
    static let buttonSecondaryBackground = accentCyan
    static let focusGlow = accentCyan.opacity(0.4)
    
    // MARK: - Chat Colors
    static let clientBubble = LinearGradient(
        colors: [accentBlue, accentBlue.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let dietitianBubble = LinearGradient(
        colors: [accentPurple, accentPurple.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let otherUserBubble = LinearGradient(
        colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Legacy Aliases
    static var accentColor: Color { accentCyan }
}

// MARK: - Color Extensions (using different names to avoid conflicts)
extension Color {
    static let fitConnectBackgroundDark = FitConnectColors.backgroundDark
    static let fitConnectBackgroundSecondary = FitConnectColors.backgroundSecondary
    static let fitConnectFieldBackground = FitConnectColors.fieldBackground
    static let fitConnectCardBackground = FitConnectColors.cardBackground
    static let fitConnectTextPrimary = FitConnectColors.textPrimary
    static let fitConnectTextSecondary = FitConnectColors.textSecondary
    static let fitConnectTextTertiary = FitConnectColors.textTertiary
    static let fitConnectAccentPurple = FitConnectColors.accentPurple
    static let fitConnectAccentBlue = FitConnectColors.accentBlue
    static let fitConnectAccentGreen = FitConnectColors.accentGreen
    static let fitConnectAccentOrange = FitConnectColors.accentOrange
    static let fitConnectAccentCyan = FitConnectColors.accentCyan
}
