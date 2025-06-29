import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void
    
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.0
    @State private var logoRotation: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textLetterSpacing: CGFloat = -2.0
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 50
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonBreathing: CGFloat = 1.0
    @State private var isAnimating = false
    
    // Particle animation states
    @State private var particleOffset1: CGFloat = 0
    @State private var particleOffset2: CGFloat = 0
    @State private var particleOffset3: CGFloat = 0
    @State private var particleOpacity: Double = 0.0
    
    // Background animation
    @State private var gradientOffset: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // PREMIUM DYNAMIC BACKGROUND
                ZStack {
                    // Base deep space gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.02, green: 0.02, blue: 0.08),
                            Color(red: 0.05, green: 0.03, blue: 0.12),
                            Color(red: 0.08, green: 0.05, blue: 0.16)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Animated overlay gradient for depth
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.1),
                            Color.clear,
                            Color.blue.opacity(0.08)
                        ]),
                        startPoint: UnitPoint(x: 0.2 + gradientOffset, y: 0.2),
                        endPoint: UnitPoint(x: 0.8 + gradientOffset, y: 0.8)
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: gradientOffset)
                    
                    // Constellation particles
                    ForEach(0..<12, id: \.self) { index in
                        ConstellationParticle(
                            index: index,
                            screenSize: geometry.size,
                            opacity: particleOpacity
                        )
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 120)
                    
                    // PREMIUM LOGO WITH DEPTH LAYERS
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.3),
                                        Color.blue.opacity(0.2),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 180, height: 180)
                            .blur(radius: 8)
                        
                        // Medium glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.4),
                                        Color.blue.opacity(0.2),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 15)
                        
                        // Inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.purple.opacity(0.6),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .blur(radius: 12)
                        
                        // Main icon background with embossed effect
                        ZStack {
                            // Shadow layer (embossed depth)
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.black.opacity(0.4))
                                .frame(width: 120, height: 120)
                                .offset(x: 2, y: 2)
                                .blur(radius: 4)
                            
                            // Highlight layer (embossed depth)
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .offset(x: -1, y: -1)
                                .blur(radius: 1)
                            
                            // Main gradient background
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.6, green: 0.4, blue: 1.0),
                                            Color(red: 0.5, green: 0.2, blue: 0.9),
                                            Color(red: 0.4, green: 0.1, blue: 0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            // Subtle inner border
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear,
                                            Color.black.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 120, height: 120)
                        }
                        .shadow(color: Color.purple.opacity(0.5), radius: 25, x: 0, y: 5)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 2)
                        
                        // Running person icon with subtle animation
                        Image(systemName: "figure.run")
                            .font(.system(size: 58, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white,
                                        Color.white.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            .rotationEffect(.degrees(logoRotation))
                    }
                    .scaleEffect(logoScale * buttonBreathing)
                    .opacity(logoOpacity)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: buttonBreathing)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // PREMIUM ANIMATED TEXT
                    VStack(spacing: 12) {
                        // Title with letter-by-letter animation
                        HStack(spacing: textLetterSpacing) {
                            ForEach(Array("FitConnect".enumerated()), id: \.offset) { index, letter in
                                Text(String(letter))
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white,
                                                Color.white.opacity(0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .opacity(textOpacity)
                                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.08), value: textOpacity)
                            }
                        }
                        
                        // Subtitle with breathing glow effect
                        Text("Your Health, Your Way")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(1.2)
                            .opacity(textOpacity)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 0)
                    }
                    
                    Spacer()
                    
                    // PREMIUM INTERACTIVE BUTTON
                    Button(action: {
                        guard !isAnimating else { return }
                        isAnimating = true
                        
                        // Premium haptic sequence
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred()
                        
                        // Button press animation with ripple effect
                        withAnimation(.easeInOut(duration: 0.1)) {
                            buttonScale = 0.95
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
                                buttonScale = 1.05
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                buttonScale = 1.0
                            }
                        }
                        
                        // Secondary haptic after spring
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            let lightFeedback = UIImpactFeedbackGenerator(style: .light)
                            lightFeedback.impactOccurred()
                        }
                        
                        // Navigate after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            onContinue()
                        }
                    }) {
                        ZStack {
                            // Button shadow base
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.black.opacity(0.3))
                                .frame(height: 56)
                                .offset(y: 4)
                                .blur(radius: 8)
                            
                            // Main button background
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0),
                                            Color(red: 0.3, green: 0.7, blue: 1.0),
                                            Color(red: 0.5, green: 0.3, blue: 1.0)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 56)
                            
                            // Button highlight
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                                .frame(height: 56)
                            
                            // Button text
                            Text("Continue")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    .scaleEffect(buttonScale)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarStyle(.lightContent)
        .onAppear {
            startPremiumAnimationSequence()
        }
    }
    
    private func startPremiumAnimationSequence() {
        // Start background animation
        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
            gradientOffset = 0.3
        }
        
        // Start breathing animation for logo
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            buttonBreathing = 1.02
        }
        
        // Step 1: Logo dramatic entrance (0.8s)
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            logoOpacity = 1.0
            logoScale = 1.0
        }
        
        // Logo rotation effect
        withAnimation(.easeOut(duration: 1.2)) {
            logoRotation = 360
        }
        
        // Step 2: Particle constellation fade in (1.0s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 1.5)) {
                particleOpacity = 1.0
            }
        }
        
        // Step 3: Text letter-by-letter animation (1.4s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.8)) {
                textOpacity = 1.0
                textLetterSpacing = 0.5
            }
        }
        
        // Step 4: Button dramatic entrance (2.2s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5, blendDuration: 0)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
        
        // Final premium haptic feedback when sequence completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
        }
    }
}

