// Views/SplashView.swift
import SwiftUI
import FirebaseCore        // FirebaseApp.configure() için
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanız



struct SplashView: View {
  let onContinue: () -> Void

  @State private var logoScale: CGFloat = 0.6
  @State private var subtitleOpacity: Double = 0

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 24) {
        Spacer()

        Image("AppIcon")
          .resizable()
          .frame(width: 100, height: 100)
          .scaleEffect(logoScale)
          .onAppear {
            withAnimation(.easeOut(duration: 1)) {
              logoScale = 1
            }
          }

        Text("FitConnect")
          .font(.system(size: 36, weight: .bold))
          .foregroundColor(.white)

        Text("Your journey to a healthier you starts now")
          .foregroundColor(.white.opacity(0.8))
          .multilineTextAlignment(.center)
          .opacity(subtitleOpacity)
          .padding(.horizontal, 32)
          .onAppear {
            withAnimation(.easeIn.delay(1)) {
              subtitleOpacity = 1
            }
          }

        Spacer()

        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .white))

        Spacer().frame(height: 40)
      }
      .padding()
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        onContinue()
      }
    }
  }
}
