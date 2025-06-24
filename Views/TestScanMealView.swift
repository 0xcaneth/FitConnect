import SwiftUI

// Temporary test view to demonstrate ScanMealView functionality
@available(iOS 16.0, *)
struct TestScanMealView: View {
    @State private var showingScanMeal = false
    
    var body: some View {
        ZStack {
            FitConnectColors.backgroundDark
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Test Scan Meal Feature")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text("This is a standalone test of the Scan Meal feature")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button {
                    showingScanMeal = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Open Scan Meal")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [FitConnectColors.accentCyan, FitConnectColors.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: FitConnectColors.accentCyan.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                
                VStack(spacing: 12) {
                    Text("Feature Checklist:")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach([
                        "✅ Camera capture with overlay guides",
                        "✅ Core ML food recognition (mock data)",
                        "✅ Animated result cards",
                        "✅ Firebase image upload & storage",
                        "✅ Meal logging to Firestore",
                        "✅ Permission handling",
                        "✅ Error handling & retry logic",
                        "✅ Haptic feedback",
                        "✅ Dark theme styling"
                    ], id: \.self) { item in
                        HStack {
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingScanMeal) {
            ScanMealView()
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct TestScanMealView_Previews: PreviewProvider {
    static var previews: some View {
        TestScanMealView()
            .preferredColorScheme(.dark)
    }
}
#endif