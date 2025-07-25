import SwiftUI

struct ChatListView: View {
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
            
            Text("Chat List Screen")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }
}

#if DEBUG
struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatListView()
        }
        .preferredColorScheme(.dark)
    }
}
#endif
