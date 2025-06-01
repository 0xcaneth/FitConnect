import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        GlassCard { // Using GlassCard for consistent styling
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(FitConnectColors.accentCyan) // Using direct accentCyan
                
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
            .frame(width: 140, height: 120) // Adjust frame as needed
        }
    }
}

struct FeatureCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            EnhancedGradientBackground()
            HStack {
                FeatureCard(icon: "figure.run", title: "Workouts", subtitle: "Start training")
                FeatureCard(icon: "fork.knife", title: "Nutrition", subtitle: "Track meals")
            }
        }
        .preferredColorScheme(.dark)
    }
}
