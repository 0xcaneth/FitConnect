import SwiftUI

struct TermsView: View {
    let onAccept: () -> Void
    let onBack: () -> Void
    
    @State private var accepted = false
    @State private var showContent = false
    
    private let termsText = """
By using FitConnect's AI-powered features, you accept that results may not always be entirely accurate. Our meal scanning, workout recommendations, and health insights are meant to assist you in your fitness journey, but should not replace professional medical or nutritional advice.

Data Privacy: Your personal health data, photos, and workout information are encrypted and stored securely. We do not share your personal information with third parties without your explicit consent.

Accuracy Disclaimer: While our AI strives for accuracy in meal analysis and fitness recommendations, results may vary. Always consult with healthcare professionals for personalized advice.

Usage Guidelines: FitConnect is designed for individuals 18 and older. Use of our services implies acceptance of these terms and our commitment to helping you achieve your fitness goals safely and effectively.

By continuing, you acknowledge that you understand these terms and agree to use FitConnect responsibly as part of a balanced approach to health and fitness.

Additional Terms: Your use of FitConnect's premium features, including personalized coaching and advanced analytics, is subject to our subscription terms. You may cancel your subscription at any time through your device's settings.

Health Disclaimer: FitConnect is not a medical device and should not be used to diagnose, treat, cure, or prevent any disease. Always consult with qualified healthcare professionals before making significant changes to your diet or exercise routine.

Community Guidelines: When sharing content within FitConnect, please be respectful and supportive of other users. Harassment, inappropriate content, or spam will result in account suspension.

Updates: These terms may be updated periodically. Continued use of the app after changes indicates acceptance of revised terms.
"""
    
    var body: some View {
        ZStack {
            // Unified Background
            UnifiedBackground()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FitConnectColors.textPrimary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Title
                Text("Terms & Conditions")
                    .font(FitConnectFonts.largeTitle())
                    .foregroundColor(FitConnectColors.textPrimary)
                    .padding(.top, 16)
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1.0 : 0.0)
                
                // Content with sticky footer
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Scrollable terms text
                        ScrollView {
                            VStack(spacing: 20) {
                                UnifiedCard {
                                    Text(termsText)
                                        .font(FitConnectFonts.body)
                                        .foregroundColor(FitConnectColors.textPrimary)
                                        .lineSpacing(4)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                
                                // Extra padding to ensure content is scrollable above footer
                                Spacer().frame(height: 120)
                            }
                        }
                        
                        // Sticky Footer
                        VStack(spacing: 16) {
                            // Divider
                            Rectangle()
                                .fill(FitConnectColors.textTertiary)
                                .frame(height: 1)
                            
                            // Toggle with iOS compatibility
                            HStack {
                                if #available(iOS 14.0, *) {
                                    Toggle("I agree to the Terms & Conditions", isOn: $accepted)
                                        .font(FitConnectFonts.body)
                                        .foregroundColor(FitConnectColors.textPrimary)
                                        .toggleStyle(SwitchToggleStyle(tint: FitConnectColors.accentColor))
                                } else {
                                    Toggle("I agree to the Terms & Conditions", isOn: $accepted)
                                        .font(FitConnectFonts.body)
                                        .foregroundColor(FitConnectColors.textPrimary)
                                        .accentColor(FitConnectColors.accentColor)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Accept Button
                            UnifiedPrimaryButton("Accept & Continue") {
                                onAccept()
                            }
                            .disabled(!accepted)
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 34)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(FitConnectColors.gradientBottom.opacity(0.95))
                                .blur(radius: 20)
                        )
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}
