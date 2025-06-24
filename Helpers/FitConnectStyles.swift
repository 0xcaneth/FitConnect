import SwiftUI
import UIKit

// MARK: - FitConnect Design System 2024

// FitConnectFonts struct remains the same
struct FitConnectFonts {
    static func largeTitle() -> Font {
        return .largeTitle.weight(.bold)
    }
    
    static func title() -> Font {
        return .title.weight(.bold)
    }
    
    static let body = Font.system(size: 16, weight: .medium)
    static let bodyRegular = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 14, weight: .regular)
    static let small = Font.system(size: 12, weight: .medium)
}

// MARK: - Enhanced Background Component
struct EnhancedGradientBackground: View {
    @State private var animateGradient = false
    @State private var animateOverlay = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FitConnectColors.gradientTop, FitConnectColors.gradientBottom],
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    FitConnectColors.accentCyan.opacity(0.15),
                    Color.clear
                ],
                center: animateOverlay ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()
            .opacity(0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateOverlay.toggle()
            }
        }
    }
}

// MARK: - Glass Card Component
struct GlassCard<Content: View>: View {
    let content: Content
    let opacityValue: Double

    init(opacity: Double = 0.12, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.opacityValue = opacity
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(opacityValue))

                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thinMaterial)
                        .opacity(0.85)
                }
                .compositingGroup()
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
    }
}

// MARK: - Enhanced Primary Button
struct EnhancedPrimaryButton: View {
    let title: String
    let iconName: String?
    let action: () -> Void
    let isEnabled: Bool
    
    @State private var isPressed = false
    @State private var animateGlow = false
    
    init(title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.iconName = icon
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if let sfSymbolName = iconName {
                    Image(systemName: sfSymbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isEnabled ? FitConnectColors.buttonPrimaryText : FitConnectColors.textTertiary)
                }
                
                Text(title)
                    .font(FitConnectFonts.body)
                    .fontWeight(.bold)
                    .foregroundColor(isEnabled ? FitConnectColors.buttonPrimaryText : FitConnectColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .disabled(!isEnabled)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(isEnabled ? FitConnectColors.buttonPrimary : FitConnectColors.glassCard)
                .shadow(color: isEnabled ? FitConnectColors.accentCyan.opacity(0.3) : Color.clear, radius: animateGlow ? 12 : 6, x: 0, y: 4)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .onAppear {
            if isEnabled {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow.toggle()
                }
            }
        }
    }
}

// MARK: - Enhanced Text Field with Eye Icon (Updated for all requirements)
struct EnhancedTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .autocapitalization(.none) 
                        .disableAutocorrection(true) 
                        .textContentType(isSecure ? .password : .none)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none) 
                        .disableAutocorrection(true) 
                        .keyboardType(keyboardType)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : (isSecure ? .password : .none))
                        .focused($isFocused)
                }
            }
            .font(.system(size: 16, weight: .regular)) 
            .foregroundColor(.white) 
            .accentColor(Color(red: 0.0, green: 0.9, blue: 1.0)) 
            
            if isSecure {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5)) 
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.12, green: 0.12, blue: 0.15)) 
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color(red: 0.0, green: 0.9, blue: 1.0) : Color.clear, 
                    lineWidth: 2
                )
                .shadow(
                    color: isFocused ? Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.3) : Color.clear,
                    radius: isFocused ? 8 : 0,
                    x: 0, y: 0
                )
        )
    }
}

// MARK: - Loading Skeleton
struct LoadingSkeleton: View {
    @State private var animateShimmer = false
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(FitConnectColors.glassCard)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                FitConnectColors.textTertiary.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: animateShimmer ? .leading : .trailing,
                            endPoint: animateShimmer ? .trailing : .leading
                        )
                    )
                    .opacity(animateShimmer ? 0.7 : 0.3)
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animateShimmer.toggle()
                }
            }
    }
}
