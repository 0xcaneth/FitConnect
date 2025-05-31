import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        UnifiedCard {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(FitConnectColors.accentColor)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(FitConnectFonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text(subtitle)
                        .font(FitConnectFonts.caption)
                        .foregroundColor(FitConnectColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 140, height: 120)
        }
    }
}
