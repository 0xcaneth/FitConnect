import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CreatePostView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPostType: FeedPostType = .motivation_text
    @State private var postContent: String = ""
    @State private var selectedBadgeType: BadgeType = .steps10k
    @State private var isPosting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    enum BadgeType: String, CaseIterable {
        case steps10k = "10k Steps Daily"
        case steps15k = "15k Steps Warrior"
        case steps20k = "20k Steps Champion"
        case calories500 = "500 kcal Burn"
        case calories750 = "750 kcal Burn"
        case calories1000 = "1000 kcal Hero"
        case workout3days = "3-Day Workout Streak"
        case workout7days = "Weekly Workout Champion"
        case activeMinutes30 = "30 Min Active Zone"
        case activeMinutes60 = "1 Hour Active Hero"
        case stairsClimbed = "Stair Climbing Master"
        
        case water2L = "2L Water Hero"
        case water3L = "3L Hydration Champion"
        case veggie5servings = "5 Veggie Servings"
        case mealLog5days = "5-Day Meal Logger"
        case sugarFreeDay = "Sugar-Free Day"
        case proteinGoal = "Daily Protein Goal"
        case healthyBreakfast = "Healthy Breakfast Week"
        
        case meditation5min = "5 Min Daily Meditation"
        case meditation15min = "15 Min Zen Master"
        case sleep8hours = "8 Hours Sleep Champion"
        case stressFreeDay = "Stress-Free Day"
        case mindfulEating = "Mindful Eating Practice"
        
        case challengeComplete = "Challenge Completed"
        case weeklyGoal = "Weekly Goal Crusher"
        case monthlyGoal = "Monthly Achievement"
        case socialSupport = "Community Support"
        case motivatorBadge = "Daily Motivator"
        
        var displayName: String {
            return self.rawValue
        }
        
        var iconName: String {
            switch self {
            case .steps10k, .steps15k, .steps20k: return "figure.walk"
            case .calories500, .calories750, .calories1000: return "flame.fill"
            case .workout3days, .workout7days: return "dumbbell.fill"
            case .activeMinutes30, .activeMinutes60: return "timer"
            case .stairsClimbed: return "arrow.up.circle.fill"
            
            case .water2L, .water3L: return "drop.fill"
            case .veggie5servings: return "leaf.fill"
            case .mealLog5days: return "fork.knife"
            case .sugarFreeDay: return "xmark.circle.fill"
            case .proteinGoal: return "bolt.fill"
            case .healthyBreakfast: return "sun.max.fill"
            
            case .meditation5min, .meditation15min: return "heart.circle.fill"
            case .sleep8hours: return "moon.fill"
            case .stressFreeDay: return "leaf.circle.fill"
            case .mindfulEating: return "brain.head.profile"
            
            case .challengeComplete: return "checkmark.seal.fill"
            case .weeklyGoal, .monthlyGoal: return "target"
            case .socialSupport: return "person.2.fill"
            case .motivatorBadge: return "quote.bubble.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .steps10k, .steps15k, .steps20k: return Color(hex: "#22C55E")
            case .calories500, .calories750, .calories1000: return Color(hex: "#EF4444")
            case .workout3days, .workout7days: return Color(hex: "#F59E0B")
            case .activeMinutes30, .activeMinutes60: return Color(hex: "#10B981")
            case .stairsClimbed: return Color(hex: "#8B5CF6")
            
            case .water2L, .water3L: return Color(hex: "#06B6D4")
            case .veggie5servings: return Color(hex: "#84CC16")
            case .mealLog5days: return Color(hex: "#F97316")
            case .sugarFreeDay: return Color(hex: "#EF4444")
            case .proteinGoal: return Color(hex: "#3B82F6")
            case .healthyBreakfast: return Color(hex: "#FBBF24")
            
            case .meditation5min, .meditation15min: return Color(hex: "#A855F7")
            case .sleep8hours: return Color(hex: "#6366F1")
            case .stressFreeDay: return Color(hex: "#EC4899")
            case .mindfulEating: return Color(hex: "#8B5CF6")
            
            case .challengeComplete: return Color(hex: "#059669")
            case .weeklyGoal: return Color(hex: "#DC2626")
            case .monthlyGoal: return Color(hex: "#7C3AED")
            case .socialSupport: return Color(hex: "#0891B2")
            case .motivatorBadge: return Color(hex: "#DB2777")
            }
        }
        
        var colorHex: String {
            switch self {
            case .steps10k, .steps15k, .steps20k: return "#22C55E"
            case .calories500, .calories750, .calories1000: return "#EF4444"
            case .workout3days, .workout7days: return "#F59E0B"
            case .activeMinutes30, .activeMinutes60: return "#10B981"
            case .stairsClimbed: return "#8B5CF6"
            
            case .water2L, .water3L: return "#06B6D4"
            case .veggie5servings: return "#84CC16"
            case .mealLog5days: return "#F97316"
            case .sugarFreeDay: return "#EF4444"
            case .proteinGoal: return "#3B82F6"
            case .healthyBreakfast: return "#FBBF24"
            
            case .meditation5min, .meditation15min: return "#A855F7"
            case .sleep8hours: return "#6366F1"
            case .stressFreeDay: return "#EC4899"
            case .mindfulEating: return "#8B5CF6"
            
            case .challengeComplete: return "#059669"
            case .weeklyGoal: return "#DC2626"
            case .monthlyGoal: return "#7C3AED"
            case .socialSupport: return "#0891B2"
            case .motivatorBadge: return "#DB2777"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Post Type")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(FeedPostType.allCases, id: \.self) { type in
                                    PostTypeButton(
                                        type: type,
                                        isSelected: selectedPostType == type
                                    ) {
                                        selectedPostType = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        contentInputView()
                        
                        previewPostView()
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createPost()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canPost() ? Color(hex: "#6E56E9") : Color(hex: "#B0B3BA"))
                    .disabled(!canPost() || isPosting)
                }
            }
        }
        .alert("Post Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("Success") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    @ViewBuilder
    private func contentInputView() -> some View {
        switch selectedPostType {
        case .badge, .achievement:
            VStack(alignment: .leading, spacing: 20) {
                Text("Select \(selectedPostType.displayName)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                badgeSelectionGrid()
            }
            .padding(.horizontal, 20)
            
        case .motivation_text:
            VStack(alignment: .leading, spacing: 12) {
                Text("Write your motivational quote")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1C1E25").opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(minHeight: 80)

                    if postContent.isEmpty {
                        Text("Share an inspiring quote or thought...")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $postContent)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .background(Color.clear)
                        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .frame(minHeight: 80, maxHeight: 120)
                        .onAppear { 
                            UITextView.appearance().backgroundColor = UIColor.clear
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private func badgeSelectionGrid() -> some View {
        let categories = badgeCategories()
        
        VStack(spacing: 24) {
            ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: category.iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(category.color)
                        }
                        
                        Text(category.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(category.badges, id: \.self) { badge in
                                modernBadgeCard(badge, categoryColor: category.color)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    @ViewBuilder
    private func modernBadgeCard(_ badgeType: BadgeType, categoryColor: Color) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedBadgeType = badgeType
                postContent = badgeType.displayName
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            selectedBadgeType == badgeType ?
                            LinearGradient(
                                gradient: Gradient(colors: [badgeType.color.opacity(0.3), badgeType.color.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#1E1F25"), Color(hex: "#2A2B35")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedBadgeType == badgeType ? badgeType.color : Color.clear,
                                    lineWidth: selectedBadgeType == badgeType ? 2 : 0
                                )
                        )
                    
                    Image(systemName: badgeType.iconName)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(selectedBadgeType == badgeType ? badgeType.color : Color.white.opacity(0.8))
                        .scaleEffect(selectedBadgeType == badgeType ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedBadgeType == badgeType)
                }
                
                Text(badgeType.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(selectedBadgeType == badgeType ? .white : Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 80)
            }
            .padding(.vertical, 12)
            .scaleEffect(selectedBadgeType == badgeType ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedBadgeType == badgeType)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func badgeCategories() -> [BadgeCategory] {
        return [
            BadgeCategory(
                name: "Fitness & Activity",
                iconName: "figure.run",
                color: Color(hex: "#22C55E"),
                badges: [.steps10k, .steps15k, .steps20k, .calories500, .calories750, .calories1000, .workout3days, .workout7days, .activeMinutes30, .activeMinutes60, .stairsClimbed]
            ),
            BadgeCategory(
                name: "Nutrition & Health",
                iconName: "leaf.fill",
                color: Color(hex: "#06B6D4"),
                badges: [.water2L, .water3L, .veggie5servings, .mealLog5days, .sugarFreeDay, .proteinGoal, .healthyBreakfast]
            ),
            BadgeCategory(
                name: "Wellness & Mindfulness",
                iconName: "heart.circle.fill",
                color: Color(hex: "#A855F7"),
                badges: [.meditation5min, .meditation15min, .sleep8hours, .stressFreeDay, .mindfulEating]
            ),
            BadgeCategory(
                name: "Achievements & Goals",
                iconName: "trophy.fill",
                color: Color(hex: "#F59E0B"),
                badges: [.challengeComplete, .weeklyGoal, .monthlyGoal, .socialSupport, .motivatorBadge]
            )
        ]
    }
    
    struct BadgeCategory {
        let name: String
        let iconName: String
        let color: Color
        let badges: [BadgeType]
    }
    
    @ViewBuilder
    private func previewPostView() -> some View {
        if canPost() {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: "#444444"))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#4A00E0"), Color(hex: "#00D4FF")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        )
                        .overlay(
                            Text(String(getCurrentUserName().prefix(1)).uppercased())
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getCurrentUserName())
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("now")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(Color(hex: "#B0B3BA"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: selectedPostType.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(colorForPostType(selectedPostType))
                }
                
                contentPreview()
                
                HStack(spacing: 6) {
                    Image(systemName: "heart")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                    
                    Text("0")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#B0B3BA"))
                }
            }
            .padding(16)
            .background(Color(hex: "#1C1E25"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorForPostType(selectedPostType).opacity(0.5),
                                colorForPostType(selectedPostType).opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        } else {
            VStack(spacing: 12) {
                Image(systemName: "eye.slash")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "#6A6A6A"))
                
                Text("Preview will appear here")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Color(hex: "#6A6A6A"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(Color(hex: "#1C1E25"))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private func contentPreview() -> some View {
        switch selectedPostType {
        case .badge:
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#22C55E"))
                
                Text("\(getCurrentUserName()) unlocked \(postContent)!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
        case .achievement:
            HStack(spacing: 8) {
                Image(systemName: "trophy.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#F59E0B"))
                
                Text("\(getCurrentUserName()) achieved \(postContent)!")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
        case .motivation_text:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#6E56E9"))
                    Spacer()
                }
                
                Text(postContent)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .italic()
                    .foregroundColor(.white)
                    .lineLimit(nil)
                
                HStack {
                    Spacer()
                    Image(systemName: "quote.closing")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#6E56E9"))
                }
            }
        }
    }
    
    private func canPost() -> Bool {
        switch selectedPostType {
        case .badge, .achievement:
            return !postContent.isEmpty
        case .motivation_text:
            return postContent.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
        }
    }
    
    private func getCurrentUserName() -> String {
        if let currentUser = session.currentUser {
            return currentUser.displayName ?? currentUser.email ?? "Unknown User"
        }
        return "Unknown User"
    }
    
    private func colorForPostType(_ type: FeedPostType) -> Color {
        switch type {
        case .badge:
            return Color(hex: "#22C55E")
        case .achievement:
            return Color(hex: "#F59E0B")
        case .motivation_text:
            return Color(hex: "#6E56E9")
        }
    }
    
    private func createPost() {
        guard canPost(), !session.currentUserId.isEmpty else { return }
        
        isPosting = true
        
        let finalContent: String
        switch selectedPostType {
        case .badge, .achievement:
            finalContent = selectedBadgeType.displayName
        case .motivation_text:
            finalContent = postContent
        }
        
        let newPost = FeedPost(
            authorId: session.currentUserId,
            authorName: getCurrentUserName(),
            authorPhotoURL: nil,
            type: selectedPostType,
            content: finalContent,
            imageURL: nil,
            timestamp: Timestamp(date: Date()),
            likesCount: 0,
            likedBy: []
        )
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("feed").addDocument(from: newPost) { error in
                DispatchQueue.main.async {
                    self.isPosting = false
                    
                    if let error = error {
                        self.alertMessage = "Failed to publish post: \(error.localizedDescription)"
                        self.showingAlert = true
                    } else {
                        self.alertMessage = "Post published successfully!"
                        self.showingAlert = true
                        
                        if self.selectedPostType == .badge || self.selectedPostType == .achievement {
                            self.createActivityEntry(for: self.selectedBadgeType)
                        }
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isPosting = false
                self.alertMessage = "Failed to create post: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }
    
    private func createActivityEntry(for badgeType: BadgeType) {
        let db = Firestore.firestore()
        
        let activityData: [String: Any] = [
            "userId": session.currentUserId,
            "type": selectedPostType == .badge ? "badge" : "achievement",
            "title": "\(selectedPostType.displayName) Unlocked",
            "description": badgeType.displayName,
            "iconName": badgeType.iconName,
            "iconColorHex": badgeType.colorHex,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("user_activities").addDocument(data: activityData) { error in
            if let error = error {
                print("[CreatePostView] Error creating activity entry: \(error.localizedDescription)")
            } else {
                print("[CreatePostView] Activity entry created for \(badgeType.displayName)")
            }
        }
    }

}

struct PostTypeButton: View {
    let type: FeedPostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color(hex: "#B0B3BA"))
                
                Text(type.displayName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(hex: "#B0B3BA"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colorForType(type) : Color(hex: "#1E1F25"))
            )
        }
    }
    
    private func colorForType(_ type: FeedPostType) -> Color {
        switch type {
        case .badge:
            return Color(hex: "#22C55E").opacity(0.3)
        case .achievement:
            return Color(hex: "#F59E0B").opacity(0.3)
        case .motivation_text:
            return Color(hex: "#6E56E9").opacity(0.3)
        }
    }
}

#if DEBUG
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif
