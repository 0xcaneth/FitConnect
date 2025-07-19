//
//  Extensions.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import Foundation
import SwiftUI // Ensure SwiftUI is imported if other extensions need it

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}