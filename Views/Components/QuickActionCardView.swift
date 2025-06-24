import SwiftUI

struct QuickActionCardView: View {
    let title: String
    let iconName: String
    let gradientColors: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var glowOpacity: Double = 0.4
    @State private var scale: CGFloat = 1.0
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Scale animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.05
                glowOpacity = 0.8
            }
            
            // Return to normal and execute action
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    scale = 1.0
                    glowOpacity = 0.4
                }
                action()
            }
        }) {
            VStack(spacing: 16) {
                // Icon with circular gradient background and enhanced glow
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 60, height: 60)
                        .shadow(color: gradientColors.first?.opacity(glowOpacity) ?? Color.clear, radius: 12, x: 0, y: 6)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Title text with better typography
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.9)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: gradientColors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .opacity(glowOpacity)
                            .shadow(color: gradientColors.first?.opacity(glowOpacity * 0.8) ?? Color.clear, radius: 8, x: 0, y: 4)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isPressed ? 0.1 : 0))
            )
            .scaleEffect(scale)
            .overlay(
                // Tooltip
                Group {
                    if showTooltip {
                        VStack {
                            Text(getTooltipText())
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.black.opacity(0.8))
                                )
                            Spacer()
                        }
                        .offset(y: -10)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .onLongPressGesture(minimumDuration: 0.5) {
            // Show tooltip on long press
            withAnimation(.easeInOut(duration: 0.3)) {
                showTooltip = true
            }
            
            // Pulse effect
            withAnimation(.easeInOut(duration: 0.6)) {
                glowOpacity = 1.0
            }
            
            // Hide tooltip after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTooltip = false
                    glowOpacity = 0.4
                }
            }
        }
        .accessibilityLabel(Text("\(title), double-tap to \(title.lowercased())"))
        .onAppear {
            startGlowAnimation()
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.7
        }
    }
    
    private func getTooltipText() -> String {
        switch title {
        case "Scan Meal":
            return "Quick Scan"
        case "Log Meal":
            return "Manual Entry"
        case "Stats":
            return "View Analytics"
        case "Chat w/ Dietitian":
            return "Get Support"
        default:
            return title
        }
    }
}

// MARK: - Quick Actions Grid Container
struct QuickActionsGrid: View {
    let scanMealAction: () -> Void
    let logMealAction: () -> Void
    let statsAction: () -> Void
    let chatAction: () -> Void
    
    @Environment(\.horizontalSizeClass) var hSizeClass
    
    var gridColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            QuickActionCardView(
                title: "Scan Meal",
                iconName: "camera.fill",
                gradientColors: [Color.orange, Color.red],
                action: scanMealAction
            )
            
            QuickActionCardView(
                title: "Log Meal",
                iconName: "plus.circle.fill",
                gradientColors: [Color.green, Color.teal],
                action: logMealAction
            )
            
            QuickActionCardView(
                title: "Stats",
                iconName: "chart.bar.fill",
                gradientColors: [Color.blue, Color.cyan],
                action: statsAction
            )
            
            QuickActionCardView(
                title: "Chat w/ Dietitian",
                iconName: "bubble.left.and.bubble.right.fill",
                gradientColors: [Color.purple, Color.indigo],
                action: chatAction
            )
        }
    }
}
