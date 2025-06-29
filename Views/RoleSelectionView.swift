import SwiftUI

@available(iOS 16.0, *)
struct RoleSelectionView: View {
    let onRoleSelected: (UserRole) -> Void
    let onBack: () -> Void
    
    @State private var selectedRole: UserRole? = nil
    @State private var isAnimating = false
    
    // Premium animation states
    @State private var titleOpacity: Double = 0.0
    @State private var titleScale: CGFloat = 0.9
    @State private var subtitleOpacity: Double = 0.0
    @State private var cardsOpacity: [Double] = [0.0, 0.0]
    @State private var cardsOffset: [CGFloat] = [30, 30]
    @State private var cardsScale: [CGFloat] = [0.95, 0.95]
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 40
    @State private var buttonPulse: CGFloat = 1.0
    @State private var buttonScale: CGFloat = 1.0
    
    // Particle and glow effects
    @State private var particleOffset1: CGFloat = 0
    @State private var particleOffset2: CGFloat = 0
    @State private var particleOpacity: Double = 0.0
    @State private var cardGlowIntensity: [Double] = [0.0, 0.0]
    @State private var backgroundGradientOffset: CGFloat = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // PREMIUM BACKGROUND with animated particles
                ZStack {
                    // Base dark gradient
                    Color(hex: "#0A0B0F")
                        .ignoresSafeArea()
                    
                    // Animated background gradient
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#7E57FF").opacity(0.15),
                            Color(hex: "#4A7BFF").opacity(0.1),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.3 + backgroundGradientOffset, y: 0.4),
                        startRadius: 100,
                        endRadius: 400
                    )
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true), value: backgroundGradientOffset)
                    
                    // Secondary gradient for depth
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#00E5FF").opacity(0.08),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.7, y: 0.6),
                        startRadius: 80,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                    
                    // Floating particles
                    ForEach(0..<8, id: \.self) { index in
                        RoleSelectionParticle(
                            index: index,
                            screenSize: geometry.size,
                            opacity: particleOpacity
                        )
                    }
                }
                
                VStack(spacing: 0) {
                    // PREMIUM NAVIGATION BAR
                    premiumNavigationBar()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            // HERO SECTION
                            premiumHeroSection()
                                .padding(.top, 40)
                            
                            // ROLE CARDS
                            premiumRoleCardsStack()
                                .padding(.top, 40)
                            
                            Spacer(minLength: 160)
                        }
                    }
                }
                
                // FLOATING CTA BUTTON
                VStack {
                    Spacer()
                    premiumContinueButton()
                        .opacity(buttonOpacity)
                        .offset(y: buttonOffset)
                        .scaleEffect(buttonScale * buttonPulse)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            startPremiumAnimationSequence()
        }
    }
    
    @ViewBuilder
    private func premiumNavigationBar() -> some View {
        HStack {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onBack()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.leading, 20)
            
            Spacer()
            
            // Progress dots: ◯◯●◯ (step 3 of 4)
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                Circle()
                    .fill(Color(hex: "#7E57FF"))
                    .frame(width: 8, height: 8)
                
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func premiumHeroSection() -> some View {
        VStack(spacing: 20) {
            // Premium icon with depth layers
            ZStack {
                // Outer glow
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#7E57FF").opacity(0.4),
                                Color(hex: "#00E5FF").opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 12)
                
                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "#7E57FF").opacity(0.3),
                                Color(hex: "#4A7BFF").opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 70
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 8)
                
                // Main icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#7E57FF"),
                                Color(hex: "#5A3FD6")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color(hex: "#7E57FF").opacity(0.5), radius: 20, x: 0, y: 4)
                
                // Icon
                Image(systemName: "person.2.fill")
                    .font(.system(size: 45, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .opacity(titleOpacity)
            .scaleEffect(titleScale)
            
            // Title and subtitle
            VStack(spacing: 12) {
                Text("Choose Your Role")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)
                
                Text("Select your account type to get started with FitConnect")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(subtitleOpacity)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    @ViewBuilder
    private func premiumRoleCardsStack() -> some View {
        VStack(spacing: 20) {
            // USER CARD
            PremiumRoleCard(
                role: .client,
                title: "I'm a User",
                subtitle: "Track your fitness journey and connect with nutrition experts",
                icon: "figure.run.circle.fill",
                iconColor: Color(hex: "#4A7BFF"),
                features: [
                    "Track workouts and nutrition",
                    "Connect with dietitians",
                    "Personal health insights",
                    "Goal setting and monitoring"
                ],
                isSelected: selectedRole == .client,
                glowIntensity: cardGlowIntensity[0],
                onTap: {
                    selectRole(.client, cardIndex: 0)
                }
            )
            .opacity(cardsOpacity[0])
            .offset(y: cardsOffset[0])
            .scaleEffect(cardsScale[0])
            
            // DIETITIAN CARD
            PremiumRoleCard(
                role: .dietitian,
                title: "I'm a Dietitian",
                subtitle: "Help clients achieve their health goals with professional guidance",
                icon: "stethoscope.circle.fill",
                iconColor: Color(hex: "#4AFFA1"),
                features: [
                    "Manage client relationships",
                    "Create custom meal plans",
                    "Professional analytics",
                    "Schedule appointments"
                ],
                isSelected: selectedRole == .dietitian,
                glowIntensity: cardGlowIntensity[1],
                onTap: {
                    selectRole(.dietitian, cardIndex: 1)
                }
            )
            .opacity(cardsOpacity[1])
            .offset(y: cardsOffset[1])
            .scaleEffect(cardsScale[1])
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func premiumContinueButton() -> some View {
        Button(action: {
            guard let selectedRole = selectedRole, !isAnimating else { return }
            isAnimating = true
            
            // Premium haptic feedback sequence
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Button animation sequence
            withAnimation(.easeInOut(duration: 0.1)) {
                buttonScale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    buttonScale = 1.02
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.2)) {
                    buttonScale = 1.0
                }
            }
            
            // Success haptic
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let successFeedback = UIImpactFeedbackGenerator(style: .light)
                successFeedback.impactOccurred()
                
                onRoleSelected(selectedRole)
            }
        }) {
            ZStack {
                // Button shadow
                RoundedRectangle(cornerRadius: 26)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 52)
                    .offset(y: 4)
                    .blur(radius: 10)
                
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        LinearGradient(
                            colors: buttonGradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 52)
                
                // Button highlight
                RoundedRectangle(cornerRadius: 26)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 52)
                
                // Button text
                Text("Continue as \(selectedRole?.displayName ?? "User")")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .disabled(selectedRole == nil)
        .opacity(selectedRole == nil ? 0.4 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedRole)
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: buttonPulse)
    }
    
    private var buttonGradientColors: [Color] {
        guard let selectedRole = selectedRole else {
            // Default gradient when no role selected
            return [
                Color(hex: "#00E5FF"),
                Color(hex: "#7E57FF")
            ]
        }
        
        switch selectedRole {
        case .client: // User
            return [
                Color(hex: "#4A7BFF"), // Blue
                Color(hex: "#3A6FE8")  // Darker blue
            ]
        case .dietitian:
            return [
                Color(hex: "#4AFFA1"), // Green
                Color(hex: "#3AE891")  // Darker green
            ]
        }
    }
    
    private func selectRole(_ role: UserRole, cardIndex: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        selectedRole = role
        
        // Trigger card glow effect
        withAnimation(.easeOut(duration: 0.3)) {
            cardGlowIntensity[cardIndex] = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 1.0)) {
                cardGlowIntensity[cardIndex] = 0.0
            }
        }
    }
    
    private func startPremiumAnimationSequence() {
        // Background animation
        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
            backgroundGradientOffset = 0.4
        }
        
        // Button breathing animation
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            buttonPulse = 1.02
        }
        
        // Hero section animations
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            titleOpacity = 1.0
            titleScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                subtitleOpacity = 1.0
            }
        }
        
        // Particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeIn(duration: 1.2)) {
                particleOpacity = 1.0
            }
        }
        
        // Role cards with staggered animation
        let cardStartDelay = 1.0
        for index in 0..<2 {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardStartDelay + (Double(index) * 0.2)) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                    cardsOpacity[index] = 1.0
                    cardsOffset[index] = 0
                    cardsScale[index] = 1.0
                }
            }
        }
        
        // Continue button
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
}

