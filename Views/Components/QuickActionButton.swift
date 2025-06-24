import SwiftUI

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(FitConnectColors.accentCyan) // Using direct accentCyan
                
                Text(title)
                    .font(FitConnectFonts.small) // Using small font for consistency
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                // Using GlassCard style directly for consistency
                ZStack {
                     RoundedRectangle(cornerRadius: 12)
                         .fill(FitConnectColors.glassCard) // From FitConnectStyles
                     RoundedRectangle(cornerRadius: 12)
                         .fill(.thinMaterial.opacity(0.8))
                 }
                .compositingGroup()
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4) // Subtle shadow
            )
        }
        .buttonStyle(PlainButtonStyle()) // To remove default button styling
    }
}

struct QuickActionButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            EnhancedGradientBackground()
            HStack {
                QuickActionButton(icon: "plus", title: "Add Workout") {}
                QuickActionButton(icon: "camera", title: "Meal Photo") {}
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
