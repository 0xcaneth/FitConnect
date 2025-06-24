import SwiftUI

struct HealthKitAccessCard: View {
    let onEnableTap: () -> Void
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            HStack(spacing: 16) {
                // Health icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color(hex: "#FF7E1E"), Color(hex: "#FF4154")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text("HealthKit access needed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Enable to see your live health data")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#D0D0D0"))
                }
                
                Spacer()
                
                // Enable button
                Button(action: {
                    onEnableTap()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Text("Enable")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "#FF7E1E"), Color(hex: "#FF4154")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(20)
            .background(Color(hex: "#1A1A1A"))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color(hex: "#FF7E1E"), Color(hex: "#FF4154")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color(hex: "#FF7E1E").opacity(0.15), radius: 20, x: 0, y: 0)
            .padding(.horizontal, 16)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .top)),
                removal: .opacity.combined(with: .move(edge: .top).combined(with: .offset(y: -20)))
            ))
        }
    }
}