// PREMIUM ROLE CARD COMPONENT
struct PremiumRoleCard: View {
    let role: UserRole
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let features: [String]
    let isSelected: Bool
    let glowIntensity: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var hoverEffect: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(spacing: 20) {
                // Header with icon and title
                HStack(spacing: 16) {
                    ZStack {
                        // Icon glow
                        Circle()
                            .fill(iconColor.opacity(0.3))
                            .frame(width: 60, height: 60)
                            .blur(radius: 8)
                        
                        // Icon background
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        iconColor,
                                        iconColor.opacity(0.8)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 28
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        // Icon
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                
                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(iconColor)
                                .frame(width: 6, height: 6)
                                .opacity(0.8)
                            
                            Text(feature)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.15),
                                Color(red: 0.08, green: 0.08, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ? [
                                        iconColor.opacity(0.8 + glowIntensity * 0.2),
                                        iconColor.opacity(0.6 + glowIntensity * 0.4)
                                    ] : [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                            .shadow(
                                color: isSelected ? iconColor.opacity(glowIntensity * 0.6) : Color.clear,
                                radius: glowIntensity * 12,
                                x: 0,
                                y: 0
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.98 : (isSelected ? 1.02 : 1.0))
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
}

// PREMIUM FLOATING PARTICLES COMPONENT
struct RoleSelectionParticle: View {
    let index: Int
    let screenSize: CGSize
    let opacity: Double
    
    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.8),
                        particleColor.opacity(0.6),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: particleSize / 2
                )
            )
            .frame(width: particleSize, height: particleSize)
            .blur(radius: 1)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(
                x: initialX + xOffset,
                y: initialY + yOffset
            )
            .onAppear {
                startParticleAnimation()
            }
    }
    
