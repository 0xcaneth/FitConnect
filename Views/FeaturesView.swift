// Views/FeaturesView.swift
import SwiftUI

// Ensure FitConnectFonts and FitConnectColors are defined here or accessible
// Ensure UnifiedBackground, UnifiedPrimaryButton, and UnifiedCard are defined here or accessible

struct FeaturesView: View {
    let onNext: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Unified Background
            UnifiedBackground()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main Title
                Text("Features")
                    .font(FitConnectFonts.largeTitle())
                    .foregroundColor(FitConnectColors.textPrimary)
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1.0 : 0.0)
                
                // Feature Cards
                VStack(spacing: 20) {
                    ForEach(featureItems.indices, id: \.self) { index in
                        UnifiedFeatureCard(
                            icon: featureItems[index].icon,
                            title: featureItems[index].title
                        )
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(x: showContent ? 0 : -50)
                        .animation(
                            .easeOut(duration: 0.6).delay(Double(index) * 0.2),
                            value: showContent
                        )
                    }
                }
                
                Spacer()
                
                // Continue Button
                UnifiedPrimaryButton("Continue") {
                    onNext()
                }
                .opacity(showContent ? 1.0 : 0.0)
                .padding(.horizontal, 32)
                
                Spacer().frame(height: 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Unified Feature Card Component
struct UnifiedFeatureCard: View {
    let icon: String
    let title: String
    
    var body: some View {
        UnifiedCard {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(FitConnectColors.accentColor)
                    .frame(width: 40, height: 40)
                
                // Title
                Text(title)
                    .font(FitConnectFonts.body)
                    .foregroundColor(FitConnectColors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Data Model
struct FeatureItem {
    let icon: String
    let title: String
}

let featureItems: [FeatureItem] = [
    FeatureItem(icon: "eye.fill", title: "Snap your meal instantly"),
    FeatureItem(icon: "chart.bar.fill", title: "Track your macros"),
    FeatureItem(icon: "video.fill", title: "Share workout clips")
]
