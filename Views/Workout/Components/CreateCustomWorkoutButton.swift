import SwiftUI

struct CreateCustomWorkoutButton: View {
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon section
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                
                // Text section
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("CREATE")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Spacer()
                    }
                    
                    Text("Build Your Own")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Mix & Match Exercises")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                // Clean background without artifacts
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.8, blue: 0.2),
                                Color(red: 0.3, green: 0.7, blue: 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Subtle shimmer without artifacts
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .clear,
                                        .white.opacity(0.15),
                                        .clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: shimmerOffset)
                            .mask(RoundedRectangle(cornerRadius: 16))
                    )
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        } perform: {}
        .shadow(
            color: Color(red: 0.3, green: 0.7, blue: 0.1).opacity(0.3), 
            radius: 12, 
            x: 0, 
            y: 6
        )
        .onAppear {
            // Subtle shimmer animation
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                shimmerOffset = 300
            }
        }
    }
}

#if DEBUG
struct CreateCustomWorkoutButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CreateCustomWorkoutButton {
                print("Create Custom Workout tapped")
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 11/255, green: 13/255, blue: 23/255),
                    Color(red: 26/255, green: 27/255, blue: 37/255)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .previewLayout(.sizeThatFits)
    }
}
#endif