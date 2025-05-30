import SwiftUI

struct ConversationRow: View {
    var conversation: Conversation
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: conversation.otherParticipantPhotoURL ?? "")) { ph in
                ph.resizable()
            } placeholder: {
                Circle().fill(Color.gray)
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(conversation.otherParticipantName ?? "Someone")
                    .font(.headline)
                Text(conversation.lastMessageText ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            if let ts = conversation.lastMessageTimestamp {
                Text(ts, style: .time)
                    .font(.footnote)
            }
        }
        .padding(.vertical, 8)
    }
}