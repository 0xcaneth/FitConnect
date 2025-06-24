//
//  UIHelpers.swift
//  FitConnect
//
//  Created by Can Acar on 4/25/25.
//

import SwiftUI
import UIKit

// MARK: - UI Helper Functions
struct UIHelpers {
    
    // MARK: - Haptic Feedback
    static func impactFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    static func selectionFeedback() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    static func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    // MARK: - Keyboard Helpers
    static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Safe Area Helpers
    static func getSafeAreaInsets() -> UIEdgeInsets {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIEdgeInsets.zero
        }
        return window.safeAreaInsets
    }
    
    // MARK: - Screen Dimensions
    static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
}

// MARK: - SwiftUI Extensions
extension View {
    func hideKeyboard() {
        UIHelpers.hideKeyboard()
    }
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIHelpers.impactFeedback(style)
    }
}