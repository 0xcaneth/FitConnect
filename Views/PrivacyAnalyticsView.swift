import SwiftUI
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

struct PrivacyAnalyticsView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showContent = false
    @State private var appUsage = true
    @State private var workoutSuccess = true
    @State private var anonymousBehavior = true
    @State private var noPersonalInfo = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.05, blue: 0.09), 
                        Color(red: 0.10, green: 0.11, blue: 0.15)  
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack {
                            Button(action: {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) 
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, max(20, geometry.safeAreaInsets.top + 10))
                        
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0).opacity(0.3),
                                            Color(red: 0.43, green: 0.31, blue: 1.0).opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 50
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .scaleEffect(showContent ? 1.0 : 0.8)
                            
                            Image(systemName: "shield.checkerboard")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0),
                                            Color(red: 0.43, green: 0.31, blue: 1.0)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.0, green: 0.9, blue: 1.0), radius: 10, x: 0, y: 0)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Privacy & Analytics")
                                .font(.system(size: 28, weight: .semibold)) 
                                .foregroundColor(.white) 
                            
                            Text("Help us improve FitConnect while keeping your data private and secure. Your privacy is our priority.")
                                .font(.system(size: 16, weight: .regular)) 
                                .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) 
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        
                        HStack {
                            Text("What We Track")
                                .font(.system(size: 20, weight: .semibold)) 
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) 
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 16) {
                            PrivacyTrackingCard(
                                icon: "chart.pie.fill", 
                                title: "App Usage & Feature Performance",
                                subtitle: "How you use features and app performance metrics.",
                                isEnabled: $appUsage
                            )
                            
                            PrivacyTrackingCard(
                                icon: "figure.mixed.cardio", 
                                title: "Workout Success Rates & Patterns",
                                subtitle: "Workout completion and habit tracking.",
                                isEnabled: $workoutSuccess
                            )
                            
                            PrivacyTrackingCard(
                                icon: "person.3.sequence.fill", 
                                title: "Anonymous User Behavior",
                                subtitle: "Aggregated usage patterns with no personal identifiers.",
                                isEnabled: $anonymousBehavior
                            )
                            
                            PrivacyTrackingCard(
                                icon: "lock.shield.fill", 
                                title: "No Personal Information Collected",
                                subtitle: "We never collect names, emails, or personal identifiers.",
                                isEnabled: $noPersonalInfo,
                                isReadOnly: true
                            )
                            
                            IOSTrackingCard() 
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                            .frame(height: 32) 
                        
                        Button(action: handleAllowTracking) {
                            Text("Allow Tracking & Continue")
                                .font(.system(size: 18, weight: .semibold)) 
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16) 
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.0, green: 0.9, blue: 1.0), 
                                            Color(red: 0.43, green: 0.31, blue: 1.0)  
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(24) 
                        }
                        .padding(.horizontal, 40) 
                        
                        Spacer()
                            .frame(height: max(32, geometry.safeAreaInsets.bottom + 16))
                    }
                }
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6), value: showContent)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func handleAllowTracking() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        #if canImport(AppTrackingTransparency)
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    onContinue()
                }
            }
        } else {
            onContinue()
        }
        #else
        onContinue()
        #endif
    }
}

struct PrivacyTrackingCard: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool 
    let isReadOnly: Bool
    
    init(icon: String, title: String, subtitle: String, isEnabled: Binding<Bool>, isReadOnly: Bool = false) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isEnabled = isEnabled
        self.isReadOnly = isReadOnly
    }
    
    var body: some View {
        HStack(spacing: 16) { 
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.43, green: 0.31, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)], 
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44) 
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium)) 
                    .foregroundColor(.white) 
            }
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0)) 

            VStack(alignment: .leading, spacing: 4) { 
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.white) 
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) 
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if !isReadOnly {
                Image(systemName: "checkmark.circle.fill") 
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color(red: 0.43, green: 0.31, blue: 1.0)) 
            } else {
                Image(systemName: "lock.fill") 
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67))
            }
        }
        .padding(16) 
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.85)) 
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient( 
                                colors: [Color(red: 0.43, green: 0.31, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)], 
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5 
                        )
                )
        )
    }
}

struct IOSTrackingCard: View {
    var body: some View {
        HStack(spacing: 16) { 
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.43, green: 0.31, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)], 
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 44, height: 44) 
                
                Image(systemName: "hand.raised.app.fill") 
                    .font(.system(size: 20, weight: .medium)) 
                    .foregroundColor(.white) 
            }
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 0))

            VStack(alignment: .leading, spacing: 4) { 
                Text("iOS Tracking Permission")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.white) 
                    .multilineTextAlignment(.leading)
                
                Text("Tap to configure system-level tracking preferences.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) 
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.67, green: 0.67, blue: 0.67)) 
        }
        .padding(16) 
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.15).opacity(0.85)) 
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient( 
                                colors: [Color(red: 0.43, green: 0.31, blue: 1.0), Color(red: 0.0, green: 0.9, blue: 1.0)], 
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5 
                        )
                )
        )
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            #if canImport(AppTrackingTransparency)
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    DispatchQueue.main.async {
                        print("ATT status: \(status.rawValue)") 
                    }
                }
            } else {
            }
            #else
            #endif
        }
    }
}

#if DEBUG
struct PrivacyAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyAnalyticsView(onContinue: {}, onSkip: {})
            .preferredColorScheme(.dark)
    }
}
#endif
