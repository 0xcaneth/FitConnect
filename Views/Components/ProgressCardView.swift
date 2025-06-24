import SwiftUI

struct ProgressCardView: View {
    let iconName: String
    let value: Int
    let goal: Int
    let unit: String
    let accentColor: Color
    let isCenter: Bool
    
    @State private var animatedValue: Int = 0
    @State private var progress: CGFloat = 0
    @State private var ringProgress: CGFloat = 0
    @State private var scale: CGFloat = 0.95
    @State private var shadowRadius: CGFloat = 8
    @State private var glowOpacity: Double = 0.3
    @Namespace private var cardNamespace
    
    private var progressFraction: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(goal), 1.0)
    }
    
    private var progressPercentage: Int {
        Int(progressFraction * 100)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon with animated progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                // Animated progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor,
                                accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 100, height: 100)
                    .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 2)
                
                // Icon background with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.9),
                                accentColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .shadow(color: accentColor.opacity(glowOpacity), radius: 8, x: 0, y: 4)
                
                // Icon
                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Value and unit with animated counter
            VStack(spacing: 6) {
                Text("\(animatedValue)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            // Goal text
            Text("Goal: \(formatNumber(goal)) \(unit)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // Progress bar with animation
            VStack(spacing: 6) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor,
                                    accentColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progress * 220, height: 8)
                        .shadow(color: accentColor.opacity(0.6), radius: 2, x: 0, y: 1)
                }
                .frame(width: 220)
                
                // Percentage text
                Text("\(progressPercentage)% complete")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(28)
        .frame(width: 300, height: 340)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.6),
                                    accentColor.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .shadow(color: accentColor.opacity(glowOpacity), radius: 10, x: 0, y: 5)
                )
        )
        .scaleEffect(isCenter ? 1.0 : scale)
        .shadow(
            color: accentColor.opacity(isCenter ? 0.4 : 0.2),
            radius: isCenter ? shadowRadius : 6,
            x: 0,
            y: isCenter ? 8 : 4
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(animatedValue) \(unit), \(progressPercentage)% of \(goal) goal achieved"))
        .onAppear {
            startAnimations()
            startGlowAnimation()
        }
        .onChange(of: value) { _ in
            startAnimations()
        }
        .onChange(of: isCenter) { newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = newValue ? 1.0 : 0.95
                shadowRadius = newValue ? 12 : 8
            }
            
            // Haptic feedback when card becomes center
            if newValue {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
    }
    
    private func startAnimations() {
        // Reset animations
        progress = 0
        ringProgress = 0
        animatedValue = 0
        
        // Animate progress bar
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            progress = progressFraction
        }
        
        // Animate progress ring
        withAnimation(.easeOut(duration: 1.5).delay(0.1)) {
            ringProgress = progressFraction
        }
        
        // Animate counter
        animateCounter()
    }
    
    private func animateCounter() {
        let duration = 1.5
        let steps = 60
        let increment = max(1, value / steps)
        let stepDuration = duration / Double(steps)
        
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            if animatedValue < value {
                animatedValue = min(animatedValue + increment, value)
            } else {
                timer.invalidate()
                animatedValue = value
            }
        }
    }
    
    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.7
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}
