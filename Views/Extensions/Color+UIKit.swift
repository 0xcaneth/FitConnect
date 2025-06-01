//  Color+UIKit.swift
//  FitConnect
//
//  Converts SwiftUI Color to UIColor, primarily for iOS 13 compatibility.

import SwiftUI
import UIKit

extension Color {
    /// Returns a UIKit UIColor for this SwiftUI Color (iOS 15.6+ only).
    var uiColor: UIColor {
        UIColor(self)
    }
}