// PREMIUM CONSTELLATION PARTICLE COMPONENT
struct ConstellationParticle: View {
    let index: Int
    let screenSize: CGSize
    let opacity: Double
    
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var glowIntensity: Double = 0.3
    @State private var particleScale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.9),
                        Color.blue.opacity(0.6),
                        Color.purple.opacity(0.3),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 8
                )
            )
            .frame(width: particleSize, height: particleSize)
            .blur(radius: 1)
            .scaleEffect(particleScale)
            .opacity(opacity * glowIntensity)
            .position(
                x: initialX + xOffset,
                y: initialY + yOffset
            )
            .onAppear {
                startParticleAnimation()
            }
    }
    
    private var particleSize: CGFloat {
        [2, 3, 4, 2, 3, 5, 2, 4, 3, 2, 4, 3][index % 12]
    }
    
    private var initialX: CGFloat {
        let positions: [CGFloat] = [0.15, 0.25, 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.2, 0.4, 0.6, 0.8]
        return screenSize.width * positions[index % 12]
    }
    
    private var initialY: CGFloat {
        let positions: [CGFloat] = [0.2, 0.3, 0.25, 0.4, 0.35, 0.5, 0.45, 0.6, 0.7, 0.8, 0.75, 0.9]
        return screenSize.height * positions[index % 12]
    }
    
    private func startParticleAnimation() {
        let animationDuration = Double.random(in: 4.0...8.0)
        let delayOffset = Double(index) * 0.3
        
        // Floating animation
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
            .delay(delayOffset)
        ) {
            yOffset = CGFloat.random(in: -20...20)
            xOffset = CGFloat.random(in: -15...15)
        }
        
        // Twinkling effect
        withAnimation(
            .easeInOut(duration: Double.random(in: 2.0...4.0))
            .repeatForever(autoreverses: true)
            .delay(delayOffset)
        ) {
            glowIntensity = Double.random(in: 0.6...1.0)
            particleScale = CGFloat.random(in: 0.8...1.2)
        }
    }
}

// Extension to handle status bar style
extension View {
    func statusBarStyle(_ style: UIStatusBarStyle) -> some View {
        background(StatusBarStyleHost(style: style))
    }
}

struct StatusBarStyleHost: UIViewControllerRepresentable {
    let style: UIStatusBarStyle
    
    func makeUIViewController(context: Context) -> StatusBarStyleViewController {
        StatusBarStyleViewController(style: style)
    }
    
    func updateUIViewController(_ uiViewController: StatusBarStyleViewController, context: Context) {
        uiViewController.style = style
    }
}

class StatusBarStyleViewController: UIViewController {
    var style: UIStatusBarStyle
    
    init(style: UIStatusBarStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return style
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
