import SwiftUI

struct WorkoutView: View {
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
            
            Text("Workout Screen")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false) // Allow back navigation
    }
}

// Helper extension from HomeView.swift, needed if this file is compiled standalone for previews
// extension Color {
//     init(hex: String) { ... } // Copy from HomeView if needed for isolated preview
// }

#if DEBUG
struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WorkoutView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
