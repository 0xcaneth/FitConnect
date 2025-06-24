import SwiftUI
import FirebaseFirestore

// Re-using UserActivity and ActivityRow from ClientHomeView for now.
// Consider moving these to a shared Models/Components file if used in more places.

@available(iOS 16.0, *)
struct AllActivitiesView: View {
    @EnvironmentObject var session: SessionStore
    // Assuming UserActivity and ActivityRow are accessible or redefined here
    // If they are private in ClientHomeView, they need to be made internal or public,
    // or redefined here, or moved to a shared location.

    // For simplicity, let's assume UserActivity can be defined here or is globally available
    // If not, you'll need to copy/paste the UserActivity struct definition here.
    // And similarly for ActivityRow or make it a public/internal component.

    @State private var allActivities: [UserActivity] = []
    @State private var isLoading: Bool = true

    private func formatTimestamp(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }

    private func formatRelativeTime(_ timestamp: Timestamp) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp.dateValue(), relativeTo: Date())
    }

    private func iconColorForActivityType(_ type: String) -> Color {
        switch type.lowercased() {
        case "workout", "run", "strength":
            return Color(hex: "#4CAF50") ?? .green
        case "achievement", "badge":
            return Color(hex: "#FFC107") ?? .yellow
        case "yoga", "meditation":
            return Color(hex: "#9C27B0") ?? .purple
        default:
            return Color(hex: "#6E56E9") ?? .blue
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0F14") ?? .black, Color(hex: "#1A1B25") ?? .black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#6E56E9")))
                        .scaleEffect(1.5)
                        .padding(.top, 50)
                } else if allActivities.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.mixed.cardio")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(Color.gray.opacity(0.7))
                        Text("No Activities Found")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Your recent activities will appear here once you record them.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 50)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(allActivities) { activity in
                            ActivityRow(
                                icon: activity.iconName,
                                iconColor: iconColorForActivityType(activity.type),
                                title: activity.title,
                                subtitle: activity.description,
                                time: formatRelativeTime(activity.timestamp)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("All Activity")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                fetchAllUserActivities()
            }
        }
    }

    private func fetchAllUserActivities() {
        isLoading = true
        guard let currentUserId = session.currentUserId, !currentUserId.isEmpty else {
            isLoading = false
            allActivities = []
            print("[AllActivitiesView] Cannot fetch activities: User ID is nil or empty.")
            return
        }

        let db = Firestore.firestore()
        db.collection("user_activities")
            .whereField("userId", isEqualTo: currentUserId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("Error fetching all activities: \(error.localizedDescription)")
                        allActivities = []
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        allActivities = []
                        return
                    }

                    self.allActivities = documents.compactMap { document -> UserActivity? in
                        try? document.data(as: UserActivity.self)
                    }
                }
            }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AllActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AllActivitiesView()
                .environmentObject(SessionStore.previewStore())
        }
        .preferredColorScheme(.dark)
    }
}
#endif
