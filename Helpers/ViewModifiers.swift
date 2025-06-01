import SwiftUI

// MARK: - View Extensions for iOS 15.6+
extension View {
    /// Apply background that ignores safe area
    func backgroundSafeArea() -> some View {
        self.ignoresSafeArea()
    }
    
    /// Apply navigation title (iOS 15.6+ compatible)
    func navigationTitleCompat(_ title: String) -> some View {
        self.navigationTitle(title)
    }
}
