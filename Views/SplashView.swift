import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void
    
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0.0
    @State private var glowEffect: Bool = false
    @State private var showPrivacyAnalytics = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark gradient background (#0B0D17→#1A1B25)
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Subtle glow effect behind logo
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.1), // #00E5FF
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(glowEffect ? 1.2 : 0.8)
                    .opacity(logoOpacity * 0.6)
                
                // Main content
                VStack(spacing: 32) {
                    // Simple, elegant icon
                    ZStack {
                        // Icon background
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                        Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(
                                color: Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.4),
                                radius: 20, x: 0, y: 0
                            )
                        
                        // Modern fitness icon
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App name and tagline
                    VStack(spacing: 12) {
                        Text("FitConnect")
                            .font(.system(size: 32, weight: .bold, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.96, green: 0.96, blue: 0.98), // #F5F5F7
                                        Color(red: 0.85, green: 0.85, blue: 0.87)  // #D9D9DE
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .opacity(logoOpacity)
                        
                        Text("Your Health, Your Way")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)) // #C0C0C0
                            .opacity(logoOpacity * 0.8)
                    }
                    
                    // Continue button with neon gradient
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        showPrivacyAnalytics = true
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold)) // SF Pro Semibold
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16) // 16pt vertical padding
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                        Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16) // 16pt corner radius
                    }
                    .padding(.horizontal, 40)
                    .opacity(logoOpacity)
                }
            }
        }
        .onAppear {
            // Subtle glow animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowEffect.toggle()
            }
            
            // Logo entrance animation
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.1
                logoOpacity = 1.0
            }
            
            // Haptic feedback and settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                }
            }
        }
        .fullScreenCover(isPresented: $showPrivacyAnalytics, onDismiss: {
            self.onContinue()
        }) {
            PrivacyAnalyticsView(
                onContinue: {
                    showPrivacyAnalytics = false 
                },
                onSkip: {
                    showPrivacyAnalytics = false 
                }
            )
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
#endif
