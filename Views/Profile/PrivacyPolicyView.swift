import SwiftUI

@available(iOS 16.0, *)
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var scrollOffset: CGFloat = 0
    @State private var readingProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.06, blue: 0.08),
                    Color(red: 0.10, green: 0.11, blue: 0.15),
                    Color(red: 0.12, green: 0.13, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header with Progress
                premiumNavigationHeader()
                
                // Reading Progress Bar
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.49, green: 0.34, blue: 1.0),
                                    Color(red: 0.31, green: 0.25, blue: 0.84)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * readingProgress, height: 4)
                        .animation(.easeOut(duration: 0.3), value: readingProgress)
                }
                .frame(height: 4)
                .background(Color.white.opacity(0.1))
                
                // Content
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            VStack(spacing: 32) {
                                // Header Section
                                premiumHeaderSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                                
                                // Privacy Policy Sections
                                ForEach(Array(privacySections.enumerated()), id: \.offset) { index, section in
                                    premiumPrivacySection(
                                        title: section.title,
                                        content: section.content,
                                        icon: section.icon,
                                        color: section.color
                                    )
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(0.2 + Double(index) * 0.1),
                                        value: showContent
                                    )
                                    .id(index)
                                }
                                
                                // Contact Section
                                premiumContactSection()
                                    .opacity(showContent ? 1.0 : 0.0)
                                    .offset(y: showContent ? 0 : 30)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: showContent)
                                
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: geo.frame(in: .named("scroll")).minY) { newValue in
                                            updateReadingProgress(scrollOffset: newValue, contentHeight: geo.size.height)
                                        }
                                }
                            )
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    @ViewBuilder
    private func premiumNavigationHeader() -> some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Privacy Policy")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("\(Int(readingProgress * 100))% read")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
            }
            .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private func premiumHeaderSection() -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.27, green: 0.64, blue: 0.71).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.27, green: 0.64, blue: 0.71),
                                Color(red: 0.49, green: 0.34, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("Your Privacy Matters")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("We're committed to protecting your personal information and being transparent about how we collect, use, and share your data.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            HStack(spacing: 16) {
                premiumInfoBadge(title: "Last Updated", value: "Dec 28, 2024")
                premiumInfoBadge(title: "Version", value: "2.1")
            }
        }
    }
    
    @ViewBuilder
    private func premiumInfoBadge(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func premiumPrivacySection(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(6)
                .padding(.leading, 52)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    @ViewBuilder
    private func premiumContactSection() -> some View {
        VStack(spacing: 20) {
            Text("Questions or Concerns?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("If you have any questions about this Privacy Policy or our data practices, please contact us:")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            VStack(spacing: 12) {
                premiumContactButton(
                    title: "Email Support",
                    subtitle: "privacy@fitconnect.com",
                    icon: "envelope.fill",
                    color: Color(red: 0.49, green: 0.34, blue: 1.0)
                ) {
                    // TODO: Open email client
                }
                
                premiumContactButton(
                    title: "Data Protection Officer",
                    subtitle: "dpo@fitconnect.com",
                    icon: "person.badge.shield.checkmark",
                    color: Color(red: 0.31, green: 0.78, blue: 0.47)
                ) {
                    // TODO: Open email client
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func premiumContactButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.2),
                                    color.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 25
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
    
    private func updateReadingProgress(scrollOffset: CGFloat, contentHeight: CGFloat) {
        let progress = min(max((-scrollOffset) / max(contentHeight - UIScreen.main.bounds.height, 1), 0), 1)
        readingProgress = progress
    }
    
    private var privacySections: [(title: String, content: String, icon: String, color: Color)] {
        [
            (
                title: "Information We Collect",
                content: "We collect information you provide directly to us, such as when you create an account, update your profile, or use our services. This includes your name, email address, fitness data, health metrics, and workout information. We also automatically collect certain information about your device and usage patterns to improve our services.",
                icon: "doc.text.magnifyingglass",
                color: Color(red: 0.49, green: 0.34, blue: 1.0)
            ),
            (
                title: "How We Use Your Information",
                content: "We use your information to provide, maintain, and improve our services, personalize your experience, communicate with you, ensure security, and comply with legal obligations. Your health and fitness data helps us provide personalized recommendations and track your progress toward your goals.",
                icon: "gearshape.2",
                color: Color(red: 0.31, green: 0.78, blue: 0.47)
            ),
            (
                title: "Information Sharing",
                content: "We do not sell your personal information. We may share your information with service providers, business partners, or as required by law. When you choose to connect with dietitians or share content publicly, that information becomes visible to other users as you've designated.",
                icon: "person.2.fill",
                color: Color(red: 1.0, green: 0.42, blue: 0.42)
            ),
            (
                title: "Data Security",
                content: "We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. This includes encryption of sensitive data, secure data transmission, and regular security assessments.",
                icon: "lock.shield",
                color: Color(red: 0.27, green: 0.64, blue: 0.71)
            ),
            (
                title: "Your Rights",
                content: "You have the right to access, update, or delete your personal information. You can also opt out of certain communications, request data portability, and restrict processing of your data. Contact us to exercise these rights or if you have questions about your data.",
                icon: "hand.raised.fill",
                color: Color(red: 0.94, green: 0.58, blue: 0.98)
            ),
            (
                title: "Cookies and Tracking",
                content: "We use cookies and similar technologies to enhance your experience, analyze usage patterns, and provide personalized content. You can control cookie preferences through your browser settings, though some features may not function properly if cookies are disabled.",
                icon: "network",
                color: Color(red: 1.0, green: 0.65, blue: 0.0)
            ),
            (
                title: "International Transfers",
                content: "Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your information in accordance with applicable data protection laws.",
                icon: "globe",
                color: Color(red: 0.31, green: 0.25, blue: 0.84)
            ),
            (
                title: "Changes to This Policy",
                content: "We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy on our app and updating the 'Last Updated' date. Your continued use of our services after changes become effective constitutes acceptance of the updated policy.",
                icon: "arrow.clockwise",
                color: Color(red: 0.54, green: 0.50, blue: 0.97)
            )
        ]
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
            .preferredColorScheme(.dark)
    }
}
#endif