import SwiftUI

struct PrivacyAnalyticsView: View {
    @State private var showContent = false
    @State private var showPermissionSheet = false
    @State private var checkedItems: Set<Int> = []
    
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            // Unified Background
            UnifiedBackground()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)
                    
                    // Header Section
                    VStack(spacing: 16) {
                        Text("Privacy & Analytics")
                            .font(FitConnectFonts.largeTitle())
                            .foregroundColor(FitConnectColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .scaleEffect(showContent ? 1.0 : 0.9)
                            .opacity(showContent ? 1.0 : 0.0)
                        
                        Text("Help us improve FitConnect while keeping your data private.")
                            .font(FitConnectFonts.body)
                            .foregroundColor(FitConnectColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(showContent ? 1.0 : 0.0)
                            .padding(.horizontal, 16)
                    }
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                    
                    // Tracking List Section
                    VStack(spacing: 16) {
                        ForEach(trackingItems.indices, id: \.self) { index in
                            UnifiedTrackedItemRow(
                                item: trackingItems[index],
                                isChecked: checkedItems.contains(index)
                            )
                            .opacity(showContent ? 1.0 : 0.0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.4 + Double(index) * 0.1), value: showContent)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Permission Card
                    UnifiedPermissionCard {
                        showPermissionSheet = true
                    }
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)
                    .padding(.horizontal, 24)
                    
                    // CTA Buttons
                    VStack(spacing: 16) {
                        UnifiedPrimaryButton("Allow Tracking") {
                            onContinue()
                        }
                        
                        Button("Skip for Now") {
                            onSkip()
                        }
                        .font(FitConnectFonts.body)
                        .foregroundColor(FitConnectColors.textTertiary)
                    }
                    .opacity(showContent ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: showContent)
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
            animateCheckmarks()
        }
        .sheet(isPresented: $showPermissionSheet) {
            PermissionSheetView()
        }
    }
    
    private func animateCheckmarks() {
        for i in 0..<trackingItems.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    _ = checkedItems.insert(i)
                }
            }
        }
    }
}

// MARK: - Updated Components with Unified Design
struct UnifiedTrackedItemRow: View {
    let item: TrackingItem
    let isChecked: Bool
    
    var body: some View {
        UnifiedCard {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(item.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(FitConnectFonts.body)
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text(item.description)
                        .font(FitConnectFonts.caption)
                        .foregroundColor(FitConnectColors.textSecondary)
                }
                
                Spacer()
                
                // Checkmark
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .scaleEffect(isChecked ? 1.0 : 0.0)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(isChecked ? 1.0 : 0.0)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isChecked)
            }
        }
    }
}

struct UnifiedPermissionCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            UnifiedCard {
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(FitConnectColors.accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(FitConnectColors.accentColor)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tracking Permission")
                            .font(FitConnectFonts.body)
                            .foregroundColor(FitConnectColors.textPrimary)
                        
                        Text("Tap to set your preference")
                            .font(FitConnectFonts.caption)
                            .foregroundColor(FitConnectColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Arrow
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Data remains the same
struct TrackingItem {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

let trackingItems: [TrackingItem] = [
    TrackingItem(
        title: "App Usage & Performance",
        description: "How you interact with features",
        icon: "chart.line.uptrend.xyaxis",
        color: .green
    ),
    TrackingItem(
        title: "Goal Completion Patterns",
        description: "Anonymous progress insights",
        icon: "target",
        color: .blue
    ),
    TrackingItem(
        title: "Anonymous Usage Insights",
        description: "Aggregated user behavior",
        icon: "eye.fill",
        color: .purple
    ),
    TrackingItem(
        title: "No Personal Data Collected",
        description: "Your privacy is protected",
        icon: "shield.checkered",
        color: .red
    )
]
