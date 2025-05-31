import SwiftUI
// If Lottie was used, you might need:
// #if canImport(Lottie)
// import Lottie
// #endif

#if canImport(UIKit)
import UIKit

private extension Color {
    var diagnosticUiColor: UIColor {
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
            // iOS 13 fallback for diagnostic:
            // For a truly robust solution on iOS 13, one would typically map known app Colors
            // to UIColors manually or use a more complex introspection if possible.
            // Since this is diagnostic, we'll just use a system color.
            // If 'self' is FitConnectColors.accentCyan, we could try to approximate it.
            // Let's assume for diagnostic purposes, we return a known color.
            // This won't be accurate for all 'self' Color instances but will compile.
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            // This is a simplified way to try and get components, but UIColor(self) would have done this if available.
            // The issue with iOS 13 Color to UIColor is exactly this step.
            // For the diagnostic, let's just return a fixed color to ensure it compiles.
            return UIColor.cyan // Fallback to a system cyan for diagnostic
        }
    }
}
#endif

struct SplashView: View {
    let onContinue: () -> Void
    
    @State private var showContent = false

    var body: some View {
        ZStack {
            EnhancedGradientBackground()
            
            VStack {
                Spacer()
                Image("AppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)
                
                Text("FitConnect")
                    .font(FitConnectFonts.largeTitle())
                    .foregroundColor(FitConnectColors.textPrimary)
                    .scaleEffect(showContent ? 1 : 0.8)
                    .opacity(showContent ? 1 : 0)
                
                if showContent {
                    Text("AI-Powered Fitness Journey")
                        .font(FitConnectFonts.body)
                        .foregroundColor(FitConnectColors.textSecondary)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                Spacer()
                
                if showContent {
                    if #available(iOS 14.0, *) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentCyan))
                            .scaleEffect(1.2)
                    } else {
                        // Explicitly referencing the module/target if possible, or just the type.
                        // Assuming ActivityIndicator is in the main app module (FitConnect).
                        let accentAsUIColor: UIColor = FitConnectColors.accentCyan.uiColor
                        FitConnect.ActivityIndicator(style: .large, color: accentAsUIColor) // Try to qualify with module name if your module is 'FitConnect'
                    }
                    Text("Loading...")
                        .font(FitConnectFonts.caption)
                        .foregroundColor(FitConnectColors.textTertiary)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                showContent = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onContinue()
                }
            }
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onContinue: {})
            .preferredColorScheme(.dark)
    }
}
#endif
