import SwiftUI
import AppTrackingTransparency

@available(iOS 16.0, *)
struct PrivacyAnalyticsView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @State private var appUsageTracking = true
    @State private var workoutTracking = true
    @State private var anonymousTracking = true
    @State private var attPermissionGranted = false
    
    @State private var iconOpacity: Double = 0.0
    @State private var iconScale: CGFloat = 0.9
    @State private var descriptionOpacity: Double = 0.0
    @State private var cardsOpacity: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    @State private var cardsOffset: [CGFloat] = [10, 10, 10, 10, 10]
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 10
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen dark background
                Color(hex: "#0D0F14")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    navigationBar()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Shield Icon
                            shieldIcon()
                                .opacity(iconOpacity)
                                .scaleEffect(iconScale)
                                .padding(.top, 32)
                            
                            // Description Text
                            descriptionText()
                                .opacity(descriptionOpacity)
                                .padding(.top, 16)
                            
                            // Privacy Options Cards
                            privacyCardsStack()
                                .padding(.top, 24)
                            
                            Spacer(minLength: 120) // Space for bottom button
                        }
                    }
                }
                
                // Bottom CTA Button (Fixed)
                VStack {
                    Spacer()
                    bottomButton()
                        .opacity(buttonOpacity)
                        .offset(y: buttonOffset)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    @ViewBuilder
    private func navigationBar() -> some View {
        HStack {
            Button(action: onSkip) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            Text("Privacy & Analytics")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance the back button
            Color.clear
                .frame(width: 24, height: 24)
                .padding(.trailing, 20)
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private func shieldIcon() -> some View {
        ZStack {
            // Glow background
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#4E2A6F") ?? .purple,
                            Color(hex: "#2A1A34").opacity(0)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
            
            // Shield icon
            Image(systemName: "shield.lefthalf.fill")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private func descriptionText() -> some View {
        Text("Help us improve FitConnect while keeping your data private and secure. Your privacy is our priority.")
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func privacyCardsStack() -> some View {
        VStack(spacing: 16) {
            PrivacyOptionCardView(
                title: "App Usage & Feature Performance",
                subtitle: "How you use features and app performance metrics.",
                icon: "chart.pie.fill",
                gradientColors: [Color(hex: "#4A7BFF") ?? .blue, Color(hex: "#1A2A5F") ?? .blue],
                trailingType: .checkmark,
                isEnabled: $appUsageTracking,
                onTap: { optionTapped(index: 0) }
            )
            .opacity(cardsOpacity[0])
            .offset(y: cardsOffset[0])
            
            PrivacyOptionCardView(
                title: "Workout Success Rates & Patterns",
                subtitle: "Workout completion and habit tracking.",
                icon: "figure.walk.circle.fill",
                gradientColors: [Color(hex: "#4AFFA1") ?? .green, Color(hex: "#1A3F2A") ?? .green],
                trailingType: .checkmark,
                isEnabled: $workoutTracking,
                onTap: { optionTapped(index: 1) }
            )
            .opacity(cardsOpacity[1])
            .offset(y: cardsOffset[1])
            
            PrivacyOptionCardView(
                title: "Anonymous User Behavior",
                subtitle: "Aggregated usage patterns with no personal identifiers.",
                icon: "person.3.fill",
                gradientColors: [Color(hex: "#FFD54F") ?? .yellow, Color(hex: "#4A3F1A") ?? .yellow],
                trailingType: .checkmark,
                isEnabled: $anonymousTracking,
                onTap: { optionTapped(index: 2) }
            )
            .opacity(cardsOpacity[2])
            .offset(y: cardsOffset[2])
            
            PrivacyOptionCardView(
                title: "No Personal Information Collected",
                subtitle: "We never collect names, emails, or personal identifiers.",
                icon: "lock.fill",
                gradientColors: [Color(hex: "#4A4A4A").opacity(0.4), Color(hex: "#4A4A4A").opacity(0.4)],
                trailingType: .lock,
                isEnabled: .constant(false),
                onTap: nil
            )
            .opacity(cardsOpacity[3])
            .offset(y: cardsOffset[3])
            
            PrivacyOptionCardView(
                title: "iOS Tracking Permission",
                subtitle: "Tap to configure system-level tracking preferences.",
                icon: "hand.raised.fill",
                gradientColors: [Color(hex: "#FF6B00") ?? .orange, Color(hex: "#5A2A00") ?? .orange],
                trailingType: .chevron,
                isEnabled: $attPermissionGranted,
                onTap: { requestTrackingPermissions() }
            )
            .opacity(cardsOpacity[4])
            .offset(y: cardsOffset[4])
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func bottomButton() -> some View {
        Button(action: onContinue) {
            Text("Allow Tracking & Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#3A8AFF") ?? .blue,
                            Color(hex: "#8C2FFF") ?? .purple
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
        }
        .scaleEffect(buttonOpacity > 0 ? 1.0 : 0.95)
    }
    
    private func startAnimationSequence() {
        // Step 1: Shield Icon animation
        withAnimation(.easeOut(duration: 0.5)) {
            iconOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                iconScale = 1.0
            }
        }
        
        // Step 2: Description text (0.2s delay after icon finishes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                descriptionOpacity = 1.0
            }
        }
        
        // Step 3: Cards (0.2s delay after description, staggered by 0.1s each)
        let cardStartDelay = 1.6
        for index in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardStartDelay + (Double(index) * 0.1)) {
                withAnimation(.easeOut(duration: 0.5)) {
                    cardsOpacity[index] = 1.0
                    cardsOffset[index] = 0
                }
            }
        }
        
        // Step 4: Bottom button (0.1s after last card)
        DispatchQueue.main.asyncAfter(deadline: .now() + cardStartDelay + 0.5 + 0.1) {
            withAnimation(.easeOut(duration: 0.4)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
    
    private func optionTapped(index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("Privacy option \(index) tapped")
    }
    
    private func requestTrackingPermissions() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                attPermissionGranted = status == .authorized
            }
        }
    }
}

@available(iOS 16.0, *)
struct PrivacyOptionCardView: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let trailingType: TrailingIconType
    @Binding var isEnabled: Bool
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    enum TrailingIconType {
        case checkmark, lock, chevron
    }
    
    var body: some View {
        Button(action: {
            guard let onTap = onTap else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: gradientColors),
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Text stack
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Trailing icon
                trailingIcon()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#121318") ?? .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#5A4AFF") ?? .purple,
                                        Color(hex: "#3A8AFF") ?? .blue
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .disabled(onTap == nil)
    }
    
    @ViewBuilder
    private func trailingIcon() -> some View {
        switch trailingType {
        case .checkmark:
            ZStack {
                Circle()
                    .fill(isEnabled ? Color(hex: "#7E57FF") ?? .purple : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                if isEnabled {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
        case .lock:
            ZStack {
                Circle()
                    .fill(Color(hex: "#4A4A4A").opacity(0.4))
                    .frame(width: 20, height: 20)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PrivacyAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyAnalyticsView(
            onContinue: {},
            onSkip: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
