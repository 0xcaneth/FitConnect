import SwiftUI
import HealthKit
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct ClientHomeView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var showChatDetail = false
    @State private var currentChatId: String?
    @State private var showHealthKitBanner = true
    @State private var currentQuoteIndex = 0
    @State private var isHeartFilled = false
    @State private var selectedProgressCard = 0
    @State private var isCreatingChat = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var chatSummaryForSheet: ChatSummary? = nil
    @State private var showingScanMeal = false
    @State private var showingLogMeal = false

    private let chatService = ChatService.shared
    
    private let motivationalQuotes = [
        "Every step counts towards your goals!",
        "Your health journey starts today!",
        "Small changes lead to big results!",
        "You're stronger than you think!",
        "Progress, not perfection!"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if showHealthKitBanner && healthKitManager.authorizationStatus != .sharingAuthorized {
                    healthKitPermissionBanner
                }
                
                motivationalQuoteCard
                
                todaysProgressSection
                
                quickActionsSection
                
                recentActivitySection
                
                Spacer(minLength: 100) // Extra space at bottom for tab bar
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(Color(hex: "0D0F14"))
        .onAppear {
            if healthKitManager.authorizationStatus == .sharingAuthorized {
                showHealthKitBanner = false
            }
            if session.assignedDietitianId.isEmpty {
                session.assignedDietitianId = "mock_dietitian_123"
                print("[ClientHomeView] Assigned mock dietitian for testing")
            }
        }
        .sheet(isPresented: $showingScanMeal) {
            ScanMealView()
        }
        .sheet(isPresented: $showingLogMeal) {
            LogMealView()
                .environmentObject(session)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(item: $chatSummaryForSheet, onDismiss: {
            // Optionally reset any state if needed when sheet is dismissed
        }) { summary in
            NavigationStack {
                ClientChatDetailView(
                    chatId: summary.id,
                    dietitianName: summary.otherParticipant(currentUserId: session.currentUserId ?? "")?.fullName ?? "Dietitian",
                    dietitianAvatarURL: summary.otherParticipant(currentUserId: session.currentUserId ?? "")?.photoURL,
                    session: session
                )
                .environmentObject(session)
                .navigationBarHidden(true)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private var healthKitPermissionBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "FF8E3C"))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit access needed")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Enable to see your live health data")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Button {
                Task {
                    await healthKitManager.requestAuthorization()
                    if healthKitManager.authorizationStatus == .sharingAuthorized {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showHealthKitBanner = false
                        }
                    }
                }
            } label: {
                Text("Enable")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF8E3C"), Color(hex: "FF3C5C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.backgroundDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF8E3C"), Color(hex: "FF3C5C")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    private var motivationalQuoteCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: 30))
                .foregroundColor(.white)
            
            Text(motivationalQuotes[currentQuoteIndex])
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHeartFilled.toggle()
                }
                
                currentQuoteIndex = (currentQuoteIndex + 1) % motivationalQuotes.count
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                }
            } label: {
                Image(systemName: isHeartFilled ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .scaleEffect(isHeartFilled ? 1.4 : 1.0)
            }
        }
        .padding(16)
        .frame(height: 95)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "FF8E3C"), Color(hex: "FF5C9C")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
    }
    
    private var todaysProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == selectedProgressCard ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            TabView(selection: $selectedProgressCard) {
                progressCard(
                    title: "steps",
                    value: "\(healthKitManager.stepCount)",
                    goal: "Goal: 10,000",
                    progress: Double(healthKitManager.stepCount) / 10000.0,
                    color: Color(hex: "3CD76B"),
                    icon: "figure.walk"
                ).tag(0)
                
                progressCard(
                    title: "kcal",
                    value: "\(Int(healthKitManager.activeEnergyBurned))",
                    goal: "Goal: 500 kcal",
                    progress: healthKitManager.activeEnergyBurned / 500.0,
                    color: Color(hex: "FF8E3C"),
                    icon: "flame.fill"
                ).tag(1)
                
                progressCard(
                    title: "mL",
                    value: "\(Int(healthKitManager.waterIntake))",
                    goal: "Goal: 2000 mL",
                    progress: healthKitManager.waterIntake / 2000.0,
                    color: Color(hex: "3C9CFF"),
                    icon: "drop.fill"
                ).tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
        }
    }
    
    private func progressCard(title: String, value: String, goal: String, progress: Double, color: Color, icon: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Text(goal)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            VStack(spacing: 8) {
                ProgressView(value: min(progress, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .frame(height: 6)
                
                Text("\(Int(min(progress * 100, 100)))% complete")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color, lineWidth: 2)
                )
        )
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Scan Meal",
                        icon: "camera",
                        gradient: GradientColors(start: Color(hex: "FF9800"), end: Color(hex: "FF5722"))
                    ) {
                        showingScanMeal = true
                    }
                    
                    quickActionButton(
                        title: "Log Meal",
                        icon: "fork.knife",
                        gradient: GradientColors(start: Color(hex: "26C6DA"), end: Color(hex: "00ACC1"))
                    ) {
                        print("[ClientHomeView] Log Meal button tapped")
                        showingLogMeal = true
                    }
                }
                
                HStack(spacing: 12) {
                    quickActionButton(
                        title: "Stats",
                        icon: "chart.bar.fill",
                        gradient: GradientColors(start: Color(hex: "42A5F5"), end: Color(hex: "1E88E5"))
                    ) {
                        // Action for Stats
                    }
                    
                    quickActionButton(
                        title: "Chat w/ Dietitian",
                        icon: "bubble.left.and.bubble.right.fill",
                        gradient: GradientColors(start: Color(hex: "AB47BC"), end: Color(hex: "8E24AA")),
                        isDisabled: session.assignedDietitianId.isEmpty
                    ) {
                        openChatWithAssignedDietitian()
                    }
                }
            }
            
            if session.assignedDietitianId.isEmpty {
                Text("No dietitian assigned yet")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
    }
    
    struct GradientColors {
        let start: Color
        let end: Color
    }
    
    private func quickActionButton(title: String, icon: String, gradient: GradientColors, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
            }
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDisabled ? [Color.gray.opacity(0.5), Color.gray.opacity(0.3)] : [gradient.start, gradient.end],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isDisabled ? .gray : .white)
                }
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isDisabled ? .gray : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "0D0F14"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(LinearGradient(
                                colors: isDisabled ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)] : [gradient.start.opacity(0.7), gradient.end.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ), lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .scaleEffect(isDisabled ? 1.0 : 1.0) // Will be animated on tap
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
    
    private func openChatWithAssignedDietitian() {
        if isCreatingChat {
            print("[ClientHome] openChatWithAssignedDietitian called while already isCreatingChat. Aborting.")
            return
        }

        guard let currentUserId = session.currentUserId,
              let currentUserFullName = session.currentUser?.fullName,
              !session.assignedDietitianId.isEmpty else {
            errorMessage = "User not logged in or no dietitian assigned."
            showError = true
            return
        }
        
        let dietitianId = session.assignedDietitianId
        
        // Ensure client and dietitian are not the same (though assignedDietitianId should prevent this)
        guard currentUserId != dietitianId else {
            errorMessage = "Invalid chat configuration."
            showError = true
            return
        }

        isCreatingChat = true

        if dietitianId == "mock_dietitian_123" {
            let clientParticipant = ParticipantInfo(id: currentUserId, fullName: currentUserFullName, photoURL: session.currentUser?.photoURL)
            let dietitianParticipantInfo = ParticipantInfo(id: dietitianId, fullName: "Dr. Sarah Wilson", photoURL: nil)

            chatService.getOrCreateChat(client: clientParticipant, dietitian: dietitianParticipantInfo) { result in
                DispatchQueue.main.async {
                    self.isCreatingChat = false
                    switch result {
                    case .success(let chatSummary):
                        self.chatSummaryForSheet = chatSummary
                    case .failure(let error):
                        self.errorMessage = "Failed to get or create chat: \(error.localizedDescription)"
                        self.showError = true
                    }
                }
            }
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(dietitianId).getDocument { dietitianSnapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Could not fetch dietitian details: \(error.localizedDescription)"
                    self.showError = true
                    self.isCreatingChat = false
                    return
                }
                
                guard let dietitianData = dietitianSnapshot?.data(),
                      let dietitianFullName = dietitianData["fullName"] as? String else {
                    self.errorMessage = "Dietitian details incomplete."
                    self.showError = true
                    self.isCreatingChat = false
                    return
                }
                let dietitianPhotoURL = dietitianData["photoURL"] as? String

                let clientParticipant = ParticipantInfo(id: currentUserId, fullName: currentUserFullName, photoURL: session.currentUser?.photoURL)
                let dietitianParticipantInfo = ParticipantInfo(id: dietitianId, fullName: dietitianFullName, photoURL: dietitianPhotoURL)

                chatService.getOrCreateChat(client: clientParticipant, dietitian: dietitianParticipantInfo) { result in
                    DispatchQueue.main.async {
                        self.isCreatingChat = false
                        switch result {
                        case .success(let chatSummary):
                            self.chatSummaryForSheet = chatSummary
                        case .failure(let error):
                            self.errorMessage = "Failed to get or create chat: \(error.localizedDescription)"
                            self.showError = true
                        }
                    }
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                }
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8F3FFF"))
            }
            
            VStack(spacing: 12) {
                Image(systemName: "star")
                    .font(.system(size: 64))
                    .foregroundColor(.gray.opacity(0.6))
                
                VStack(spacing: 4) {
                    Text("No recent activity yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete workouts and log meals to see your activity here.")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let previewSession = SessionStore.previewStore(isLoggedIn: true, role: "client")
        var previewUser = FitConnectUser(id: "clientPreviewUser", email: "client@example.com", fullName: "Client Preview")
        previewUser.assignedDietitianId = "dietitianPreviewUser123"
        previewSession.currentUser = previewUser
        previewSession.currentUserId = previewUser.id

        return ClientHomeView()
            .environmentObject(previewSession)
            .preferredColorScheme(.dark)
    }
}
#endif
