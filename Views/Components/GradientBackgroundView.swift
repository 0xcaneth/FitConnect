import SwiftUI

struct GradientBackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base dark background
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Animated gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3), // Deep indigo
                    Color(red: 0.0, green: 0.2, blue: 0.3), // Dark teal
                    Color(red: 0.05, green: 0.15, blue: 0.25) // Mixed blue
                ],
                startPoint: animateGradient ? .topLeading : .topTrailing,
                endPoint: animateGradient ? .bottomTrailing : .bottomLeading
            )
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Subtle texture overlay - compatible with iOS 13+
            Rectangle()
                .fill(Color.white.opacity(0.02))
                .edgesIgnoringSafeArea(.all)
        }
    }
}
