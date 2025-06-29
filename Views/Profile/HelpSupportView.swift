import SwiftUI
import MessageUI

@available(iOS 16.0, *)
struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var selectedCategory: String = ""
    @State private var searchText = ""
    @State private var showContactForm = false
    @State private var showMailComposer = false
    
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
                // Navigation Header
                premiumNavigationHeader()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header Section
                        premiumHeaderSection()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showContent)
                        
                        // Search Section
                        premiumSearchSection()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: showContent)
                        
                        // Quick Actions
                        premiumQuickActions()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showContent)
                        
                        // FAQ Categories
                        premiumFAQCategories()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: showContent)
                        
                        // Popular FAQs
                        premiumPopularFAQs()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: showContent)
                        
                        // Contact Support
                        premiumContactSupport()
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 30)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: showContent)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .sheet(isPresented: $showContactForm) {
            ContactFormView()
        }
        .sheet(isPresented: $showMailComposer) {
            if MFMailComposeViewController.canSendMail() {
                MailComposerView()
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
            
            Text("Help & Support")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
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
                                Color(red: 0.94, green: 0.58, blue: 0.98).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 60
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.58, blue: 0.98),
                                Color(red: 0.49, green: 0.34, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 12) {
                Text("How Can We Help?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Find answers to common questions, contact our support team, or get help with using FitConnect.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
    
    @ViewBuilder
    private func premiumSearchSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Help Articles")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search for help topics...", text: $searchText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func premiumQuickActions() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                premiumQuickActionCard(
                    title: "Live Chat",
                    subtitle: "Get instant help",
                    icon: "message.fill",
                    color: Color(red: 0.49, green: 0.34, blue: 1.0)
                ) {
                    // TODO: Open live chat
                }
                
                premiumQuickActionCard(
                    title: "Email Us",
                    subtitle: "Send us a message",
                    icon: "envelope.fill",
                    color: Color(red: 0.31, green: 0.78, blue: 0.47)
                ) {
                    showMailComposer = true
                }
                
                premiumQuickActionCard(
                    title: "Video Guide",
                    subtitle: "Watch tutorials",
                    icon: "play.rectangle.fill",
                    color: Color(red: 1.0, green: 0.42, blue: 0.42)
                ) {
                    // TODO: Open video guides
                }
                
                premiumQuickActionCard(
                    title: "Report Bug",
                    subtitle: "Found an issue?",
                    icon: "exclamationmark.triangle.fill",
                    color: Color(red: 1.0, green: 0.65, blue: 0.0)
                ) {
                    showContactForm = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumQuickActionCard(
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
            VStack(spacing: 12) {
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
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
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
                        RoundedRectangle(cornerRadius: 16)
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
    }
    
    @ViewBuilder
    private func premiumFAQCategories() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FAQ Categories")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(faqCategories, id: \.title) { category in
                    premiumCategoryCard(
                        title: category.title,
                        count: category.count,
                        icon: category.icon,
                        color: category.color
                    ) {
                        selectedCategory = category.title
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumCategoryCard(
        title: String,
        count: Int,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
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
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(count) articles")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 12)
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
    
    @ViewBuilder
    private func premiumPopularFAQs() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Questions")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(popularFAQs, id: \.question) { faq in
                    premiumFAQItem(question: faq.question, answer: faq.answer)
                }
            }
        }
    }
    
    @ViewBuilder
    private func premiumFAQItem(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.94, green: 0.58, blue: 0.98))
                
                Text(question)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Text(answer)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
                .padding(.leading, 28)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func premiumContactSupport() -> some View {
        VStack(spacing: 20) {
            Text("Still Need Help?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Our support team is here to help you get the most out of FitConnect.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                premiumContactButton(
                    title: "Contact Support",
                    subtitle: "Send us a detailed message",
                    icon: "envelope.fill",
                    color: Color(red: 0.49, green: 0.34, blue: 1.0)
                ) {
                    showContactForm = true
                }
                
                premiumContactButton(
                    title: "Community Forum",
                    subtitle: "Ask the FitConnect community",
                    icon: "person.3.fill",
                    color: Color(red: 0.31, green: 0.78, blue: 0.47)
                ) {
                    // TODO: Open community forum
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
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    private var faqCategories: [(title: String, count: Int, icon: String, color: Color)] {
        [
            ("Getting Started", 12, "play.circle.fill", Color(red: 0.49, green: 0.34, blue: 1.0)),
            ("Account & Profile", 8, "person.circle.fill", Color(red: 0.31, green: 0.78, blue: 0.47)),
            ("Workouts", 15, "figure.run", Color(red: 1.0, green: 0.42, blue: 0.42)),
            ("Nutrition", 10, "fork.knife", Color(red: 0.27, green: 0.64, blue: 0.71)),
            ("Privacy & Security", 6, "lock.shield.fill", Color(red: 0.94, green: 0.58, blue: 0.98)),
            ("Troubleshooting", 9, "wrench.fill", Color(red: 1.0, green: 0.65, blue: 0.0))
        ]
    }
    
    private var popularFAQs: [(question: String, answer: String)] {
        [
            (
                "How do I track my workouts?",
                "You can track workouts manually by going to the Workouts tab and tapping 'Log Workout', or connect your fitness wearables like Apple Watch for automatic tracking."
            ),
            (
                "Can I connect with a dietitian?",
                "Yes! You can browse verified dietitians in the 'My Expert' section, view their profiles, book consultations, and chat with them directly through the app."
            ),
            (
                "How do I scan meals?",
                "Use the camera scanner in the Nutrition tab. Point your camera at your meal, tap capture, and our AI will identify the food and estimate calories and macros."
            ),
            (
                "Is my data secure?",
                "Absolutely. We use industry-standard encryption and never sell your personal data. Read our Privacy Policy for complete details on how we protect your information."
            ),
            (
                "How do I change my fitness goals?",
                "Go to your Profile, tap 'Edit Profile', and update your fitness goals under the 'Fitness Preferences' section."
            )
        ]
    }
}

// MARK: - Contact Form View

@available(iOS 16.0, *)
struct ContactFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var category = "General"
    @State private var isSending = false
    @State private var showSuccess = false
    
    private let categories = ["General", "Bug Report", "Feature Request", "Account Issue", "Technical Support", "Billing"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Category")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Subject")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            TextField("Brief description of your issue", text: $subject)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Message")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $message)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .frame(height: 120)
                                    .background(Color.clear)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                
                                if message.isEmpty {
                                    Text("Please describe your issue or question in detail...")
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 20)
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Button(action: sendMessage) {
                            HStack(spacing: 12) {
                                if isSending {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                
                                Text(isSending ? "Sending..." : "Send Message")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.49, green: 0.34, blue: 1.0),
                                        Color(red: 0.31, green: 0.25, blue: 0.84)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(
                                color: Color(red: 0.49, green: 0.34, blue: 1.0).opacity(0.4),
                                radius: 12, x: 0, y: 6
                            )
                        }
                        .disabled(subject.isEmpty || message.isEmpty || isSending)
                        .opacity((subject.isEmpty || message.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                
                if showSuccess {
                    VStack {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Message sent successfully!")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.31, green: 0.78, blue: 0.47),
                                            Color(red: 0.13, green: 0.64, blue: 0.27)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(
                                    color: Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.4),
                                    radius: 12, x: 0, y: 6
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccess)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSuccess = false
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func sendMessage() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isSending = true
        
        // Simulate sending message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            showSuccess = true
            
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
        }
    }
}

// MARK: - Mail Composer

struct MailComposerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject("FitConnect Support Request")
        composer.setToRecipients(["support@fitconnect.com"])
        composer.setMessageBody("Hi FitConnect team,\n\nI need help with...", isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct HelpSupportView_Previews: PreviewProvider {
    static var previews: some View {
        HelpSupportView()
            .preferredColorScheme(.dark)
    }
}
#endif