import SwiftUI

struct GradientButton: View {
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var height: CGFloat = 56
    var cornerRadius: CGFloat = 28
    
    private var gradientColors: [Color] {
        if isEnabled {
            return [Color(hex: "#00E0FF") ?? .cyan, Color(hex: "#6A00FF") ?? .purple]
        } else {
            return [Color(hex: "#3A3A3A") ?? .gray, Color(hex: "#3A3A3A") ?? .gray]
        }
    }
    
    var body: some View {
        Button(action: isEnabled ? action : {}) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(cornerRadius)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientButton(title: "Continue", action: {})
        GradientButton(title: "Loading...", action: {}, isLoading: true)
        GradientButton(title: "Disabled", action: {}, isEnabled: false)
    }
    .padding()
    .background(Color.black)
}