    private var particleSize: CGFloat {
        [3, 4, 2, 5, 3, 4, 2, 3][index % 8]
    }
    
    private var particleColor: Color {
        [Color.purple, Color.blue, Color.cyan, Color.purple, Color.blue, Color.cyan, Color.purple, Color.blue][index % 8]
    }
    
    private var initialX: CGFloat {
        let positions: [CGFloat] = [0.1, 0.2, 0.8, 0.9, 0.15, 0.85, 0.3, 0.7]
        return screenSize.width * positions[index % 8]
    }
    
    private var initialY: CGFloat {
        let positions: [CGFloat] = [0.2, 0.7, 0.3, 0.8, 0.5, 0.4, 0.9, 0.6]
        return screenSize.height * positions[index % 8]
    }
    
    private func startParticleAnimation() {
        let animationDuration = Double.random(in: 6.0...10.0)
        let delayOffset = Double(index) * 0.4
        
        // Floating motion
        withAnimation(
            .easeInOut(duration: animationDuration)
            .repeatForever(autoreverses: true)
            .delay(delayOffset)
        ) {
            yOffset = CGFloat.random(in: -30...30)
            xOffset = CGFloat.random(in: -20...20)
        }
        
        // Rotation
        withAnimation(
            .linear(duration: Double.random(in: 8.0...15.0))
            .repeatForever(autoreverses: false)
            .delay(delayOffset)
        ) {
            rotation = 360
        }
        
        // Scale pulsing
        withAnimation(
            .easeInOut(duration: Double.random(in: 3.0...5.0))
            .repeatForever(autoreverses: true)
            .delay(delayOffset)
        ) {
            scale = CGFloat.random(in: 0.7...1.3)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView(
            onRoleSelected: { _ in },
            onBack: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif