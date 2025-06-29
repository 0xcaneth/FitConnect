import SwiftUI
import AppTrackingTransparency

@available(iOS 16.0, *)
struct PrivacyAnalyticsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var appUsageTracking = true
    @State private var workoutTracking = true
    @State private var anonymousTracking = true
    @State private var attPermissionGranted = false
    
    @State private var titleOpacity: Double = 0.0
    @State private var titleScale: CGFloat = 0.9
    @State private var shieldOpacity: Double = 0.0
    @State private var shieldScale: CGFloat = 0.9
    @State private var shieldPulse: CGFloat = 1.0
    @State private var descriptionOpacity: Double = 0.0
    @State private var cardsOpacity: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    @State private var cardsOffset: [CGFloat] = [20, 20, 20, 20, 20]
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 30
    @State private var buttonPulse: CGFloat = 1.0
    
    @State private var cardGlowIntensity: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                        .ignoresSafeArea()
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.15),
                            Color.blue.opacity(0.1),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.3),
                        startRadius: 50,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                    
                    Rectangle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    premiumNavigationBar()
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            premiumShieldIcon()
                                .opacity(shieldOpacity)
                                .scaleEffect(shieldScale * shieldPulse)
                                .padding(.top, 40)
                            
                            VStack(spacing: 16) {
                                Text("Privacy & Analytics")
                                    .font(.system(size: 28, weight: .semibold, design: .rounded))
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
                                    .opacity(titleOpacity)
                                    .scaleEffect(titleScale)
                                
                                Text("Help us improve FitConnect while keeping your data private and secure. Your privacy is our priority.")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .opacity(descriptionOpacity)
                                    .padding(.horizontal, 32)
                            }
                            .padding(.top, 24)
                            
                            premiumPrivacyCardsStack()
                                .padding(.top, 32)
                            
                            Spacer(minLength: 140)
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    premiumBottomButton()
                        .opacity(buttonOpacity)
                        .offset(y: buttonOffset)
                        .scaleEffect(buttonPulse)
                        .padding(.bottom, 34)
                        .padding(.horizontal, 32)
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
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ]),
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
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func premiumShieldIcon() -> some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.4),
                            Color.blue.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 120, height: 120)
                .blur(radius: 12)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 100, height: 100)
                .blur(radius: 8)
            
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.purple.opacity(0.4),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .blur(radius: 6)
            
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 52, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.purple.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: shieldPulse)
    }
    
    @ViewBuilder
    private func premiumPrivacyCardsStack() -> some View {
        VStack(spacing: 16) {
            PremiumPrivacyCard(
                title: "App Usage & Feature Performance",
                subtitle: "How you use features and app performance metrics.",
                icon: "chart.pie.fill",
                iconColor: Color(red: 0.29, green: 0.48, blue: 1.0),
                trailingType: .toggle,
                isEnabled: $appUsageTracking,
                glowIntensity: cardGlowIntensity[0],
                onTap: { 
                    appUsageTracking.toggle()
                    triggerCardGlow(index: 0)
                }
            )
            .opacity(cardsOpacity[0])
            .offset(y: cardsOffset[0])
            
            PremiumPrivacyCard(
                title: "Workout Success Rates & Patterns",
                subtitle: "Workout completion and habit tracking.",
                icon: "figure.run.circle.fill",
                iconColor: Color(red: 0.29, green: 1.0, blue: 0.63),
                trailingType: .toggle,
                isEnabled: $workoutTracking,
                glowIntensity: cardGlowIntensity[1],
                onTap: {
                    workoutTracking.toggle()
                    triggerCardGlow(index: 1)
                }
            )
            .opacity(cardsOpacity[1])
            .offset(y: cardsOffset[1])
            
            PremiumPrivacyCard(
                title: "Anonymous User Behavior",
                subtitle: "Aggregated usage patterns with no personal identifiers.",
                icon: "person.3.fill",
                iconColor: Color(red: 1.0, green: 0.84, blue: 0.31),
                trailingType: .toggle,
                isEnabled: $anonymousTracking,
                glowIntensity: cardGlowIntensity[2],
                onTap: {
                    anonymousTracking.toggle()
                    triggerCardGlow(index: 2)
                }
            )
            .opacity(cardsOpacity[2])
            .offset(y: cardsOffset[2])
            
            PremiumPrivacyCard(
                title: "No Personal Information Collected",
                subtitle: "We never collect names, emails, or personal identifiers.",
                icon: "lock.fill",
                iconColor: Color(red: 0.5, green: 0.5, blue: 0.5),
                trailingType: .lock,
                isEnabled: .constant(false),
                glowIntensity: 0.0,
                onTap: nil
            )
            .opacity(cardsOpacity[3])
            .offset(y: cardsOffset[3])
            
            PremiumPrivacyCard(
                title: "iOS Tracking Permission",
                subtitle: "Tap to configure system-level tracking preferences.",
                icon: "hand.raised.fill",
                iconColor: Color(red: 1.0, green: 0.42, blue: 0.0),
                trailingType: .chevron,
                isEnabled: $attPermissionGranted,
                glowIntensity: cardGlowIntensity[4],
                onTap: { requestTrackingPermissions() }
            )
            .opacity(cardsOpacity[4])
            .offset(y: cardsOffset[4])
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func premiumBottomButton() -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            onContinue()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 50)
                    .offset(y: 4)
                    .blur(radius: 8)
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.9, blue: 1.0),
                                Color(red: 0.5, green: 0.3, blue: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 50)
                
                RoundedRectangle(cornerRadius: 25)
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
                    .frame(height: 50)
                
                Text("Allow Tracking & Continue")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: buttonPulse)
    }
    
    private func startPremiumAnimationSequence() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            shieldPulse = 1.05
        }
        
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            buttonPulse = 1.02
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            shieldOpacity = 1.0
            shieldScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                titleOpacity = 1.0
                titleScale = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                descriptionOpacity = 1.0
            }
        }
        
        let cardStartDelay = 1.2
        for index in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardStartDelay + (Double(index) * 0.05)) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    cardsOpacity[index] = 1.0
                    cardsOffset[index] = 0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
    
    private func triggerCardGlow(index: Int) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.2)) {
            cardGlowIntensity[index] = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.8)) {
                cardGlowIntensity[index] = 0.0
            }
        }
    }
    
    private func requestTrackingPermissions() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.2)) {
            cardGlowIntensity[4] = 1.0
        }
        
        ATTrackingManager.requestTrackingAuthorization { status in
            DispatchQueue.main.async {
                attPermissionGranted = status == .authorized
                
                withAnimation(.easeOut(duration: 0.8)) {
                    cardGlowIntensity[4] = 0.0
                }
            }
        }
    }
}

