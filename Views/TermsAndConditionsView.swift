import SwiftUI

@available(iOS 16.0, *)
struct TermsConditionsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var hasReadTerms = false
    @State private var agreedToTerms = false
    
    var body: some View {
        ZStack {
            Color(hex: "#0D0F14")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Content
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Terms & Conditions")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Please review our terms carefully before continuing.")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Scrollable Terms Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            TermsSection(
                                title: "Introduction",
                                content: "Welcome to FitConnect (\"we,\" \"our,\" \"us\"). By downloading or using our app, you agree to these Terms. If you do not agree, please do not use the app."
                            )
                            
                            TermsSection(
                                title: "Acceptance of Terms",
                                content: "By accessing FitConnect, you confirm that:",
                                bulletPoints: [
                                    "You are at least 18 years old (or of legal age in your jurisdiction).",
                                    "You will comply with all local laws regarding app usage.",
                                    "You have read, understood, and accepted these Terms."
                                ]
                            )
                            
                            TermsSection(
                                title: "Account Registration",
                                content: "To create an account, you must provide a valid email address and choose a secure password. You are responsible for keeping your login credentials confidential."
                            )
                            
                            TermsSection(
                                title: "User Conduct",
                                content: "You agree not to misuse the app, post offensive content, or violate any applicable laws. Any violation may result in account termination."
                            )
                            
                            TermsSection(
                                title: "Termination",
                                content: "Either party may terminate this agreement at any time. Upon termination, your access will cease and data may be deleted according to our retention policy."
                            )
                            
                            TermsSection(
                                title: "Contact Us",
                                content: "Questions about these Terms? Email us at support@fitconnectapp.com or visit our website for more information."
                            )
                        }
                        .padding(.horizontal, 20)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                hasReadTerms = true
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    
                    // Bottom Section
                    VStack(spacing: 16) {
                        // Custom checkbox for terms agreement
                        HStack(spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "#00E0FF") ?? .cyan,
                                                    Color(hex: "#6A00FF") ?? .purple
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 2
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(agreedToTerms ? Color(hex: "#7C3AED") ?? .purple : Color(hex: "#1E1E1E") ?? .clear)
                                        )
                                        .frame(width: 20, height: 20)
                                    
                                    if agreedToTerms {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            
                            Text("I have read and agree to the Terms & Conditions")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        GradientButton(
                            title: "Continue to Login",
                            action: {
                                UserDefaults.standard.set(true, forKey: "TermsAccepted")
                                onContinue()
                            },
                            isEnabled: agreedToTerms
                        )
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    var bulletPoints: [String] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
            
            if !bulletPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(bulletPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(point)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)
                        }
                    }
                }
                .padding(.leading, 16)
            }
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct TermsConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsConditionsView(
            onContinue: {},
            onBack: {}
        )
        .preferredColorScheme(.dark)
    }
}
#endif
