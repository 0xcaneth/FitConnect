import SwiftUI

struct TermsView: View {
    let onAccept: () -> Void
    let onBack: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var accepted = false
    @State private var showContent = false
    @State private var buttonGlow = false
    
    // Clean legal text without ** characters
    private let termsText = """
Introduction
Welcome to FitConnect ("we," "our," "us"). By downloading or using our app, you agree to these Terms. If you do not agree, please do not use the app.

Acceptance of Terms
By accessing FitConnect, you confirm that:
• You are at least 18 years old (or of legal age in your jurisdiction).
• You will comply with all local laws regarding app usage.
• You have read, understood, and accepted these Terms.

Account Registration
To create an account, you must provide a valid email address and choose a secure password. You are responsible for keeping your login credentials confidential.

User Conduct
You agree not to misuse the app, post offensive content, or violate any applicable laws. Any violation may result in account termination.

Termination
Either party may terminate this agreement at any time. Upon termination, your access will cease and data may be deleted according to our retention policy.

Contact Us
Questions about these Terms? Email us at support@fitconnectapp.com or visit our website for more information.
"""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium dark gradient background matching HomeView
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
                    // Custom Navigation Header
                    VStack(spacing: 10) {
                        // Back Button
                        HStack {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                onBack()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(hex: "#6E56E9") ?? .purple)
                            }
                            .padding(.leading, 24)
                            
                            Spacer()
                        }
                        .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                        
                        // Title and Subtitle
                        VStack(spacing: 10) {
                            Text("Terms & Conditions")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("Please review our terms carefully before continuing")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 24)
                    
                    // Content Container - Scrollable Card
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(parsedSections(), id: \.title) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Section heading
                                    Text(section.title)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    // Paragraph text
                                    Text(section.content)
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineSpacing(4)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Subtle divider
                                if section.title != parsedSections().last?.title {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "#212329") ?? Color.black.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(hex: "#6E56E9").opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .frame(maxHeight: geometry.size.height * 0.5)
                    
                    Spacer()
                    
                    // Agreement Section
                    VStack(spacing: 24) {
                        // Custom Checkbox Row
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    accepted.toggle()
                                }
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                
                                // Trigger button glow when checkbox is enabled
                                if accepted {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        buttonGlow = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        buttonGlow = false
                                    }
                                }
                            }) {
                                ZStack {
                                    // Checkbox background
                                    Circle()
                                        .fill(accepted ? Color(hex: "#6E56E9") ?? .purple : Color.clear)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color(hex: "#6E56E9") ?? .purple, lineWidth: 2)
                                        )
                                    
                                    // Checkmark
                                    if accepted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("I have read and agree to the Terms & Conditions")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Continue Button
                        Button(action: {
                            if accepted {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                onAccept()
                            }
                        }) {
                            Text("Continue to Login")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accepted ? .white : .white.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    Group {
                                        if accepted {
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "#3ABCE0") ?? .cyan,
                                                    Color(hex: "#805ED6") ?? .purple
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
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .overlay(
                                    // Pulsing glow effect when button becomes active
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(hex: "#3ABCE0") ?? .cyan,
                                                    Color(hex: "#805ED6") ?? .purple
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: buttonGlow ? 2 : 0
                                        )
                                        .scaleEffect(buttonGlow ? 1.05 : 1.0)
                                        .opacity(buttonGlow ? 0.8 : 0)
                                )
                        }
                        .disabled(!accepted)
                        .padding(.horizontal, 24)
                        .shadow(
                            color: accepted ? Color(hex: "#3ABCE0").opacity(0.3) : Color.clear,
                            radius: 15, x: 0, y: 8
                        )
                    }
                    .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 16))
                }
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: showContent)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    private func parsedSections() -> [(title: String, content: String)] {
        let sections = termsText.components(separatedBy: "\n\n")
        var result: [(title: String, content: String)] = []
        
        for section in sections {
            let lines = section.components(separatedBy: "\n")
            if let firstLine = lines.first, !firstLine.isEmpty {
                let title = firstLine
                let content = lines.dropFirst().joined(separator: "\n")
                result.append((title: title, content: content))
            }
        }
        
        return result
    }
}

#if DEBUG
struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView(onAccept: {}, onBack: {})
            .preferredColorScheme(.dark)
    }
}
#endif
