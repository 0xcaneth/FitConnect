import SwiftUI

/// Clean, compact progress card with circular progress around icon
struct ModernProgressCard: View {
    let metric: ProgressMetric
    let isCenter: Bool
    @State private var animateProgress = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Circular progress with icon in center
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 90, height: 90)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: animateProgress ? metric.progress : 0)
                    .stroke(
                        LinearGradient(
                            colors: [metric.color, metric.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.2).delay(0.3), value: animateProgress)
                
                // Icon in center
                Image(systemName: metric.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(metric.color)
                    .scaleEffect(animateProgress ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateProgress)
            }
            
            // Value and unit
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(metric.current)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                    
                    Text(metric.unit)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .offset(y: -2)
                }
                
                if let subtitle = metric.subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Progress percentage
            Text("\(metric.progressPercentage)%")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(metric.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(metric.color.opacity(0.15))
                )
            
            // Goal text
            Text("Goal: \(metric.goal)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220) // Smaller, more compact frame
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#1A1C23"),
                            Color(hex: "#242730")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [metric.color.opacity(0.4), metric.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .scaleEffect(isCenter ? 1.0 : 0.9)
        .opacity(isCenter ? 1.0 : 0.7)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCenter)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

#if DEBUG
struct ModernProgressCard_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 16) {
            ModernProgressCard(
                metric: ProgressMetric(
                    current: 7542,
                    goal: 10000,
                    unit: "steps",
                    icon: "figure.walk",
                    color: Color(hex: "#3CD76B")
                ),
                isCenter: true
            )
            
            ModernProgressCard(
                metric: ProgressMetric(
                    current: 1200,
                    goal: 2000,
                    unit: "kcal",
                    icon: "fork.knife",
                    color: Color(hex: "#FF8E3C")
                ),
                isCenter: false
            )
        }
        .padding()
        .background(Color(hex: "#0D0F14"))
        .preferredColorScheme(.dark)
    }
}
#endif