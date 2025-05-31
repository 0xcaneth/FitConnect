import SwiftUI
#if canImport(Lottie)
import Lottie // Conditional import
#endif
#if canImport(UIKit)
import UIKit // For Color.uiColor extension
#endif

// MARK: - FitConnect Design System 2024

struct FitConnectColors {
    // Primary Gradient - Deep Navy Blue
    static let gradientTop = Color(red: 0.07, green: 0.16, blue: 0.36)    // #122A5C
    static let gradientBottom = Color(red: 0.05, green: 0.10, blue: 0.25) // #0D1A40
    
    // Accent Colors
    static let accentCyan = Color(red: 0.0, green: 0.85, blue: 1.0)       // #00D9FF
    static let accentBlue = Color(red: 0.2, green: 0.6, blue: 1.0)        // #3399FF
    
    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.8)
    static let textTertiary = Color.white.opacity(0.6)
    static let textBody = Color.white.opacity(0.85)
    
    // Background Colors
    static let glassCard = Color.white.opacity(0.12)
    static let glassCardStrong = Color.white.opacity(0.18)
    static let inputBackground = Color.white.opacity(0.15)
    
    // Interactive Colors
    static let buttonPrimary = Color.white
    static let buttonPrimaryText = gradientBottom
    static let buttonSecondary = accentCyan
    static let focusGlow = accentCyan.opacity(0.4)
}

// MARK: - FitConnectColors Aliases (Consolidated)
extension FitConnectColors {
    static var accentColor: Color        { FitConnectColors.accentCyan }
    static var cardBackground: Color     { Color(.secondarySystemBackground) }
}

// MARK: - Color to UIColor Extension (Consolidated)
extension Color {
    var uiColor: UIColor {
        #if canImport(UIKit)
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
            // iOS 13 Fallback: Manual mapping for known colors or a default.
            if self == FitConnectColors.accentCyan {
                return UIColor(red: 0.0, green: 0.85, blue: 1.0, alpha: 1.0)
            }
            // Add other explicit mappings for your app's palette if needed for iOS 13.
            // Example: if self == Color.red { return UIColor.red }
            
            print("Warning: Converting an unmapped SwiftUI.Color to UIColor on iOS 13. Defaulting to black. Color: \(self)")
            return UIColor.black 
        }
        #else
        // Fallback for platforms where UIKit is not available (e.g., watchOS without UIKit import).
        return UIColor() 
        #endif
    }
}

struct FitConnectFonts {
    static func largeTitle() -> Font {
        if #available(iOS 14.0, *) {
            return .largeTitle.weight(.bold) // .weight() on Font is iOS 14+
        } else {
            return Font.system(size: 34, weight: .bold) // Standard large title size for iOS 13
        }
    }
    
    static func title() -> Font {
        if #available(iOS 14.0, *) {
            return .title.weight(.bold) // .weight() on Font is iOS 14+
        } else {
            return Font.system(size: 28, weight: .bold) // Standard title size for iOS 13
        }
    }
    
    // These are iOS 13 compatible
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
            .backgroundSafeArea() // Assumes backgroundSafeArea() is an iOS 13-compatible helper defined elsewhere
            
            RadialGradient(
                colors: [
                    FitConnectColors.accentCyan.opacity(0.15), // .opacity() is iOS 13+
                    Color.clear
                ],
                center: animateOverlay ? .topLeading : .bottomTrailing,
                startRadius: 100,
                endRadius: 400
            )
            .backgroundSafeArea() // Assumes backgroundSafeArea() is an iOS 13-compatible helper
            .opacity(0.6) // .opacity() is iOS 13+
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
    let opacityValue: Double // To avoid conflict with .opacity modifier if used directly

    init(opacity: Double = 0.12, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.opacityValue = opacity
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                // Layering backgrounds for visual effect
                ZStack {
                    // Base color layer, providing a consistent minimum opacity and color tone.
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(opacityValue))

                    // Conditional material or fallback effect on top
                    if #available(iOS 15.0, *) {
                        // iOS 15+ uses .thinMaterial
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.thinMaterial) // .thinMaterial is iOS 15+
                            .opacity(0.85) // Slightly increased opacity for better legibility of material
                    } else {
                        // iOS 13/14 fallback: semi-transparent color with blur
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(opacityValue * 0.65)) // Adjusted opacity for fallback visual
                            .blur(radius: 1) // Subtle blur, available on iOS 13
                    }
                }
                .compositingGroup() // Helps with rendering complex layered backgrounds
                .cornerRadius(16) // Apply corner radius to the entire background stack
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6) // Shadow is iOS 13+
            )
    }
}


// MARK: - Enhanced Primary Button
struct EnhancedPrimaryButton: View {
    let title: String
    let iconName: String? // Renamed from 'icon' to be clear it's an SF Symbol name
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
            impactFeedback.impactOccurred() // iOS 13+
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { // iOS 13+
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            HStack(spacing: 12) {
                if let sfSymbolName = iconName {
                    Image(systemName: sfSymbolName) // iOS 13+
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isEnabled ? FitConnectColors.buttonPrimaryText : FitConnectColors.textTertiary)
                }
                
                Text(title)
                    .font(FitConnectFonts.body) // Assumes FitConnectFonts.body is iOS 13 compatible
                    .fontWeight(.bold) // .fontWeight on Text is iOS 13+
                    .foregroundColor(isEnabled ? FitConnectColors.buttonPrimaryText : FitConnectColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .disabled(!isEnabled) // iOS 13+
        .background(
            RoundedRectangle(cornerRadius: 28) // iOS 13+
                .fill(isEnabled ? FitConnectColors.buttonPrimary : FitConnectColors.glassCard) // .fill is iOS 13+
                .shadow(color: isEnabled ? FitConnectColors.accentCyan.opacity(0.3) : Color.clear, radius: animateGlow ? 12 : 6, x: 0, y: 4) // .shadow is iOS 13+
        )
        .scaleEffect(isPressed ? 0.96 : 1.0) // .scaleEffect is iOS 13+
        .onAppear { // .onAppear is iOS 13+
            if isEnabled {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animateGlow.toggle()
                }
            }
        }
    }
}

