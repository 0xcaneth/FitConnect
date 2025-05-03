// Views/FeaturesView.swift
import SwiftUI

struct FeaturesView: View {
  let onNext: () -> Void

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 32) {
        Spacer()

        Text("Features")
          .font(.largeTitle).bold()
          .foregroundColor(.white)

        VStack(spacing: 16) {
          FeatureBullet(icon: "eye.fill",    title: "Snap your meal instantly")
          FeatureBullet(icon: "chart.bar.fill", title: "Track your macros")
          FeatureBullet(icon: "video.fill",  title: "Share workout clips")
        }
        .padding(.horizontal, 32)

        Spacer()

        Button(action: onNext) {
          Text("Continue")
            .bold()
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .foregroundColor(Color("PrimaryGradientStart"))
            .cornerRadius(10)
        }
        .padding(.horizontal, 32)

        Spacer()
      }
    }
  }
}

private struct FeatureBullet: View {
  let icon: String, title: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundColor(.white)
      Text(title)
        .foregroundColor(.white)
    }
  }
}
