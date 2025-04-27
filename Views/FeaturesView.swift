// Views/FeaturesView.swift
import SwiftUI

struct FeaturesView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Aynı Splash’te kullandığımız gradyan
                LinearGradient(
                    gradient: Gradient(colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()
                    Text("Welcome to FitConnect")
                        .font(.largeTitle).bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    FeatureRow(icon: "eye.fill",
                               title: "Food Vision AI",
                               subtitle: "Analyze meals just by snapping a photo.")
                    FeatureRow(icon: "chart.bar.fill",
                               title: "Nutrition Stats",
                               subtitle: "Track macros & calories over time.")
                    FeatureRow(icon: "video.fill",
                               title: "Workout Clips",
                               subtitle: "Share short videos with your trainer.")

                    Spacer()

                    // Burada NavigationLink ile TermsView’e geçiyoruz
                    NavigationLink {
                        TermsView()
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color("PrimaryGradientStart"))
                            .cornerRadius(10)
                            .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct FeaturesView_Previews: PreviewProvider {
    static var previews: some View {
        FeaturesView()
    }
}
