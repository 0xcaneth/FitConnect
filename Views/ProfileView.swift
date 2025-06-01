import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userXP: Int = 0
    @State private var userBadges: [Badge] = []
    @State private var isLoadingProfile: Bool = true

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
    
    private var userLevel: Int {
        // Simple level calculation: Level = XP / 100, minimum level 1
        max(1, userXP / 100)
    }
    
    private var xpForCurrentLevel: Int {
        (userLevel - 1) * 100
    }
    
    private var xpForNextLevel: Int {
        userLevel * 100
    }
    
    private var progressToNextLevel: Double {
        let currentLevelXP = userXP - xpForCurrentLevel
        let totalXPNeeded = xpForNextLevel - xpForCurrentLevel
        return totalXPNeeded > 0 ? Double(currentLevelXP) / Double(totalXPNeeded) : 0.0
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea()

                if isLoadingProfile {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            // User Info Header
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(Color(hex: "#444444"))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle().stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
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
                            
                            VStack(spacing: 20) {
                                VStack(spacing: 8) {
                                    Text("Level \(userLevel)")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("\(userXP) XP")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(hex: "#B0B3BA"))
                                }
                                
                                // Progress Ring for Next Level
                                ZStack {
                                    Circle()
                                        .stroke(Color(hex: "#2A2E3B"), lineWidth: 8)
                                        .frame(width: 120, height: 120)
                                    
                                    Circle()
                                        .trim(from: 0, to: progressToNextLevel)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 120, height: 120)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack(spacing: 4) {
                                        Text("\(Int(progressToNextLevel * 100))%")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text("to Level \(userLevel + 1)")
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundColor(Color(hex: "#B0B3BA"))
                                    }
                                }
                            }
                            .padding()
                            .background(Color(hex: "#1E1F25"))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Badges")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(userBadges.count)")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(Color(hex: "#B0B3BA"))
                                }
                                .padding(.horizontal, 20)
                                
                                if userBadges.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "star.circle")
                                            .font(.system(size: 48))
                                            .foregroundColor(Color(hex: "#6E56E9"))
                                        Text("No badges yet—complete a goal!")
                                            .font(.system(size: 16, design: .rounded))
                                            .foregroundColor(Color(hex: "#B0B3BA"))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(Color(hex: "#1E1F25"))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(userBadges) { badge in
                                                BadgeCardView(badge: badge)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }

                            // Settings List
                            VStack(spacing: 1) {
                                ProfileRow(iconName: "person.fill", text: "Edit Profile") { /* TODO: Action */ }
                                ProfileRow(iconName: "slider.horizontal.3", text: "Preferences") { /* TODO: Action */ }
                                ProfileRow(iconName: "shield.lefthalf.filled", text: "Privacy Policy") { /* TODO: Action */ }
                                ProfileRow(iconName: "doc.text.fill", text: "Terms & Conditions") { /* TODO: Action */ }
                                ProfileRow(iconName: "questionmark.circle.fill", text: "Help & Support") { /* TODO: Action */ }
                            }
                            .background(Color(hex: "#1E1F25"))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 30)

                            // Logout Button
                            Button(action: {
                                try? session.signOut()
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Text("Log Out")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "#FF3B30"))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#FF3B30").opacity(0.15))
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
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
                    .foregroundColor(Color(hex: "#6E56E9"))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadProfileData()
        }
    }
    
    private func loadProfileData() {
        guard !session.currentUserId.isEmpty else {
            print("[ProfileView] User not logged in, cannot load profile data.")
            isLoadingProfile = false
            return
        }
        
        let userId = session.currentUserId
        let db = Firestore.firestore()
        
        // Load user XP
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ProfileView] Error loading user data: \(error.localizedDescription)")
                } else if let data = snapshot?.data(),
                          let xp = data["xp"] as? Int {
                    self.userXP = xp
                } else {
                    print("[ProfileView] No XP data found, defaulting to 0")
                    self.userXP = 0
                }
            }
        }
        
        // Load user badges
        db.collection("users").document(userId).collection("badges")
            .order(by: "earnedAt", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingProfile = false
                    
                    if let error = error {
                        print("[ProfileView] Error loading badges: \(error.localizedDescription)")
                        self.userBadges = []
                    } else if let documents = snapshot?.documents {
                        self.userBadges = documents.compactMap { document in
                            do {
                                return try document.data(as: Badge.self)
                            } catch {
                                print("[ProfileView] Error decoding badge \(document.documentID): \(error)")
                                return nil
                            }
                        }
                        print("[ProfileView] Loaded \(self.userBadges.count) badges for user.")
                    } else {
                        self.userBadges = []
                    }
                }
            }
    }
}

struct BadgeCardView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.iconName ?? "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(badge.badgeName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(badge.earnedAt.dateValue(), style: .date)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(Color(hex: "#1E1F25"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// Keep existing ProfileRow struct and extension...
struct ProfileRow: View {
    let iconName: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .foregroundColor(Color(hex: "#6E56E9"))
                    .font(.system(size: 20))
                    .frame(width: 24)
                Text(text)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#575A62"))
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
        }
        Divider().background(Color(hex: "#2A2E3B"))
            .padding(.leading, 56)
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}

extension SessionStore {
    static func previewStore() -> SessionStore {
        let store = SessionStore()
        store.isLoggedIn = true
        store.role = "client"
        return store
    }
}
#endif
