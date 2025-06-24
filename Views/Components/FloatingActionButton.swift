import SwiftUI

struct FloatingActionButton: View {
    @Binding var isExpanded: Bool
    let onLogMealTap: () -> Void
    let onStartWorkoutTap: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Mini buttons
            if isExpanded {
                VStack(spacing: 12) {
                    // Start Workout button
                    Button(action: onStartWorkoutTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Start Workout")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#00C853"))
                        .clipShape(Capsule())
                    }
                    .offset(x: isExpanded ? -200 : 0)
                    .opacity(isExpanded ? 1 : 0)
                    
                    // Log Meal button
                    Button(action: onLogMealTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Log Meal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "#00E5FF"))
                        .clipShape(Capsule())
                    }
                    .offset(x: isExpanded ? -100 : 0)
                    .opacity(isExpanded ? 1 : 0)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .trailing))
                ))
            }
            
            // Main button
            Button(action: {
                isExpanded.toggle()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#8E24AA"), Color(hex: "#D500F9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
}