// MARK: - Enhanced Text Field
struct EnhancedTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    
    // This state is shared and managed by the implementations below.
    @State private var isEffectivelyFocused: Bool = false 

    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            // iOS 15+ uses @FocusState internally and syncs with isEffectivelyFocused
            ModernTextFieldWrapper(
                placeholder: placeholder,
                text: $text,
                isSecure: isSecure,
                keyboardType: keyboardType,
                isFocusedCoordinator: $isEffectivelyFocused
            )
        } else {
            // iOS 13/14 uses onEditingChanged to update isEffectivelyFocused
            LegacyTextField(
                placeholder: placeholder,
                text: $text,
                isSecure: isSecure,
                keyboardType: keyboardType,
                isFocusedBinding: $isEffectivelyFocused
            )
        }
    }
}

// MARK: - iOS 15+ Modern TextField Implementation Wrapper
@available(iOS 15.0, *) // Entire struct is only available on iOS 15+
private struct ModernTextFieldWrapper: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    @Binding var isFocusedCoordinator: Bool // Binding to parent's @State

    @FocusState private var actualFieldFocus: Bool // Internal @FocusState for this view

    var body: some View {
        let textField = Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }

        textField
            .focused($actualFieldFocus) // .focused is iOS 15+
            .font(FitConnectFonts.body)
            .foregroundColor(FitConnectColors.textPrimary)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.thinMaterial.opacity(0.8)) // .thinMaterial is iOS 15+
                    .background( // Solid color underneath material for consistent look
                        RoundedRectangle(cornerRadius: 14)
                            .fill(FitConnectColors.inputBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                actualFieldFocus ? FitConnectColors.accentCyan : Color.clear,
                                lineWidth: 2
                            )
                            .shadow( // Focus glow effect
                                color: actualFieldFocus ? FitConnectColors.focusGlow : Color.clear,
                                radius: actualFieldFocus ? 8 : 0,
                                x: 0, y: 0
                            )
                    )
            )
            // Sync @FocusState with parent's @State (`isFocusedCoordinator`)
            .onChange(of: actualFieldFocus) { newFocusValue in // This variant of onChange is iOS 14+, fine here.
                if isFocusedCoordinator != newFocusValue {
                    isFocusedCoordinator = newFocusValue
                }
            }
            // Sync from parent's @State to @FocusState if parent changes it
            .onChange(of: isFocusedCoordinator) { newCoordinatorValue in
                 if actualFieldFocus != newCoordinatorValue {
                    actualFieldFocus = newCoordinatorValue
                 }
            }
            .onAppear { // Initial sync on appear
                actualFieldFocus = isFocusedCoordinator
            }
    }
}

// MARK: - iOS 13-14 Legacy TextField Implementation
private struct LegacyTextField: View {
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    @Binding var isFocusedBinding: Bool // Binding to parent's @State

    var body: some View {
        let textField = Group {
            if isSecure {
                // For SecureField on iOS 13/14, onEditingChanged is not available.
                // We use onCommit to detect when focus is lost.
                // A tap gesture is added to try and set focus state visually.
                SecureField(placeholder, text: $text, onCommit: {
                    isFocusedBinding = false
                })
            } else {
                TextField(placeholder, text: $text, onEditingChanged: { editing in
                    isFocusedBinding = editing
                }, onCommit: {
                    isFocusedBinding = false
                })
                .keyboardType(keyboardType)
            }
        }
        
        textField
            .font(FitConnectFonts.body)
            .foregroundColor(FitConnectColors.textPrimary)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(FitConnectColors.inputBackground) // Simple solid background
                    .overlay(
                        // Simple border for visual focus feedback
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isFocusedBinding ? FitConnectColors.accentCyan : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            // Add a tap gesture to allow setting focus state, especially for SecureField
            .simultaneousGesture(TapGesture().onEnded({ _ in 
                if !isFocusedBinding { // Only set to true if not already focused, or to re-trigger
                    isFocusedBinding = true
                }
            }))
    }
}

// MARK: - Loading Skeleton
struct LoadingSkeleton: View {
    @State private var animateShimmer = false
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8) // iOS 13+
            .fill(FitConnectColors.glassCard) // .fill is iOS 13+
            .frame(width: width, height: height) // .frame is iOS 13+
            .overlay( // .overlay is iOS 13+
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient( // iOS 13+
                            colors: [
                                Color.clear,
                                FitConnectColors.textTertiary.opacity(0.3), // .opacity is iOS 13+
                                Color.clear
                            ],
                            startPoint: animateShimmer ? .leading : .trailing,
                            endPoint: animateShimmer ? .trailing : .leading
                        )
                    )
                    .opacity(animateShimmer ? 0.7 : 0.3) // .opacity is iOS 13+
            )
            .onAppear { // .onAppear is iOS 13+
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    animateShimmer.toggle()
                }
            }
    }
}

// Note: The `backgroundSafeArea()` modifier, used in `EnhancedGradientBackground`, 
// is assumed to be defined elsewhere (e.g., in a `ViewModifiers.swift` file)
// and must be compatible with iOS 13 (e.g., using `edgesIgnoringSafeArea(.all)` for iOS < 14
// and `ignoresSafeArea()` for iOS 14+).
// If it was previously defined at the end of this file, it has been removed
// to avoid redeclaration errors, assuming the other definition is canonical.
