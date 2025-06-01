import SwiftUI

struct NutritionView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("#0B0D17"),
                    Color("#1A1B25")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Text("Nutrition Screen")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

// Helper extension from HomeView.swift, needed if this file is compiled standalone for previews
// extension Color {
//     init(hex: String) { ... } // Copy from HomeView if needed for isolated preview
// }

#if DEBUG
struct NutritionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NutritionView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
