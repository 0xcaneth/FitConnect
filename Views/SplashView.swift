import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void
    
    @State private var animateBackground = false
    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var showButton = false
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Animated soft gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    FitConnectColors.accentGreen.opacity(animateBackground ? 0.25 : 0.12),
                    Color.white,
                    FitConnectColors.accentGreen.opacity(animateBackground ? 0.10 : 0.04)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.2), value: animateBackground)
            
            VStack(spacing: 0) {
                Spacer()
                // Logo
                Image(systemName: "figure.run.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [FitConnectColors.accentGreen, FitConnectColors.accentGreen.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(showLogo ? 1 : 0)
                    .scaleEffect(showLogo ? 1 : 0.7)
                    .shadow(color: FitConnectColors.accentGreen.opacity(0.18), radius: 16, x: 0, y: 8)
                    .accessibilityLabel("FitConnect Logo")
                    .animation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2), value: showLogo)
                
                // App Name
                if showTitle {
                    Text("FitConnect")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(FitConnectColors.accentGreen)
                        .padding(.top, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityAddTraits(.isHeader)
                }
                // Tagline
                if showTagline {
                    Text("Your Wellness Journey Starts Here")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                        .accessibilityLabel("Your Wellness Journey Starts Here")
                }
                Spacer()
                // Get Started Button
                if showButton {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        onContinue()
                    }) {
                        Text("Get Started")
                            .font(.title2.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(FitConnectColors.accentGreen)
                                    .shadow(color: FitConnectColors.accentGreen.opacity(0.18), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                            .scaleEffect(pulse ? 1.04 : 1.0)
                            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 48)
                    .accessibilityLabel("Get Started")
                }
            }
            .frame(maxWidth: 500)
            .padding(.top, 60)
            .padding(.bottom, 0)
            .padding(.horizontal, 0)
        }
        .preferredColorScheme(.light)
        .onAppear {
            animateBackground = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { showLogo = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { showTitle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) { showTagline = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                showButton = true
                pulse = true
            }
        }
    }
}

#Preview {
    SplashView(onContinue: {})
}

