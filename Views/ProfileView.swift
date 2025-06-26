import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userXP: Int = 0
    @State private var userBadges: [Badge] = []
    @State private var isLoadingProfile: Bool = true
    @State private var showingExpertPanel = false
    @State private var isGeneratingHealthData = false

    private var userName: String {
        session.currentUser?.fullName ?? "User Name"
    }
    private var userEmail: String {
        session.currentUser?.email ?? "user@example.com"
    }
    private var userAvatarInitial: String {
        String(userName.first ?? (userEmail.first ?? "U")).uppercased()
    }
    
    private var userLevel: Int {
        max(1, userXP / 100)
    }
    
    private var progressToNextLevel: Double {
        let currentLevelXP = userXP - ((userLevel - 1) * 100)
        let totalXPNeeded = 100
        return totalXPNeeded > 0 ? Double(currentLevelXP) / Double(totalXPNeeded) : 0.0
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoadingProfile {
                    loadingView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            profileHeaderView()
                            
                            xpLevelCard()
                            
                            statisticsGrid()
                            
                            badgesSection()
                            
                            settingsSection()
                            
                            logoutButton()
                            
                            addHealthDataButton()
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadProfileData()
        }
        .sheet(isPresented: $showingExpertPanel) {
            ExpertPanelView()
        }
    }
    
    @ViewBuilder
    private func profileHeaderView() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#6E56E9"), Color(hex: "#8B7FF7")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 108, height: 108)
                
                Circle()
                    .fill(Color(hex: "#1E1F25"))
                    .frame(width: 100, height: 100)
                
                Text(userAvatarInitial)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(userName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(userEmail)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
            }
        }
        .padding(.vertical, 20)
    }
    
    @ViewBuilder
    private func xpLevelCard() -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(userLevel)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("\(userXP) XP")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#2A2E3B"), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: progressToNextLevel)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#6E56E9"), Color(hex: "#8B7FF7")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progressToNextLevel)
                    
                    Text("\(Int(progressToNextLevel * 100))%")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress to Level \(userLevel + 1)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                    
                    Spacer()
                    
                    Text("\(Int((progressToNextLevel * 100))) / 100 XP")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#8A8F9B"))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#2A2E3B"))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#6E56E9"), Color(hex: "#8B7FF7")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressToNextLevel, height: 8)
                            .animation(.easeInOut(duration: 1.0), value: progressToNextLevel)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#1E1F25"))
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
    
    @ViewBuilder
    private func statisticsGrid() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 16) {
                StatCardView(
                    title: "Total XP",
                    value: "\(userXP)",
                    icon: "star.fill",
                    gradientColors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")]
                )
                
                StatCardView(
                    title: "Badges",
                    value: "\(userBadges.count)",
                    icon: "rosette",
                    gradientColors: [Color(hex: "#FF6B6B"), Color(hex: "#FF8E53")]
                )
                
                StatCardView(
                    title: "Level",
                    value: "\(userLevel)",
                    icon: "crown.fill",
                    gradientColors: [Color(hex: "#4ECDC4"), Color(hex: "#44A08D")]
                )
                
                StatCardView(
                    title: "Streak",
                    value: "12", 
                    icon: "flame.fill",
                    gradientColors: [Color(hex: "#F093FB"), Color(hex: "#F5576C")]
                )
            }
        }
    }
    
    @ViewBuilder
    private func badgesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Badges")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(userBadges.count)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#6E56E9"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "#6E56E9").opacity(0.2))
                    .cornerRadius(12)
            }
            
            if userBadges.isEmpty {
                emptyBadgesView()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(userBadges) { badge in
                        ModernBadgeCard(badge: badge)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func emptyBadgesView() -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#6E56E9").opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "star.circle")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#6E56E9"))
            }
            
            Text("No badges yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Complete challenges to earn your first badge!")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1E1F25").opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#6E56E9").opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private func settingsSection() -> some View {
        VStack(spacing: 1) {
            ModernSettingsRow(iconName: "person.fill", text: "Edit Profile", color: Color(hex: "#6E56E9")) { }
            ModernSettingsRow(iconName: "person.badge.plus", text: "My Expert", color: Color(hex: "#22C55E")) {
                showingExpertPanel = true
            }
            ModernSettingsRow(iconName: "slider.horizontal.3", text: "Preferences", color: Color(hex: "#FF6B6B")) { }
            ModernSettingsRow(iconName: "shield.lefthalf.filled", text: "Privacy Policy", color: Color(hex: "#4ECDC4")) { }
            ModernSettingsRow(iconName: "questionmark.circle.fill", text: "Help & Support", color: Color(hex: "#F093FB")) { }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1E1F25"))
        )
    }
    
    @ViewBuilder
    private func logoutButton() -> some View {
        Button(action: {
            try? session.signOut()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Log Out")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(Color(hex: "#FF3B30"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#FF3B30").opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FF3B30").opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    @ViewBuilder
    private func addHealthDataButton() -> some View {
        Button(action: {
            generateTestHealthData()
        }) {
            HStack {
                if isGeneratingHealthData {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(isGeneratingHealthData ? "Generating..." : "Add HealthData")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#22C55E").opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#22C55E"), lineWidth: 1)
                    )
            )
        }
        .disabled(isGeneratingHealthData)
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#6E56E9")))
                .scaleEffect(1.2)
            
            Text("Loading profile...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadProfileData() {
        guard let userId = session.currentUserId, !userId.isEmpty else {
            print("[ProfileView] User not logged in or userId is empty, cannot load profile data.")
            isLoadingProfile = false
            return
        }
        
        let db = Firestore.firestore()
        
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
    
    private func generateTestHealthData() {
        guard let userId = session.currentUserId, !userId.isEmpty else {
            print("[ProfileView] User not logged in, cannot generate test data")
            return
        }
        
        isGeneratingHealthData = true
        
        Task {
            do {
                await TestHealthDataGenerator.generateRandomHealthData(for: userId)
                
                DispatchQueue.main.async {
                    self.isGeneratingHealthData = false
                    // Show success feedback
                    print("[ProfileView] Successfully generated test health data")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isGeneratingHealthData = false
                    print("[ProfileView] Error generating test health data: \(error)")
                }
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let gradientColors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.2)
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(gradientColors[0])
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#1E1F25"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gradientColors[0].opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ModernBadgeCard: View {
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
                    .frame(width: 50, height: 50)
                
                Image(systemName: badge.iconName ?? "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(badge.badgeName)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text(badge.earnedAt.dateValue(), style: .date)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(Color(hex: "#B0B3BA"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#22C55E").opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ModernActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
            }
            
            Spacer()
            
            Text(timeAgoString(from: timestamp))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(Color(hex: "#8A8F9B"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25"))
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ModernSettingsRow: View {
    let iconName: String
    let text: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: iconName)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#575A62"))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(Color.clear)
        
        if text != "Help & Support" {
            Divider()
                .background(Color(hex: "#2A2E3B"))
                .padding(.leading, 68)
        }
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
#endif