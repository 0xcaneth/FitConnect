import SwiftUI

struct TermsView: View {
    let onAccept: () -> Void
    let onBack: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var accepted = false
    @State private var showContent = false
    
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
                // Dark gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), // #0B0D17
                        Color(red: 0.10, green: 0.11, blue: 0.15)  // #1A1B25
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back arrow at top-left
                    HStack {
                        Button(action: {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) // #6E4EFF
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                    .padding(.bottom, 20)
                    
                    // Title
                    Text("Terms & Conditions")
                        .font(.system(size: 28, weight: .semibold)) // SF Pro Semibold 28pt
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("Please review our terms carefully before continuing.")
                        .font(.system(size: 16, weight: .regular)) // SF Pro Regular 16pt
                        .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) // #AAAAAA
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(parsedSections(), id: \.title) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    // Section heading
                                    Text(section.title)
                                        .font(.system(size: 20, weight: .semibold)) // SF Pro Semibold 20pt
                                        .foregroundColor(.white)
                                    
                                    // Paragraph text
                                    Text(section.content)
                                        .font(.system(size: 14, weight: .regular)) // SF Pro Regular 14pt
                                        .foregroundColor(Color(red: 0.8, green: 0.8, blue: 0.8)) // #CCCCCC
                                        .lineSpacing(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                                
                                // Thin horizontal divider
                                if section.title != parsedSections().last?.title {
                                    Rectangle()
                                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2)) // #333333
                                        .frame(height: 1)
                                        .padding(.horizontal, 24)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                    }
                    
                    // Bottom section with checkbox and button
                    VStack(spacing: 20) {
                        // Checkbox row
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    accepted.toggle()
                                }
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Image(systemName: accepted ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(accepted ? Color(red: 0.43, green: 0.31, blue: 1.0) : Color.gray) // #6E4EFF when checked
                            }
                            
                            Text("I have read and agree to the Terms & Conditions")
                                .font(.system(size: 14, weight: .regular)) // SF Pro Regular 14pt
                                .foregroundColor(.white) // #FFFFFF
                            
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        // Continue button - only works if checkbox is checked
                        Button(action: {
                            if accepted {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                onAccept()
                            }
                        }) {
                            Text("Continue to Login")
                                .font(.system(size: 18, weight: .semibold)) // SF Pro Semibold 18pt
                                .foregroundColor(accepted ? .white : Color(red: 0.6, green: 0.6, blue: 0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    accepted ?
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0), // #00E5FF
                                            Color(red: 0.43, green: 0.31, blue: 1.0)  // #6E4EFF
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray, Color.gray],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(24) // 24pt corner radius
                        }
                        .disabled(!accepted)
                        .padding(.horizontal, 24)
                        .shadow(
                            color: accepted ? Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.3) : Color.clear,
                            radius: 15, x: 0, y: 8
                        )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 16))
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.8), value: showContent)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
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
