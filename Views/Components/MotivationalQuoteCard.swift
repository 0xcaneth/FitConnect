import SwiftUI

struct MotivationalQuoteCard: View {
    @Binding var quoteText: String
    @Binding var isQuoteFavorited: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Quote mark
            Text("\"")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(.white)
                .offset(y: -8)
            
            // Quote text
            VStack(alignment: .leading, spacing: 4) {
                Text(quoteText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Heart button
            Button(action: {
                onToggleFavorite()
            }) {
                Image(systemName: isQuoteFavorited ? "heart.fill" : "heart")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isQuoteFavorited ? Color(hex: "#FFDDDD") : .white)
                    .scaleEffect(isQuoteFavorited ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isQuoteFavorited)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .frame(height: 80)
        .background(
            LinearGradient(
                colors: [Color(hex: "#FF8C3B"), Color(hex: "#FF4E5A")],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
    }
}