struct PremiumPrivacyCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let trailingType: TrailingType
    @Binding var isEnabled: Bool
    let glowIntensity: Double
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    enum TrailingType {
        case toggle, lock, chevron
    }
    
    var body: some View {
        Button(action: {
            guard let onTap = onTap else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    iconColor,
                                    iconColor.opacity(0.8)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                trailingControl()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.08, green: 0.08, blue: 0.12),
                                Color(red: 0.06, green: 0.06, blue: 0.10)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.purple.opacity(0.4 + glowIntensity * 0.6),
                                        Color.blue.opacity(0.3 + glowIntensity * 0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .shadow(
                                color: Color.purple.opacity(glowIntensity * 0.5),
                                radius: glowIntensity * 8,
                                x: 0,
                                y: 0
                            )
                    )
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .disabled(onTap == nil)
        .opacity(trailingType == .lock ? 0.4 : 1.0)
    }
    
    @ViewBuilder
    private func trailingControl() -> some View {
        switch trailingType {
        case .toggle:
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ?
                          LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.8),
                                Color.blue.opacity(0.6)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                          ) :
                          LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.2)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                          )
                    )
                    .frame(width: 44, height: 24)
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.white.opacity(0.9)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .offset(x: isEnabled ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isEnabled)
            }
            
        case .lock:
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            
        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PrivacyAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyAnalyticsView(
            onContinue: {},
            onBack: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
