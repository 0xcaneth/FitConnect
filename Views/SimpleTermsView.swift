import SwiftUI

@available(iOS 16.0, *)
struct SimpleTermsView: View {
    let onAccept: () -> Void
    let onBack: () -> Void
    
    @State private var hasScrolledToBottom = false
    @State private var showAcceptButton = false
    
    // Premium animation states based on your design specs
    @State private var titleOpacity: Double = 0.0
    @State private var titleScale: CGFloat = 0.9
    @State private var descriptionOpacity: Double = 0.0
    @State private var cardsOpacity: [Double] = [0.0, 0.0, 0.0, 0.0]
    @State private var cardsOffset: [CGFloat] = [20, 20, 20, 20]
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 30
    @State private var buttonPulse: CGFloat = 1.0
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // BACKGROUND: #121214 with subtle radial glow
                ZStack {
                    // Primary dark backdrop
                    Color(hex: "#121214")
                        .ignoresSafeArea()
                    
                    // Ambient radial glow behind key icons
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#7E57FF").opacity(0.1),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.5, y: 0.3),
                        startRadius: 80,
                        endRadius: 300
                    )
                    .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    // HEADER: Back arrow + Progress dots + Title
                    premiumHeader()
                    
                    // SCROLLABLE CONTENT
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            // TERMS CARDS: Per your design specs
                            termsCardsStack()
                                .padding(.top, 24)
                            
                            // Bottom marker for scroll detection
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                                .onAppear {
                                    withAnimation(.easeIn(duration: 0.5)) {
                                        hasScrolledToBottom = true
                                        showAcceptButton = true
                                    }
                                }
                            
