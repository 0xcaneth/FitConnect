import SwiftUI

struct ProgressCardData {
    let title: String
    let value: String
    let unit: String
    let goal: String
    let progress: Double
    let color: Color
    let iconName: String
}

struct TodaysProgressCard: View {
    let data: ProgressCardData
    
    var body: some View {
        VStack(spacing: 12) {
            // Circular icon
            Circle()
                .fill(data.color)
                .frame(width: 60, height: 60)
                .overlay {
                    Image(systemName: data.iconName)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
            
            // Value and unit
            VStack(spacing: 4) {
                Text(data.value)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                Text(data.unit)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#B0B0B0"))
            }
            
            // Goal text
            Text(data.goal)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#A0A0A0"))
            
            // Progress bar
            VStack(spacing: 8) {
                ProgressView(value: data.progress)
                    .progressViewStyle(CustomProgressViewStyle(color: data.color))
                    .frame(height: 6)
                    .animation(.easeInOut(duration: 0.6), value: data.progress)
                
                Text("\(Int(data.progress * 100))% complete")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#A0A0A0"))
            }
            .padding(.horizontal, 16)
        }
        .frame(width: 300, height: 260)
        .background(Color(hex: "#1F1F1F"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(data.color, lineWidth: 2)
        )
        .shadow(color: data.color.opacity(0.12), radius: 20, x: 0, y: 0)
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#2A2A2A"))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 6)
            }
        }
    }
}