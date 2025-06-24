import SwiftUI
import GoogleSignIn

struct GoogleSignInButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Continue with Google")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "#00E0FF") ?? .cyan,
                                Color(hex: "#6A00FF") ?? .purple
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
        }
    }
}
