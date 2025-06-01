import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode

    // Placeholder user data - replace with actual data from session or fetched
    private var userName: String {
        session.currentUser?.displayName ?? "User Name"
    }
    private var userEmail: String {
        session.currentUser?.email ?? "user@example.com"
    }
    private var userAvatarInitial: String {
        String(userName.first ?? (userEmail.first ?? "U")).uppercased()
    }

    var body: some View {
        NavigationView { // To get a Nav Bar for title and dismiss button
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea() // Consistent dark background

                ScrollView {
                    VStack(spacing: 30) {
                        // User Info Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color(hex: "#444444"))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle().stroke(Color(hex: "#6E56E9"), lineWidth: 3)
                                )
                                .overlay(
                                    Text(userAvatarInitial)
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                            
                            Text(userName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(userEmail)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(Color(hex: "#B0B3BA"))
                        }
                        .padding(.top, 30)

                        // Settings List
                        VStack(spacing: 1) { // Use spacing 1 for thin dividers if Color.gray is used
                            ProfileRow(iconName: "person.fill", text: "Edit Profile") { /* TODO: Action */ }
                            ProfileRow(iconName: "slider.horizontal.3", text: "Preferences") { /* TODO: Action */ }
                            ProfileRow(iconName: "shield.lefthalf.filled", text: "Privacy Policy") { /* TODO: Action */ }
                            ProfileRow(iconName: "doc.text.fill", text: "Terms & Conditions") { /* TODO: Action */ }
                            ProfileRow(iconName: "questionmark.circle.fill", text: "Help & Support") { /* TODO: Action */ }
                        }
                        .background(Color(hex: "#1E1F25")) // Card background for the list
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30) // Pushes logout button towards bottom

                        // Logout Button
                        Button(action: {
                            // Add confirmation alert before logging out?
                            try? session.signOut()
                            presentationMode.wrappedValue.dismiss() // Dismiss sheet after logout
                        }) {
                            Text("Log Out")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "#FF3B30")) // Red for logout
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#FF3B30").opacity(0.15))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40) // Padding from bottom edge
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "#6E56E9")) // Accent color
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensures proper sheet presentation style
    }
}

struct ProfileRow: View {
    let iconName: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .foregroundColor(Color(hex: "#6E56E9")) // Accent color
                    .font(.system(size: 20))
                    .frame(width: 24) // Align icons
                Text(text)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#575A62")) // Mid-gray
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
        }
        Divider().background(Color(hex: "#2A2E3B")) // Custom divider color
            .padding(.leading, 56) // Indent divider
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.previewStore()) // Use a preview store
            .preferredColorScheme(.dark)
    }
}

// Add a preview SessionStore if it doesn't exist
extension SessionStore {
    static func previewStore() -> SessionStore {
        let store = SessionStore()
        // store.currentUser = User(uid: "previewUID", email: "preview@example.com", displayName: "Preview User") // If you have a Firebase User mock
        store.isLoggedIn = true
        store.role = "client"
        // For previewing, you might need to mock a Firebase User or parts of it.
        // For simplicity, ProfileView uses direct properties or placeholders if currentUser is nil.
        return store
    }
}
#endif