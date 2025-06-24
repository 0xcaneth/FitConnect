import SwiftUI

/// Primary filled button used across the app.
/// This is now an alias for EnhancedPrimaryButton with only title.
struct UnifiedPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true // Added for consistency with EnhancedPrimaryButton
    
    init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        // Uses EnhancedPrimaryButton from FitConnectStyles
        EnhancedPrimaryButton(title: title, icon: nil, isEnabled: isEnabled, action: action)
    }
}

struct UnifiedPrimaryButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            EnhancedGradientBackground()
            VStack {
                UnifiedPrimaryButton("Accept & Continue") {}
                UnifiedPrimaryButton("Disabled", isEnabled: false) {}
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
