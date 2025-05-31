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
                    .foregroundColor(FitConnectColors.accentColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FitConnectColors.cardBackground)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
