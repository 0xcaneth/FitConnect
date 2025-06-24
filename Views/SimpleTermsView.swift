import SwiftUI

@available(iOS 16.0, *)
struct SimpleTermsView: View {
    let onAccept: () -> Void
    let onBack: () -> Void
    
    @State private var hasScrolledToBottom = false
    @State private var showAcceptButton = false
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#0D0F14") ?? .black,
                    Color(hex: "#1E2029") ?? .black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView()
                
                // Scrollable Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            // Welcome Section
                            welcomeSection()
                            
                            // Terms Sections
                            termsSection(
                                title: "1. Privacy & Data",
                                content: "We respect your privacy and protect your personal health data according to applicable privacy laws.",
                                icon: "shield.lefthalf.filled"
                            )
                            
                            termsSection(
                                title: "2. Health Information",
                                content: "FitConnect is not a medical device. Consult healthcare professionals for medical advice.",
                                icon: "heart.text.square"
                            )
                            
                            termsSection(
                                title: "3. User Conduct",
                                content: "Users must provide accurate information and use the app responsibly.",
                                icon: "person.circle"
                            )
                            
                            termsSection(
                                title: "4. Service Availability",
                                content: "We strive to maintain service availability but cannot guarantee uninterrupted access.",
                                icon: "wifi"
                            )
                            
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
                            
                            Spacer(minLength: 120) // Space for button
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    .onAppear {
                        // Auto-scroll to bottom after a delay to show content
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Fixed Bottom Button
                bottomButtonView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    private func headerView() -> some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color(hex: "#7E57FF") ?? .purple)
                        .frame(width: 8, height: 8)
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            VStack(spacing: 8) {
                Text("Terms & Conditions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Please review these terms before continuing")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func welcomeSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#7E57FF") ?? .purple,
                                    Color(hex: "#5A3FD6") ?? .purple
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to FitConnect")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Your fitness journey starts here")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text("By using FitConnect, you agree to the following terms and conditions:")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func termsSection(title: String, content: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "#7E57FF") ?? .purple)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func bottomButtonView() -> some View {
        VStack(spacing: 16) {
            // Scroll indicator
            if !hasScrolledToBottom {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Scroll to continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(showAcceptButton ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: showAcceptButton)
            }
            
            // Accept Button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onAccept()
            }) {
                Text("Accept & Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Group {
                            if showAcceptButton {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#7E57FF") ?? .purple,
                                        Color(hex: "#5A3FD6") ?? .purple
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.3)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .cornerRadius(28)
                    .shadow(
                        color: showAcceptButton ? Color(hex: "#7E57FF").opacity(0.3) : Color.clear,
                        radius: 12, x: 0, y: 4
                    )
            }
            .disabled(!showAcceptButton)
            .scaleEffect(showAcceptButton ? 1.0 : 0.95)
            .opacity(showAcceptButton ? 1.0 : 0.6)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showAcceptButton)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(
            // Gradient overlay at bottom
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color(hex: "#0D0F14").opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
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
