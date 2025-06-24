import SwiftUI

struct SplashView: View {
    let onContinue: () -> Void
    
    @State private var logoOpacity: Double = 0.0
    @State private var logoOffset: CGFloat = -20
    @State private var textOpacity: Double = 0.0
    @State private var buttonOpacity: Double = 0.0
    @State private var buttonOffset: CGFloat = 10
    @State private var buttonScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Exact gradient background matching the screenshot
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#000000") ?? .black,
                        Color(hex: "#0D0F14") ?? .black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top spacing to position logo 160 points from safe area top
                    Spacer()
                        .frame(height: 160)
                    
                    // Logo with exact specifications
                    ZStack {
                        // Purple gradient glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#7C4DFF") ?? .purple,
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 160, height: 160)
                            .blur(radius: 20)
                        
                        // Main icon background
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#7C4DFF") ?? .purple,
                                        Color(hex: "#6200EA") ?? .purple
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.purple.opacity(0.3), radius: 20, x: 0, y: 0)
                        
                        // Running person icon - exactly 50% of icon size
                        Image(systemName: "figure.run")
                            .font(.system(size: 60, weight: .regular))
                            .foregroundColor(.white)
                    }
                    .opacity(logoOpacity)
                    .offset(y: logoOffset)
                    
                    // Title - exactly 24 points below logo
                    Text("FitConnect")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                        .opacity(textOpacity)
                    
                    // Subtitle - exactly 8 points below title
                    Text("Your Health, Your Way")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(textOpacity)
                    
                    // Spacing before button - exactly 48 points
                    Spacer()
                        .frame(height: 48)
                    
                    // Continue button with exact specifications
                    Button(action: {
                        guard !isAnimating else { return }
                        isAnimating = true
                        
                        // Button press animation
                        withAnimation(.easeInOut(duration: 0.1)) {
                            buttonScale = 0.97
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                buttonScale = 1.0
                            }
                        }
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        // Navigate after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onContinue()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#00E5FF") ?? .cyan,
                                        Color(hex: "#7C4DFF") ?? .purple
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(24)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 2)
                    }
                    .scaleEffect(buttonScale)
                    .opacity(buttonOpacity)
                    .offset(y: buttonOffset)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    
                    // Bottom spacer to center content vertically
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarStyle(.lightContent)
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Step 1: Logo fade in and slide down (0.6s fade + 0.4s slide)
        withAnimation(.easeOut(duration: 0.6)) {
            logoOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOffset = 0
            }
        }
        
        // Step 2: Title and subtitle fade in after 0.2s delay (total delay: 1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }
        }
        
        // Step 3: Button fade in and slide up after another 0.2s delay (total delay: 1.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            withAnimation(.easeIn(duration: 0.5)) {
                buttonOpacity = 1.0
                buttonOffset = 0
            }
        }
        
        // Subtle haptic feedback when all animations complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
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
