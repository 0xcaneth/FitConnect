//  Color+UIKit.swift
//  FitConnect
//
//  Converts SwiftUI Color to UIColor, primarily for iOS 13 compatibility.

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Returns a `UIColor` representation of this SwiftUI `Color`.
    /// On iOS 14 and later, it uses the native `UIColor(Color)` initializer.
    /// On iOS 13, it attempts to derive components; this might not be perfect for all `Color` types
    /// (like system adaptive colors or complex gradients defined as `Color`).
    /// For predefined `FitConnectColors`, this should work well.
    var uiColor: UIColor {
        #if canImport(UIKit)
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
            // Fallback for iOS 13:
            // This approach attempts to extract RGBA components.
            // It works best with Colors initialized from CGColor or component-wise.
            // For system colors or complex color types, it might default to a placeholder.
            let components = self.cgColor?.components
            let red = components?[0] ?? 0
            let green = components?[1] ?? 0
            let blue = components?[2] ?? 0
            let alpha = components?[3] ?? 1 // Alpha might be in a different position depending on color space
            
            // A more robust way for iOS 13 if direct component extraction is unreliable for some Color types
            // would be to manually map your FitConnectColors to UIColors.
            // However, this generic approach attempts to cover more cases.
            // If self.cgColor is nil (e.g. for some system colors not backed by CGColor directly on iOS 13),
            // it will default to black.
            if let cgColor = self.cgColor {
                 return UIColor(cgColor: cgColor)
            } else {
                // Fallback if CGColor is not available (e.g. for some system colors on iOS 13)
                // You might want a specific default color here.
                return UIColor(red: red, green: green, blue: blue, alpha: alpha) // Default to extracted or black
            }
        }
        #else
        // Fallback for platforms where UIKit is not available.
        return UIColor() // Or your platform-specific default.
        #endif
    }
}
