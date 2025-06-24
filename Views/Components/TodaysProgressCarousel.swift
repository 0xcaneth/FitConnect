import SwiftUI

struct TodaysProgressCarousel: View {
    let stepData: (value: Int, goal: Int)
    let caloriesData: (value: Int, goal: Int)
    let waterData: (value: Int, goal: Int)
    
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentIndex)
                }
            }
            .padding(.bottom, 8)
            
            // Paged TabView with 80% width for peek effect
            TabView(selection: $currentIndex) {
                ProgressCardView(
                    iconName: "figure.walk",
                    value: stepData.value,
                    goal: stepData.goal,
                    unit: "steps",
                    accentColor: .green,
                    isCenter: currentIndex == 0
                )
                .tag(0)
                
                ProgressCardView(
                    iconName: "flame.fill",
                    value: caloriesData.value,
                    goal: caloriesData.goal,
                    unit: "kcal",
                    accentColor: .orange,
                    isCenter: currentIndex == 1
                )
                .tag(1)
                
                ProgressCardView(
                    iconName: "drop.fill",
                    value: waterData.value,
                    goal: waterData.goal,
                    unit: "mL",
                    accentColor: .blue,
                    isCenter: currentIndex == 2
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 340)
            .onAppear {
                // Start with staggered entrance animations
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    // Cards will animate in via their onAppear
                }
            }
        }
    }
}
