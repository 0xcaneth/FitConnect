import SwiftUI

struct StatsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTimeFrame = 0
    private let timeFrames = ["Today", "Week", "Month"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time frame picker
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(0..<timeFrames.count, id: \.self) { index in
                            Text(timeFrames[index]).tag(index)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Today's Summary
                    todaysSummaryView
                    
                    // Weekly Totals
                    weeklyTotalsView
                    
                    // Nutrition Summary
                    nutritionSummaryView
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color(hex: "#0D0F14").ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        // TODO: Refresh stats
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var todaysSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatsStatCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "0",
                    subtitle: "Goal: 10,000 steps",
                    progress: 0.0,
                    color: .green
                )
                
                StatsStatCard(
                    icon: "flame.fill",
                    title: "Active Calories",
                    value: "0",
                    subtitle: "Goal: 500 kcal",
                    progress: 0.0,
                    color: .orange
                )
                
                StatsStatCard(
                    icon: "drop.fill",
                    title: "Water Intake",
                    value: "0",
                    subtitle: "Goal: 2,000 mL",
                    progress: 0.0,
                    color: .blue
                )
            }
        }
    }
    
    private var weeklyTotalsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Totals")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                WeeklyTotalCard(
                    icon: "figure.walk",
                    title: "Steps",
                    value: "0",
                    subtitle: "Total steps",
                    color: .green
                )
                
                WeeklyTotalCard(
                    icon: "flame.fill",
                    title: "Calories",
                    value: "0",
                    subtitle: "Active kcal",
                    color: .orange
                )
            }
        }
    }
    
    private var nutritionSummaryView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Summary")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NutritionCard(
                    icon: "fork.knife",
                    title: "Today's Meals",
                    subtitle: "No meals logged yet",
                    color: .purple
                )
                
                NutritionCard(
                    icon: "fork.knife",
                    title: "Weekly Meals",
                    subtitle: "No meals logged this week",
                    color: .purple
                )
            }
        }
    }
}

struct StatsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25") ?? .gray.opacity(0.3))
        )
    }
}

struct WeeklyTotalCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25") ?? .gray.opacity(0.3))
        )
    }
}

struct NutritionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25") ?? .gray.opacity(0.3))
        )
    }
}

#if DEBUG
struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .preferredColorScheme(.dark)
    }
}
#endif
