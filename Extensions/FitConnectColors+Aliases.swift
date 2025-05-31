import SwiftUI

/// Quick aliases so legacy code continues to compile.
/// Replace / rename these once your colour palette is final.
extension FitConnectColors {
    // Legacy colour names used by older components
    static var accentColor: Color        { FitConnectColors.accentCyan }     // legacy name used in FeatureCard & QuickActionButton
    static var cardBackground: Color     { Color(.secondarySystemBackground) } // Assuming FitConnectColors.accentCyan is defined in FitConnectStyles.swift
}
