// FitConnectColors.swift
import SwiftUI

// This file will serve as the single source of truth for FitConnect app colors.
// It's designed to be used alongside an Asset Catalog for named colors
// or can define colors directly.

struct FitConnectColors {
    // MARK: - Primary Palette (from Asset Catalog or direct definition)
    // Examples using named colors from Asset Catalog (recommended for theming)
    static let accentCyan = Color("AccentCyan") // Ensure "AccentCyan" exists in your Assets.xcassets
    static let textPrimary = Color("TextPrimary") // Ensure "TextPrimary" exists in Assets.xcassets
    static let textSecondary = Color("TextSecondary") // Ensure "TextSecondary" exists in Assets.xcassets
    
    // Example of defining colors directly if not using Asset Catalog for all:
    // static let accentCyan = Color(red: 0.0, green: 0.85, blue: 1.0) // #00D9FF
    // static let textPrimary = Color.white
    // static let textSecondary = Color.white.opacity(0.8)
    
    static let textTertiary = Color.white.opacity(0.6)
    static let textBody = Color.white.opacity(0.85)

    // MARK: - Backgrounds
    static let gradientTop = Color(red: 0.07, green: 0.16, blue: 0.36)    // #122A5C
    static let gradientBottom = Color(red: 0.05, green: 0.10, blue: 0.25) // #0D1A40
    static let glassCardBackground = Color.white.opacity(0.12)
    static let glassCardStrong = Color.white.opacity(0.18)
    static let inputBackground = Color.white.opacity(0.15)
    static let cardBackground = Color.white.opacity(0.12)
    static let glassCard = Color.white.opacity(0.12)

    // MARK: - Interactive Elements
    static let buttonPrimaryBackground = Color.white // Background for primary buttons
    static let buttonPrimaryText = gradientBottom    // Text color for primary buttons
    static let buttonSecondaryBackground = accentCyan // Background for secondary/accent buttons
    static let focusGlow = accentCyan.opacity(0.4)
    static let buttonPrimary = Color.white
    static let buttonPrimaryTextColor = gradientBottom

    // MARK: - Legacy Aliases (to be phased out)
    // These are kept for now to minimize immediate refactoring in existing views,
    // but direct usage of the above constants is preferred.
    static var accentColor: Color { accentCyan }
}

// It's also good practice to ensure you have corresponding Color Sets
// in your Assets.xcassets for "AccentCyan", "TextPrimary", and "TextSecondary"
// if you use the Color("NamedColor") initializer.
// For example, "AccentCyan" in Assets could be #00D9FF.
// "TextPrimary" could be #FFFFFF.
// "TextSecondary" could be #FFFFFF with 80% opacity.
