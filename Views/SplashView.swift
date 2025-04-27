// Views/SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var subtitleOpacity: Double = 0.0
    @State private var isActive = false

    var body: some View {
        Group {
            if isActive {
                FeaturesView()   // geçiş yapılacak ekran
            } else {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 16) {
                        Image("AppIcon")   // Assets’te tanımlı küçük ikon
                            .resizable()
                            .frame(width: 80, height: 80)
                            .scaleEffect(logoScale)
                            .onAppear {
                                withAnimation(.easeOut(duration: 1.0)) {
                                    logoScale = 1.0
                                }
                            }

                        Text("FitConnect")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your journey to a healthier you starts now")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(subtitleOpacity)
                            .onAppear {
                                withAnimation(.easeIn.delay(1.0)) {
                                    subtitleOpacity = 1.0
                                }
                            }

                        Spacer().frame(height: 40)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    .padding(.horizontal, 32)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
