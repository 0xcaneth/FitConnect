import SwiftUI
import AppTrackingTransparency

@available(iOS 16.0, *)
struct PrivacyAnalyticsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @StateObject private var privacyManager = PrivacyManager.shared
    @State private var attPermissionGranted = false
    
    // Animation States
    @State private var animateIn = false
    @State private var pulseAnimation = false
    @State private var cardAnimations: [Bool] = Array(repeating: false, count: 5)
    @State private var toggleGlows: [Bool] = Array(repeating: false, count: 3)
    
    // Scroll Detection
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var hasScrolledToBottom = false
    @State private var showButton = false
    @State private var scrollIndicatorOpacity: Double = 1.0
    @State private var bounceAnimation = false
    
    // Progress Tracking
    @State private var readingProgress: Double = 0.0
    
    // Button Animation
    @State private var buttonPressed = false
    @State private var gradientAnimation = false
    @State private var buttonSuccessAnimation = false
    
    @Environment(\.colorScheme) var colorScheme
    
    private var colors: PrivacyColors {
        PrivacyColors(colorScheme: colorScheme)
    }
    
    // Calculate scroll progress (0.0 to 1.0)
    private var scrollProgress: Double {
        let maxScroll = max(contentHeight - scrollViewHeight + 50, 0) // Added buffer
        guard maxScroll > 50 else { return 1.0 }
        let progress = min(max(scrollOffset / maxScroll, 0.0), 1.0)
        return progress
    }
    
    // Check if user has scrolled enough to see all content
    private var hasReadAllContent: Bool {
        scrollProgress > 0.92 // 92% scroll progress required
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium Background
                premiumBackgroundView
                
                VStack(spacing: 0) {
                    // Navigation with Progress Ring
                    premiumNavigationBar
                    
                    // Scrollable Content
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 28) {
                                premiumHeaderSection
                                privacyCardsSection
                                
                                // Extended bottom spacer for proper scroll detection
                                Spacer(minLength: 200)
                                    .id("bottom")
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear
                                        .onAppear {
                                            contentHeight = contentGeometry.size.height
                                        }
                                        .onChange(of: contentGeometry.size.height) { newHeight in
                                            contentHeight = newHeight
                                        }
                                }
                            )
                        }
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear
                                    .onAppear {
                                        scrollViewHeight = scrollGeometry.size.height
                                    }
                                    .onChange(of: scrollGeometry.size.height) { newHeight in
                                        scrollViewHeight = newHeight
                                    }
                            }
                        )
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            updateScrollProgress(value)
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: -geo.frame(in: .named("scroll")).origin.y
                                    )
                            }
                        )
                    }
                }
                
                // Scroll Down Indicator (appears initially)
                if !hasScrolledToBottom && scrollIndicatorOpacity > 0 {
                    VStack {
                        Spacer()
                        scrollDownIndicator
                            .padding(.bottom, 50)
                    }
                    .opacity(scrollIndicatorOpacity)
                }
                
                // Button - ONLY appears when scrolled to bottom
                if showButton {
                    VStack {
                        Spacer()
                        premiumActionButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, max(34, geometry.safeAreaInsets.bottom + 16))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startPremiumAnimationSequence()
            checkATTStatus()
            
            print("[PrivacyAnalyticsView] Screen appeared")
            privacyManager.printCurrentStatus()
            privacyManager.trackScreenView("privacy_analytics")
        }

    }
    
    // MARK: - Premium Background
    @ViewBuilder
    private var premiumBackgroundView: some View {
        ZStack {
            // Base background
            colors.background.ignoresSafeArea()
            
            // Dynamic gradient that responds to scroll
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: colors.gradientStart.opacity(0.4), location: 0.0),
                    .init(color: colors.gradientMid.opacity(0.25), location: 0.3),
                    .init(color: colors.gradientEnd.opacity(0.15), location: 0.7),
                    .init(color: Color.clear, location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(1.0 + readingProgress * 0.1)
            .animation(.easeInOut(duration: 0.8), value: readingProgress)
            
            // Sophisticated background pattern
            if colorScheme == .light {
                premiumBackgroundPattern
                    .opacity(animateIn ? 0.12 : 0.0)
            } else {
                premiumDarkPattern
                    .opacity(animateIn ? 0.08 : 0.0)
            }
        }
    }
    
    @ViewBuilder
    private var premiumBackgroundPattern: some View {
        GeometryReader { geometry in
            ZStack {
                // More subtle flowing organic shapes
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    colors.accentTeal.opacity(0.06),
                                    colors.accentGreen.opacity(0.03),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .offset(
                            x: CGFloat(index * 80 - 120),
                            y: CGFloat(index * 200) + (pulseAnimation ? 20 : -20)
                        )
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 6.0 + Double(index) * 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.5),
                            value: pulseAnimation
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private var premiumDarkPattern: some View {
        GeometryReader { geometry in
            ZStack {
                // More subtle grid pattern
                ForEach(0..<3, id: \.self) { row in
                    ForEach(0..<4, id: \.self) { col in
                        Circle()
                            .fill(colors.accentTeal.opacity(0.02))
                            .frame(width: 2, height: 2)
                            .offset(
                                x: CGFloat(col * 100) - 150,
                                y: CGFloat(row * 120) - 200
                            )
                            .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 4.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(row + col) * 0.2),
                                value: pulseAnimation
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Premium Navigation with Progress Ring
    @ViewBuilder
    private var premiumNavigationBar: some View {
        HStack {
            // Back button with enhanced design
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onBack()
            }) {
                ZStack {
                    Circle()
                        .fill(colors.cardBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: colors.shadowColor, radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colors.textPrimary)
                }
            }
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
            
            Spacer()
            
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Premium Header with Trust Visualization
    @ViewBuilder
    private var premiumHeaderSection: some View {
        VStack(spacing: 20) {
            // Premium Trust/Privacy Illustration
            ZStack {
                // Outer protection ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.accentTeal.opacity(0.3),
                                colors.accentGreen.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                
                // Data flow visualization
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.accentTeal.opacity(0.8),
                                    colors.accentGreen.opacity(0.6)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 16, height: 3)
                        .offset(x: 50)
                        .rotationEffect(.degrees(Double(index) * 60))
                        .opacity(pulseAnimation ? 0.9 : 0.4)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .animation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: pulseAnimation
                        )
                }
                
                // Central trust core
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    colors.accentTeal.opacity(0.2),
                                    colors.accentGreen.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    // Multi-layered shield design
                    ZStack {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(colors.accentTeal.opacity(0.3))
                            .offset(x: 1, y: 1)
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colors.accentTeal,
                                        colors.accentGreen
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    // Dynamic trust indicator
                    if hasReadAllContent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(colors.accentGreen)
                                    .frame(width: 24, height: 24)
                            )
                            .offset(x: 20, y: -20)
                            .scaleEffect(buttonSuccessAnimation ? 1.3 : 1.1)
                            .opacity(buttonSuccessAnimation ? 1.0 : 0.9)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: buttonSuccessAnimation)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .scaleEffect(animateIn ? 1.0 : 0.7)
            .opacity(animateIn ? 1.0 : 0.0)

            // Enhanced Typography
            VStack(spacing: 16) {
                Text("Privacy & Analytics")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.textPrimary,
                                colors.textPrimary.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateIn ? 1.0 : 0.9)
                    .opacity(animateIn ? 1.0 : 0.0)
                
                Text("We're building the future of fitness privacy. Your data powers innovation while staying completely secure and anonymous.")
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .opacity(animateIn ? 1.0 : 0.0)
            }
        }
    }
    
    // MARK: - Enhanced Privacy Cards
    @ViewBuilder
    private var privacyCardsSection: some View {
        VStack(spacing: 20) {
            PremiumPrivacyCard(
                title: "App Performance Analytics",
                subtitle: "Crash reporting, feature usage patterns, and performance metrics to optimize your experience",
                customIcon: "chart.line.uptrend.xyaxis.circle.fill",
                iconColors: [colors.accentBlue, colors.accentTeal],
                trailingType: .toggle,
                isEnabled: $privacyManager.appUsageTrackingEnabled,
                glowActive: toggleGlows[0],
                colorScheme: colorScheme,
                onTap: nil
            )
            .scaleEffect(cardAnimations[0] ? 1.0 : 0.95)
            .opacity(cardAnimations[0] ? 1.0 : 0.0)
            .offset(y: cardAnimations[0] ? 0 : 30)
            
            PremiumPrivacyCard(
                title: "Workout Intelligence",
                subtitle: "Anonymous workout completion rates, exercise preferences, and success patterns to enhance our AI coaching",
                customIcon: "heart.circle.fill",
                iconColors: [colors.accentGreen, colors.accentTeal],
                trailingType: .toggle,
                isEnabled: $privacyManager.workoutTrackingEnabled,
                glowActive: toggleGlows[1],
                colorScheme: colorScheme,
                onTap: nil
            )
            .scaleEffect(cardAnimations[1] ? 1.0 : 0.95)
            .opacity(cardAnimations[1] ? 1.0 : 0.0)
            .offset(y: cardAnimations[1] ? 0 : 30)
            
            PremiumPrivacyCard(
                title: "Community Trend Insights",
                subtitle: "Aggregated, anonymous behavior patterns that help us understand fitness trends and improve our community features",
                customIcon: "person.3.sequence.fill",
                iconColors: [colors.accentOrange, colors.accentGreen],
                trailingType: .toggle,
                isEnabled: $privacyManager.anonymousTrackingEnabled,
                glowActive: toggleGlows[2],
                colorScheme: colorScheme,
                onTap: nil
            )
            .scaleEffect(cardAnimations[2] ? 1.0 : 0.95)
            .opacity(cardAnimations[2] ? 1.0 : 0.0)
            .offset(y: cardAnimations[2] ? 0 : 30)
            
            PremiumPrivacyCard(
                title: "Zero Personal Data Collection",
                subtitle: "We never collect names, emails, phone numbers, addresses, or any personally identifiable information",
                customIcon: "lock.shield.fill",
                iconColors: [Color.gray.opacity(0.8), Color.gray.opacity(0.6)],
                trailingType: .lock,
                isEnabled: .constant(false),
                glowActive: false,
                colorScheme: colorScheme,
                onTap: nil
            )
            .scaleEffect(cardAnimations[3] ? 1.0 : 0.95)
            .opacity(cardAnimations[3] ? 0.7 : 0.0)
            .offset(y: cardAnimations[3] ? 0 : 30)
            
            PremiumPrivacyCard(
                title: "iOS Privacy Controls",
                subtitle: "Configure your device-level tracking preferences and advertising identifier settings",
                customIcon: "gear.badge.questionmark",
                iconColors: [colors.accentPurple, colors.accentBlue],
                trailingType: .chevron,
                isEnabled: $attPermissionGranted,
                glowActive: false,
                colorScheme: colorScheme,
                onTap: { requestTrackingPermissions() }
            )
            .scaleEffect(cardAnimations[4] ? 1.0 : 0.95)
            .opacity(cardAnimations[4] ? 1.0 : 0.0)
            .offset(y: cardAnimations[4] ? 0 : 30)
        }
    }
    
    // MARK: - Enhanced Scroll Indicator
    @ViewBuilder
    private var scrollDownIndicator: some View {
        VStack(spacing: 16) {
            Text("Please read all sections")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(colors.textSecondary)
            
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.accentTeal,
                                    colors.accentGreen
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: 12)
                        .scaleEffect(y: bounceAnimation ? 1.3 : 0.7)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: bounceAnimation
                        )
                }
            }
            .frame(width: 30, height: 50)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colors.cardBackground.opacity(0.95))
                .shadow(color: colors.shadowColor, radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colors.cardBorder.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Premium Action Button
    @ViewBuilder
    private var premiumActionButton: some View {
        Button(action: {
            performButtonAction()
        }) {
            ZStack {
                // Dynamic shadow
                RoundedRectangle(cornerRadius: 28)
                    .fill(colors.shadowColor.opacity(0.3))
                    .frame(height: 56)
                    .offset(y: buttonPressed ? 2 : 6)
                    .blur(radius: buttonPressed ? 4 : 8)
                
                // Main button with gradient
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: colors.accentTeal, location: 0.0),
                                .init(color: colors.accentGreen, location: 0.5),
                                .init(color: colors.accentBlue, location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 56)
                
                // Highlight overlay
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ]),
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(height: 56)
                
                // Button content
                if gradientAnimation {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(buttonSuccessAnimation ? 1.2 : 1.0)
                        
                        Text("Accepted")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                } else {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .scaleEffect(buttonPressed ? 0.97 : 1.0)
        .disabled(gradientAnimation)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonPressed)
    }
    
    // MARK: - Animation Functions
    private func startPremiumAnimationSequence() {
        // Start continuous animations
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            bounceAnimation = true
        }
        
        // Initial entrance animation
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            animateIn = true
        }
        
        // Staggered card animations
        for index in 0..<cardAnimations.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 + (Double(index) * 0.15)) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    cardAnimations[index] = true
                }
            }
        }
    }
    
    private func updateScrollProgress(_ offset: CGFloat) {
        scrollOffset = offset
        
        // Update reading progress
        let newProgress = scrollProgress
        if abs(newProgress - readingProgress) > 0.01 {
            withAnimation(.easeOut(duration: 0.3)) {
                readingProgress = newProgress
            }
        }
        
        // Check if user has read all content
        let newHasReadAll = hasReadAllContent
        
        if newHasReadAll && !hasScrolledToBottom {
            hasScrolledToBottom = true
            
            // Hide scroll indicator
            withAnimation(.easeOut(duration: 0.8)) {
                scrollIndicatorOpacity = 0.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showButton = true
            }
            
            // Success feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonSuccessAnimation = true
            }
        }
    }
    
    private func performButtonAction() {
        guard gradientAnimation == false else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        privacyManager.completeOnboarding()
        
        withAnimation(.easeInOut(duration: 0.15)) {
            buttonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                buttonPressed = false
            }
            
            withAnimation(.linear(duration: 1.2)) {
                gradientAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).repeatCount(2, autoreverses: true)) {
                    buttonSuccessAnimation.toggle()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                let successFeedback = UINotificationFeedbackGenerator()
                successFeedback.notificationOccurred(.success)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onContinue()
                }
            }
        }
    }
    
    private func requestTrackingPermissions() {
        // Prevent multiple calls
        guard !attPermissionGranted else {
            print("[PrivacyAnalyticsView] ATT permission already granted")
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("[PrivacyAnalyticsView] Requesting ATT permission...")
        
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                let granted = status == .authorized
                print("[PrivacyAnalyticsView] ATT permission result: \(status.rawValue) - \(granted ? "GRANTED" : "DENIED")")
                
                attPermissionGranted = granted
                privacyManager.attPermissionGranted = granted
                
                // Track the permission result
                privacyManager.trackEvent("att_permission_result", parameters: [
                    "granted": granted,
                    "status": status.rawValue
                ])
            }
        }
    }
    
    private func checkATTStatus() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        let granted = status == .authorized
        print("[PrivacyAnalyticsView] Current ATT status: \(status.rawValue) - \(granted ? "GRANTED" : "DENIED")")
        
        attPermissionGranted = granted
        privacyManager.attPermissionGranted = granted
    }

}

