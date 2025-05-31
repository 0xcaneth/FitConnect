// Views/HomeView.swift

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject private var session: SessionStore
    @Binding var selectedTab: AppTab

    @State private var userName: String = ""
    @State private var isLoadingName = true
    let onLogout: () -> Void

    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: Profile section
                    HStack {
                        AvatarView(initials: String(userName.first ?? "U"))
                        VStack(alignment: .leading) {
                            Text("Welcome, \(userName)")
                                .font(
                                    {
                                        if #available(iOS 14.0, *) {
                                            return Font.title2
                                        } else {
                                            return Font.headline
                                        }
                                    }()
                                )
                            Text("Let's get fit!")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()

                    // MARK: Feature cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            FeatureCard(icon: "figure.run", title: "Workouts", subtitle: "Start training")
                            FeatureCard(icon: "fork.knife", title: "Nutrition", subtitle: "Track meals")
                            FeatureCard(icon: "chart.bar.fill", title: "Progress", subtitle: "See stats")
                        }
                        .padding(.horizontal)
                    }

                    // MARK: Quick actions
                    HStack(spacing: 12) {
                        QuickActionButton(icon: "plus", title: "Add Workout") { }
                        QuickActionButton(icon: "camera", title: "Meal Photo") { }
                        QuickActionButton(icon: "message", title: "Chat") { }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color("AppPrimaryBackground").edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Home", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Logout", action: onLogout)
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: loadUserName)
    }

    private func loadUserName() {
        guard let uid = session.currentUser?.uid else {
            // no signed-in user, show placeholder
            userName = "User"
            isLoadingName = false
            return
        }

        db.collection("users")
          .document(uid)
          .getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["fullName"] as? String {
                self.userName = name
            } else if let email = session.currentUser?.email {
                self.userName = email
            } else {
                self.userName = "User"
            }
            self.isLoadingName = false
        }
    }
}

// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            selectedTab: .constant(.home),
            onLogout: {}
        )
        .environmentObject({
            let store = SessionStore()
            // Simulate a signed-in user for preview
            store.currentUser = Auth.auth().currentUser
            return store
        }())
        .preferredColorScheme(.light)

        HomeView(
            selectedTab: .constant(.home),
            onLogout: {}
        )
        .environmentObject(SessionStore())
        .preferredColorScheme(.dark)
    }
}
