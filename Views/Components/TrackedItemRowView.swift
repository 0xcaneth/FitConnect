import SwiftUI

struct TrackedItemRowView: View {
    let item: TrackingItem
    let isChecked: Bool
    let animationDelay: Double
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with glow effect
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(item.color)
                    .shadow(color: item.color.opacity(0.5), radius: 4, x: 0, y: 0)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(item.description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Checkmark
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 24, height: 24)
                    .scaleEffect(isChecked ? 1.0 : 0.0)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(isChecked ? 1.0 : 0.0)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isChecked)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(materialBackground())
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Helper function for material background
    private func materialBackground() -> Color {
        if #available(iOS 15.0, *) {
            return Color.white.opacity(0.1) 
        } else {
            return Color.white.opacity(0.1)
        }
    }
}