// MARK: - Enhanced Premium Privacy Card
struct PremiumPrivacyCard: View {
    let title: String
    let subtitle: String
    let customIcon: String
    let iconColors: [Color]
    let trailingType: TrailingType
    @Binding var isEnabled: Bool
    let glowActive: Bool
    let colorScheme: ColorScheme
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    @State private var localGlow = false // For toggle glow effect
    
    enum TrailingType {
        case toggle, lock, chevron
    }
    
    private var colors: PrivacyColors {
        PrivacyColors(colorScheme: colorScheme)
    }
    
    var body: some View {
        Button(action: {
            handleTap()
        }) {
            HStack(spacing: 18) {
                // Enhanced icon with more sophisticated design
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    iconColors[0].opacity(0.25),
                                    iconColors[1].opacity(0.15),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 56, height: 56)
                        .scaleEffect((glowActive || localGlow) ? 1.1 : 1.0)
                        .animation(.easeOut(duration: 0.3), value: glowActive || localGlow)
                    
                    // Icon container
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColors[0].opacity(0.15),
                                    iconColors[1].opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            iconColors[0].opacity(0.3),
                                            iconColors[1].opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: customIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: iconColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Enhanced content layout
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .default))
                        .foregroundColor(colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .lineSpacing(1)
                }
                
