import SwiftUI
import FirebaseAuth

struct HomeDashboardView: View {
    @EnvironmentObject private var session: SessionStore
    @Binding var selectedTab: AppTab
    @State private var userName: String = ""
    @State private var isLoadingName = true
    @State private var showContent = false
    
    let onLogout: () -> Void
    
    var body: some View {
        ZStack {
            // Unified Background
            UnifiedBackground()
            
            VStack(spacing: 0) {
                // Header with logout button
                HStack {
                    Spacer()
                    
                    Button(action: onLogout) {
                        Image(systemName: "power")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(FitConnectColors.textPrimary)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(FitConnectColors.cardBackground)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Welcome Header
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                AvatarView(initials: String(userName.first ?? "U"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome,")
                                        .font(FitConnectFonts.body)
                                        .foregroundColor(FitConnectColors.textSecondary)
                                    
                                    Text(userName)
                                        .font(FitConnectFonts.largeTitle())
                                        .foregroundColor(FitConnectColors.textPrimary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : -20)
                        
                        // Feature Cards
                        VStack(spacing: 16) {
                            ForEach(homeFeatures.indices, id: \.self) { index in
                                UnifiedHomeFeatureCard(
                                    icon: homeFeatures[index].icon,
                                    title: homeFeatures[index].title,
                                    subtitle: homeFeatures[index].subtitle
                                )
                                .opacity(showContent ? 1.0 : 0.0)
                                .offset(x: showContent ? 0 : -30)
                                .animation(
                                    .easeOut(duration: 0.6).delay(Double(index) * 0.1 + 0.3),
                                    value: showContent
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Quick Actions
                        VStack(spacing: 16) {
                            Text("Quick Actions")
                                .font(FitConnectFonts.body)
                                .foregroundColor(FitConnectColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                            
                            HStack(spacing: 12) {
                                UnifiedQuickAction(icon: "plus", title: "Add Workout") {}
                                UnifiedQuickAction(icon: "drop.fill", title: "Log Water") {}
                                UnifiedQuickAction(icon: "bed.double", title: "Log Sleep") {}
                            }
                            .padding(.horizontal, 24)
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            loadUserName()
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
    
    private func loadUserName() {
        guard let user = session.currentUser else {
            userName = "User"
            isLoadingName = false
            return
        }
        
        if !user.fullName.isEmpty {
            userName = user.fullName
        } else if !user.email.isEmpty {
            userName = user.email.components(separatedBy: "@").first ?? "User"
        } else {
            userName = "User"
        }
        isLoadingName = false
    }
}

// MARK: - Unified Home Feature Card Component
struct UnifiedHomeFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        UnifiedCard {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(FitConnectColors.accentColor)
                    .frame(width: 50, height: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FitConnectFonts.body)
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text(subtitle)
                        .font(FitConnectFonts.caption)
                        .foregroundColor(FitConnectColors.textSecondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
        }
    }
}

// MARK: - Unified Quick Action Component
struct UnifiedQuickAction: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(FitConnectColors.accentColor)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FitConnectColors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models
struct HomeFeature {
    let icon: String
    let title: String
    let subtitle: String
}

let homeFeatures: [HomeFeature] = [
    HomeFeature(icon: "figure.run", title: "Workouts", subtitle: "Start training"),
    HomeFeature(icon: "fork.knife", title: "Nutrition", subtitle: "Track meals"),
    HomeFeature(icon: "chart.bar.fill", title: "Progress", subtitle: "See stats")
]