                            Spacer(minLength: 120) // Space for fixed bottom button
                        }
                        .padding(.horizontal, 32) // 32pt side margins per spec
                    }
                    .onAppear {
                        // Auto-scroll to bottom after a delay to show content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                // Replace with correct scrollTo function
                            }
                        }
                    }
                }
                
                // FIXED BOTTOM CTA BUTTON
                VStack {
                    Spacer()
                    premiumCTAButton()
                        .opacity(buttonOpacity)
                        .offset(y: buttonOffset)
                        .scaleEffect(buttonPulse)
                        .padding(.horizontal, 32) // 32pt side margins per spec
                        .padding(.bottom, 34)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            startDesignSpecAnimations()
        }
    }
    
    @ViewBuilder
    private func premiumHeader() -> some View {
        VStack(spacing: 24) {
            // Navigation + Progress row
            HStack {
                // Back arrow (per your interaction spec: popViewController)
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    onBack() // This triggers popViewController behavior
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium, design: .rounded)) // SF Pro Rounded per spec
                    }
                    .foregroundColor(Color(hex: "#CCCCCC")) // Back label color per spec
                }
                
                Spacer()
                
                // Progress dots: ◯●◯ (step 2 of 3)
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8) // 8pt size per spec
                    
                    Circle()
                        .fill(Color(hex: "#7E57FF")) // Accent highlight purple per spec
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 32) // 32pt side margins per spec
            .padding(.top, 8)
            
            // Title section
            VStack(spacing: 12) {
                Text("Terms & Conditions")
                    .font(.system(size: 28, weight: .semibold, design: .rounded)) // SF Pro Rounded 28pt semibold per spec
                    .foregroundColor(Color(hex: "#FFFFFF")) // Primary text color per spec
                    .opacity(titleOpacity)
                    .scaleEffect(titleScale)
                
                Text("Please review these terms before continuing")
                    .font(.system(size: 14, weight: .regular, design: .rounded)) // Adjusted to match design
                    .foregroundColor(Color(hex: "#9B9B9B")) // Secondary text color per spec
                    .multilineTextAlignment(.center)
                    .opacity(descriptionOpacity)
            }
            .padding(.horizontal, 32) // 32pt side margins per spec
        }
    }
    
    @ViewBuilder
    private func termsCardsStack() -> some View {
        VStack(spacing: 16) { // 16pt between cards per spec
            // Card 1: Privacy & Data
            PremiumTermsCard(
                title: "1. Privacy & Data",
                content: "We respect your privacy and protect your personal health data according to applicable privacy laws.",
                icon: "doc.text.fill",
                iconColor: Color(hex: "#4A7BFF"), // Blue icon per design
                cardIndex: 0
            )
            .opacity(cardsOpacity[0])
            .offset(y: cardsOffset[0])
            
            // Card 2: Health Information
            PremiumTermsCard(
                title: "2. Health Information",
                content: "FitConnect is not a medical device. Consult healthcare professionals for medical advice.",
                icon: "cross.case.fill",
                iconColor: Color(hex: "#FF6B6B"), // Red icon per design
                cardIndex: 1
            )
            .opacity(cardsOpacity[1])
            .offset(y: cardsOffset[1])
            
            // Card 3: User Conduct
            PremiumTermsCard(
                title: "3. User Conduct",
                content: "Users must provide accurate information and use the app responsibly.",
                icon: "person.circle.fill",
                iconColor: Color(hex: "#4AFFA1"), // Green icon per design
                cardIndex: 2
            )
            .opacity(cardsOpacity[2])
            .offset(y: cardsOffset[2])
            
            // Card 4: Service Availability
            PremiumTermsCard(
                title: "4. Service Availability",
                content: "We strive to maintain service availability but cannot guarantee uninterrupted access.",
                icon: "wifi.circle.fill",
                iconColor: Color(hex: "#8C57FF"), // Purple icon per design
                cardIndex: 3
            )
            .opacity(cardsOpacity[3])
            .offset(y: cardsOffset[3])
        }
    }
    
    @ViewBuilder
    private func premiumCTAButton() -> some View {
        Button(action: {
            guard !isAnimating else { return }
            isAnimating = true
            
            // Button tap animation per your spec: 0.1s press, 0.3s release, ripple
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.prepare()
            impactFeedback.impactOccurred()
            
            // Press animation: scale 0.97 over 0.1s
            withAnimation(.easeInOut(duration: 0.1)) {
                buttonPulse = 0.97
            }
            
            // Release animation: scale 1.0 over 0.3s with ripple effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                    buttonPulse = 1.0
                }
            }
            
            // Navigate after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onAccept()
            }
        }) {
            Text("Accept & Continue")
                .font(.system(size: 18, weight: .semibold, design: .rounded)) // SF Pro Rounded 18pt semibold per spec
                .foregroundColor(Color(hex: "#FFFFFF")) // Button text color per spec
                .frame(maxWidth: .infinity)
                .frame(height: 52) // 52pt height per spec
                .background(
                    // Gradient: #00E5FF → #7C4DFF per your spec
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#00E5FF"), // Accent gradient start
                            Color(hex: "#7C4DFF")  // Accent gradient end
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(26) // 26pt corner radius per spec (52pt height / 2)
                .shadow(color: Color(hex: "#7C4DFF").opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .disabled(!showAcceptButton)
        .scaleEffect(showAcceptButton ? 1.0 : 0.95)
        .opacity(showAcceptButton ? 1.0 : 0.6)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAcceptButton)
    }
    
    private func startDesignSpecAnimations() {
        // Button pulse animation: 1.0 → 1.02 → 1.0 over 3s loop per your spec
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            buttonPulse = 1.02
        }
        
        // Title animation: immediate spring entrance
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
            titleOpacity = 1.0
            titleScale = 1.0
        }
        
        // Description fade: 0.3s delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                descriptionOpacity = 1.0
            }
        }
        
        // Cards entrance: fade + slide, 0.6s duration, 0.1s stagger per your spec
        let cardStartDelay = 0.6
        for index in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + cardStartDelay + (Double(index) * 0.1)) {
                withAnimation(
                    .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.6) // cubic-bezier per your spec
                ) {
                    cardsOpacity[index] = 1.0
                    cardsOffset[index] = 0
                }
            }
        }
        
        // Button entrance: 1.2s delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6, blendDuration: 0)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
    }
}

// PREMIUM TERMS CARD COMPONENT
struct PremiumTermsCard: View {
    let title: String
    let content: String
    let icon: String
    let iconColor: Color
    let cardIndex: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) { // 16pt spacing per spec
            // Icon: 32×32pt circle per your spec
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 32, height: 32) // 32pt per spec
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded)) // 18pt semibold per spec
                    .foregroundColor(Color(hex: "#FFFFFF")) // Primary text per spec
                
                Text(content)
                    .font(.system(size: 14, weight: .regular, design: .rounded)) // 14pt regular per spec
                    .foregroundColor(Color(hex: "#9B9B9B")) // Secondary text per spec
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16) // 16pt internal padding per spec
        .background(
            RoundedRectangle(cornerRadius: 16) // 16pt corner radius per spec
                .fill(Color(hex: "#1E1E1F")) // Card background per spec
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#2A2A2E"), lineWidth: 1) // 1px border per spec
                )
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct SimpleTermsView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleTermsView(onAccept: {}, onBack: {})
            .preferredColorScheme(.dark)
    }
}
#endif