                Spacer()
                
                enhancedTrailingControl
            }
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colors.cardBackground)
                    .shadow(
                        color: colors.shadowColor,
                        radius: (glowActive || localGlow) ? 16 : 8,
                        x: 0,
                        y: (glowActive || localGlow) ? 8 : 4
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colors.cardBorder.opacity((glowActive || localGlow) ? 0.8 : 0.3),
                                        colors.cardBorder.opacity((glowActive || localGlow) ? 0.4 : 0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: (glowActive || localGlow) ? 1.5 : 1
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .disabled(trailingType == .lock || (trailingType == .toggle && onTap == nil && false)) // Enable toggle even without onTap
        .opacity(trailingType == .lock ? 0.7 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
    }
    
    // MARK: - Handle Tap Function
    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeInOut(duration: 0.12)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isPressed = false
            }
            
            // Handle different actions based on trailing type
            switch trailingType {
            case .toggle:
                // For toggle, change the binding directly AND call onTap if exists
                isEnabled.toggle()
                
                // Trigger glow effect
                withAnimation(.easeOut(duration: 0.3)) {
                    localGlow = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        localGlow = false
                    }
                }
                
                // Call onTap if provided (for additional analytics)
                onTap?()
                
            case .chevron:
                // For chevron, just call onTap
                onTap?()
                
            case .lock:
                // Lock does nothing
                break
            }
        }
    }

    @ViewBuilder
    private var enhancedTrailingControl: some View {
        switch trailingType {
        case .toggle:
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.accentTeal,
                                colors.accentGreen
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.toggleOffBackground,
                                colors.toggleOffBackground.opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 54, height: 32)
                    .shadow(color: colors.shadowColor, radius: 2, x: 0, y: 1)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 12
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: colors.shadowColor, radius: 4, x: 0, y: 2)
                    .offset(x: isEnabled ? 11 : -11)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEnabled)
            }
            
        case .lock:
            ZStack {
                Circle()
                    .fill(colors.cardBackground.opacity(0.5))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colors.textTertiary)
            }
            
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colors.textSecondary)
                .scaleEffect(0.9)
        }
    }
}

