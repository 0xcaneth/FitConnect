import SwiftUI

/// Primary filled button used across the app.
/// Feel free to add loading state, icons, disabled styling, etc.
struct UnifiedPrimaryButton: View {
    let title: String
    let action: () -> Void
    
    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(FitConnectColors.accentCyan)
                .cornerRadius(12)
        }
    }
}
