import SwiftUI

struct PrimaryCTAButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pulseAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pulseAnimation = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.0, green: 0.8, blue: 0.8), // Turquoise
                            Color(red: 0.0, green: 0.5, blue: 1.0)  // Blue
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color.blue.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .scaleEffect(pulseAnimation ? 1.05 : (isPressed ? 0.98 : 1.0))
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }) {
            // Action handled in main button
        }
    }
}