// MARK: - Enhanced Color Scheme
struct PrivacyColors {
    let colorScheme: ColorScheme
    
    // More balanced, less vivid colors
    let accentTeal = Color(red: 0.0, green: 0.78, blue: 0.72) // #00C7B8
    let accentGreen = Color(red: 0.18, green: 0.74, blue: 0.27) // #2FBD45
    let accentBlue = Color(red: 0.22, green: 0.55, blue: 0.92) // #388CEB
    let accentOrange = Color(red: 0.92, green: 0.50, blue: 0.22) // #EB8038
    let accentPurple = Color(red: 0.50, green: 0.22, blue: 0.88) // #8038E0
    
    var background: Color {
        colorScheme == .light ? Color.white : Color(red: 0.05, green: 0.05, blue: 0.07)
    }
    
    var cardBackground: Color {
        colorScheme == .light ?
        Color.white.opacity(0.98) :
        Color(red: 0.08, green: 0.08, blue: 0.12)
    }
    
    var cardBorder: Color {
        colorScheme == .light ?
        accentTeal.opacity(0.20) :
        accentTeal.opacity(0.35)
    }
    
    var textPrimary: Color {
        colorScheme == .light ? Color.black : Color.white
    }
    
    var textSecondary: Color {
        colorScheme == .light ? Color.black.opacity(0.7) : Color.white.opacity(0.7)
    }
    
    var textTertiary: Color {
        colorScheme == .light ? Color.black.opacity(0.5) : Color.white.opacity(0.5)
    }
    
    var shadowColor: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.black.opacity(0.20)
    }
    
    var toggleOffBackground: Color {
        colorScheme == .light ? Color.gray.opacity(0.25) : Color.gray.opacity(0.35)
    }
    
    var gradientStart: Color {
        colorScheme == .light ? accentTeal.opacity(0.85) : accentTeal.opacity(0.35)
    }
    
    var gradientMid: Color {
        colorScheme == .light ? accentGreen.opacity(0.80) : accentGreen.opacity(0.25)
    }
    
    var gradientEnd: Color {
        colorScheme == .light ? accentBlue.opacity(0.75) : accentBlue.opacity(0.20)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PrivacyAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PrivacyAnalyticsView(
                onContinue: {},
                onBack: {}
            )
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            PrivacyAnalyticsView(
                onContinue: {},
                onBack: {}
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
#endif