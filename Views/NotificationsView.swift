import SwiftUI

struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                
                Text("No Notifications")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("You're all caught up! New notifications will appear here.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#0D0F14").ignoresSafeArea())
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
            .preferredColorScheme(.dark)
    }
}
#endif
