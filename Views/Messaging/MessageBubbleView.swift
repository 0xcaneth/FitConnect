import SwiftUI

struct MessageBubbleView: View {
    let msg: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack {
            if isMine { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                if let imageURL = msg.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12))
                        default: ProgressView()
                        }
                    }
                    .frame(maxWidth: 220, maxHeight: 180)
                }
                Text(msg.text ?? "")
                    .padding(12)
                    .foregroundColor(isMine ? .white : .primary)
                    .background(isMine ? Color.accentColor : Color(.systemGray5))
                    .cornerRadius(14)
                if msg.isFeedback == true {
                    Label("Feedback", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.thinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 2)
                }
            }
            if !isMine { Spacer() }
        }
        .padding(.horizontal, 2)
    }
}