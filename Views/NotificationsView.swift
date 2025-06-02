import SwiftUI

struct NotificationsView: View {
    @Environment(\.presentationMode) var presentationMode

    // Placeholder for actual notification data
    // struct NotificationItem: Identifiable {
    //     let id = UUID()
    //     let title: String
    //     let message: String
    //     let timestamp: Date
    //     var isRead: Bool
    // }
    // @State private var notifications: [NotificationItem] = [] // Populate from a service

    var body: some View {
        NavigationView { // To have a navigation bar for title and close button
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14") ?? .black, Color(hex: "#1A1B25") ?? .black.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    // Placeholder content
                    Image(systemName: "bell.slash.circle.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.top, 50)
                    
                    Text("No New Notifications")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Check back later for updates.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(Color.gray)
                    
                    Spacer()
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline) // Or .large
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "#6E56E9"))
                }
            }
        }
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