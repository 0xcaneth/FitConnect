import SwiftUI

struct QuickActionData {
    let title: String
    let iconName: String
    let colors: [Color]
    let action: () -> Void
}

struct QuickActionTile: View {
    let data: QuickActionData
    
    var body: some View {
        Button(action: data.action) {
            VStack(spacing: 8) {
                // Circular icon
                Circle()
                    .fill(LinearGradient(
                        colors: data.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: data.iconName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                
                // Label
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 165, height: 120)
            .background(Color(hex: "#1F1F1F"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: data.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: data.colors[0].opacity(0.25), radius: 15, x: 0, y: 0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}