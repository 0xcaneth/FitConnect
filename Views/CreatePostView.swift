import SwiftUI
import Combine
import FirebaseFirestore
import PhotosUI

// --- Start of Top-Level Type Definitions ---

// Moved BadgeSelectionGridView to be top-level (as per previous successful refactor for its own complexity)
@available(iOS 16.0, *)
struct BadgeSelectionGridView: View {
    @Binding var selectedUIType: UITypeForPost // Will now refer to the top-level UITypeForPost
    @Binding var selectedBadgeName: String
    @Binding var selectedAchievementName: String
    let selectedPostType: PostType
    let categories: [BadgeCategory] // Will now refer to the top-level BadgeCategory

    var body: some View {
        VStack(spacing: 24) {
            ForEach(categories, id: \.name) { category in
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
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(category.badges, id: \.self) { uiBadgeType in
                            modernBadgeCard(uiBadgeType, categoryColor: category.color)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func modernBadgeCard(_ uiType: UITypeForPost, categoryColor: Color) -> some View {
        Button(action: {
            print("[BadgeSelection] Selected: \(uiType.displayName)")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedUIType = uiType
                if selectedPostType == .badge {
                    selectedBadgeName = uiType.displayName
                    selectedAchievementName = ""
                } else if selectedPostType == .achievement {
                    selectedAchievementName = uiType.displayName
                    selectedBadgeName = ""
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            selectedUIType == uiType ?
                            LinearGradient(
                                gradient: Gradient(colors: [uiType.color.opacity(0.4), uiType.color.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#1E1F25"), Color(hex: "#2A2B35")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedUIType == uiType ? uiType.color : Color.white.opacity(0.1),
                                    lineWidth: selectedUIType == uiType ? 2 : 0.5
                                )
                        )
                    
                    Image(systemName: uiType.iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(selectedUIType == uiType ? uiType.color : Color.white.opacity(0.8))
                        .scaleEffect(selectedUIType == uiType ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedUIType == uiType)
                }
                
                Text(uiType.displayName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedUIType == uiType ? .white : Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .scaleEffect(selectedUIType == uiType ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedUIType == uiType)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

// MOVE UITypeForPost enum to be top-level
enum UITypeForPost: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    // Fitness & Activity
    case fitnessSteps10k = "10k Steps Daily"
    case fitnessSteps15k = "15k Steps Warrior"
    case fitnessSteps20k = "20k Steps Champion"
    case fitnessCalories500 = "500 kcal Burn"
    case fitnessCalories750 = "750 kcal Burn"
    case fitnessCalories1000 = "1000 kcal Hero"
    case fitnessWorkout3days = "3-Day Workout Streak"
    case fitnessWorkout7days = "Weekly Workout Champion"
    case fitnessActiveMinutes30 = "30 Min Active Zone"
    case fitnessActiveMinutes60 = "1 Hour Active Hero"
    case fitnessStairsClimbed = "Stair Climbing Master"

    // Nutrition & Health
    case nutritionWater2L = "2L Water Hero"
    case nutritionWater3L = "3L Hydration Champion"
    case nutritionVeggie5servings = "5 Veggie Servings"
    case nutritionMealLog5days = "5-Day Meal Logger"
    case nutritionSugarFreeDay = "Sugar-Free Day"
    case nutritionProteinGoal = "Daily Protein Goal"
    case nutritionHealthyBreakfast = "Healthy Breakfast Week"

    // Wellness & Mindfulness
    case wellnessMeditation5min = "5 Min Daily Meditation"
    case wellnessMeditation15min = "15 Min Zen Master"
    case wellnessSleep8hours = "8 Hours Sleep Champion"
    case wellnessStressFreeDay = "Stress-Free Day"
    case wellnessMindfulEating = "Mindful Eating Practice"

    // Achievements & Goals
    case goalsChallengeComplete = "Challenge Completed"
    case goalsWeeklyGoal = "Weekly Goal Crusher"
    case goalsMonthlyGoal = "Monthly Achievement"
    case goalsSocialSupport = "Community Support"
    case goalsMotivatorBadge = "Daily Motivator"

    var displayName: String { self.rawValue }

    var iconName: String {
        switch self {
        // Fitness & Activity
        case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k: return "figure.walk"
        case .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000: return "flame.fill"
        case .fitnessWorkout3days, .fitnessWorkout7days: return "dumbbell.fill"
        case .fitnessActiveMinutes30, .fitnessActiveMinutes60: return "timer"
        case .fitnessStairsClimbed: return "arrow.up.circle.fill"

        // Nutrition & Health
        case .nutritionWater2L, .nutritionWater3L: return "drop.fill"
        case .nutritionVeggie5servings: return "leaf.fill"
        case .nutritionMealLog5days: return "fork.knife"
        case .nutritionSugarFreeDay: return "xmark.shield.fill"
        case .nutritionProteinGoal: return "bolt.heart.fill"
        case .nutritionHealthyBreakfast: return "sunrise.fill"

        // Wellness & Mindfulness
        case .wellnessMeditation5min, .wellnessMeditation15min: return "brain.head.profile"
        case .wellnessSleep8hours: return "moon.stars.fill"
        case .wellnessStressFreeDay: return "figure.mind.and.body"
        case .wellnessMindfulEating: return "mouth.fill"

        // Achievements & Goals
        case .goalsChallengeComplete: return "checkmark.seal.fill"
        case .goalsWeeklyGoal: return "calendar.badge.checkmark"
        case .goalsMonthlyGoal: return "calendar"
        case .goalsSocialSupport: return "person.3.fill"
        case .goalsMotivatorBadge: return "star.leadinghalf.filled"
        }
    }

    var color: Color {
        switch self {
        // Fitness & Activity
        case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k: return Color(hex: "#22C55E")
        case .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000: return Color(hex: "#EF4444")
        case .fitnessWorkout3days, .fitnessWorkout7days: return Color(hex: "#F59E0B")
        case .fitnessActiveMinutes30, .fitnessActiveMinutes60: return Color(hex: "#3B82F6")
        case .fitnessStairsClimbed: return Color(hex: "#6366F1")

        // Nutrition & Health
        case .nutritionWater2L, .nutritionWater3L: return Color(hex: "#06B6D4")
        case .nutritionVeggie5servings: return Color(hex: "#84CC16")
        case .nutritionMealLog5days: return Color(hex: "#F97316")
        case .nutritionSugarFreeDay: return Color(hex: "#EC4899")
        case .nutritionProteinGoal: return Color(hex: "#10B981")
        case .nutritionHealthyBreakfast: return Color(hex: "#FACC15")

        // Wellness & Mindfulness
        case .wellnessMeditation5min, .wellnessMeditation15min: return Color(hex: "#A855F7")
        case .wellnessSleep8hours: return Color(hex: "#4F46E5")
        case .wellnessStressFreeDay: return Color(hex: "#0EA5E9")
        case .wellnessMindfulEating: return Color(hex: "#D946EF")

        // Achievements & Goals
        case .goalsChallengeComplete: return Color(hex: "#F59E0B")
        case .goalsWeeklyGoal: return Color(hex: "#D97706")
        case .goalsMonthlyGoal: return Color(hex: "#B45309")
        case .goalsSocialSupport: return Color(hex: "#9333EA")
        case .goalsMotivatorBadge: return Color(hex: "#E11D48")
        }
    }
    
    var postTypeCategory: PostType {
        switch self {
        // Achievements (Generally harder, longer-term, or significant milestones)
        case .fitnessSteps20k, .fitnessCalories1000, .fitnessWorkout7days, .fitnessActiveMinutes60, .fitnessStairsClimbed,
             .nutritionWater3L, .nutritionMealLog5days, .nutritionProteinGoal, .nutritionHealthyBreakfast,
             .wellnessMeditation15min, .wellnessSleep8hours, .wellnessStressFreeDay, .wellnessMindfulEating,
             .goalsChallengeComplete, .goalsWeeklyGoal, .goalsMonthlyGoal, .goalsSocialSupport, .goalsMotivatorBadge:
            return .achievement
        // Badges (Generally more frequent, daily/short-term goals, or steps towards achievements)
        default:
            return .badge
        }
    }
}

// MOVE BadgeCategory struct to be top-level
struct BadgeCategory {
    let name: String
    let iconName: String
    let color: Color
    let badges: [UITypeForPost]
}

// --- End of Top-Level Type Definitions ---

@available(iOS 16.0, *)
struct CreatePostView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var postService: PostService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPostType: PostType = .badge
    @State private var postContent: String = ""
    @State private var selectedBadgeName: String = ""
    @State private var selectedAchievementCategory: String = ""
    @State private var selectedUIType: UITypeForPost = UITypeForPost.fitnessSteps10k

    @State private var isPosting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var imagePreview: Image? = nil
    @State private var showingAttachmentOptions = false
    @State private var showingFullImagePreview = false
    @State private var imageForFullScreenPreview: Image? = nil

    private let motivationCharacterLimit = 300
    
    private var achievementCategories: [String] {
        badgeCategories().map { $0.name }.filter { $0 != "Achievements & Goals" }.sorted()
    }

    private var postTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Post Type")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            HStack(spacing: 12) {
                ForEach(PostType.allCases, id: \.self) { type in
                    PostTypeButton(
                        postType: type,
                        isSelected: selectedPostType == type
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedPostType = type
                            postContent = ""
                            selectedAchievementCategory = ""
                            if type == .badge {
                                selectedUIType = badgeCategoriesForType(.badge).first?.badges.first ?? UITypeForPost.fitnessSteps10k
                                selectedBadgeName = selectedUIType.displayName
                            } else if type == .achievement {
                                selectedUIType = UITypeForPost.fitnessSteps10k
                                selectedBadgeName = ""
                            } else {
                                selectedUIType = UITypeForPost.fitnessSteps10k
                                selectedBadgeName = ""
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var badgeInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Badge")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            BadgeSelectionGridView(
                selectedUIType: $selectedUIType,
                selectedBadgeName: $selectedBadgeName,
                selectedAchievementName: .constant(""),
                selectedPostType: .badge,
                categories: badgeCategoriesForType(.badge)
            )
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var achievementInputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Achievement Category")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            
            Menu {
                ForEach(achievementCategories, id: \.self) { categoryName in
                    Button(categoryName) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedAchievementCategory = categoryName
                            postContent = ""
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedAchievementCategory.isEmpty ? "Choose a category" : selectedAchievementCategory)
                        .foregroundColor(selectedAchievementCategory.isEmpty ? .gray : .white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1C1E25").opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedAchievementCategory.isEmpty ? Color.clear : getCategoryColor(selectedAchievementCategory),
                                    lineWidth: selectedAchievementCategory.isEmpty ? 0 : 1.5
                                )
                        )
                )
            }
            .padding(.bottom, selectedAchievementCategory.isEmpty ? 0 : 10)

            if !selectedAchievementCategory.isEmpty {
                Text("Describe your Achievement")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                    .padding(.top, 10)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#1C1E25").opacity(0.7))
                        .frame(minHeight: 80)

                    if postContent.isEmpty {
                        Text("E.g., Completed a 5K run today!")
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
                        .scrollContentBackground(.hidden)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var motivationInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Write your motivational quote")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                Spacer()
                Text("\(postContent.count)/\(motivationCharacterLimit)")
                    .font(.caption)
                    .foregroundColor(postContent.count > motivationCharacterLimit ? .red : Color(hex: "#B0B3BA"))
            }
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#1C1E25").opacity(0.7))
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
                    .scrollContentBackground(.hidden)
                    .onChange(of: postContent) { newValue in
                        if newValue.count > motivationCharacterLimit {
                            postContent = String(newValue.prefix(motivationCharacterLimit))
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func contentInputView() -> some View {
        switch selectedPostType {
        case .badge:
            badgeInputSection
        case .achievement:
            achievementInputSection
        case .motivation:
            motivationInputSection
        }
    }
    
    @ViewBuilder
    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imagePreview {
                imagePreview
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.imagePreview = nil
                            self.selectedImageData = nil
                            self.selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .background(Circle().fill(Color.white.opacity(0.7)))
                                .padding(4)
                        }
                    }
            }

            HStack {
                Button {
                    showingAttachmentOptions = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color(hex: "#6E56E9"))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Color(hex: "#6E56E9").opacity(0.15))
                    .cornerRadius(10)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }

    private func badgeCategoriesForType(_ type: PostType) -> [BadgeCategory] {
        return badgeCategories().filter { category in
            if type == .badge {
                return true
            } else if type == .achievement {
                return true
            }
            return false
        }
    }

    private func badgeCategories() -> [BadgeCategory] {
        return [
            BadgeCategory(
                name: "Fitness & Activity",
                iconName: "figure.run",
                color: Color(hex: "#37C978"),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k, .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000, .fitnessWorkout3days, .fitnessWorkout7days, .fitnessActiveMinutes30, .fitnessActiveMinutes60, .fitnessStairsClimbed:
                        return true
                    default: return false
                    }
                }
            ),
            BadgeCategory(
                name: "Nutrition & Health",
                iconName: "leaf.fill",
                color: Color(hex: "#00E5FF"),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .nutritionWater2L, .nutritionWater3L, .nutritionVeggie5servings, .nutritionMealLog5days, .nutritionSugarFreeDay, .nutritionProteinGoal, .nutritionHealthyBreakfast:
                        return true
                    default: return false
                    }
                }
            ),
            BadgeCategory(
                name: "Wellness & Mindfulness",
                iconName: "brain.head.profile",
                color: Color(hex: "#C964FF"),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .wellnessMeditation5min, .wellnessMeditation15min, .wellnessSleep8hours, .wellnessStressFreeDay, .wellnessMindfulEating:
                        return true
                    default: return false
                    }
                }
            ),
            BadgeCategory(
                name: "Achievements & Goals",
                iconName: "trophy.fill",
                color: Color(hex: "#FFA500"),
                badges: UITypeForPost.allCases.filter { uiType in
                     switch uiType {
                     case .goalsChallengeComplete, .goalsWeeklyGoal, .goalsMonthlyGoal, .goalsSocialSupport, .goalsMotivatorBadge:
                        return true
                     default: return false
                     }
                }
            )
        ]
    }

    private func getCategoryColor(_ categoryName: String) -> Color {
        return badgeCategories().first(where: { $0.name == categoryName })?.color ?? .gray
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#0D0F14").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        postTypeSelectionSection
                        
                        contentInputView()
                            .id(selectedPostType)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .leading)), removal: .opacity.combined(with: .move(edge: .trailing))))
                        
                        attachmentSection
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(Color(hex: "#B0B3BA"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") { handleCreatePost() }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(canPost() ? Color(hex: "#6E56E9") : Color.gray)
                        .disabled(!canPost() || isPosting)
                        .opacity(canPost() ? 1.0 : 0.5)
                        .overlay { if isPosting { ProgressView().tint(Color(hex: "#6E56E9")) } }
                }
            }
            .photosPicker(isPresented: $showingAttachmentOptions, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    guard let newItem else {
                        selectedImageData = nil; imagePreview = nil; return
                    }
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedImageData = data
                        if let uiImage = UIImage(data: data) { imagePreview = Image(uiImage: uiImage) }
                        else { imagePreview = nil }
                    } else {
                        selectedImageData = nil; imagePreview = nil
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Post Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    if alertMessage.contains("successfully") { presentationMode.wrappedValue.dismiss() }
                    alertMessage = ""
                })
            }
        }
    }

    private func canPost() -> Bool {
        guard session.currentUser != nil else { return false }
        switch selectedPostType {
        case .badge:
            return !selectedBadgeName.isEmpty
        case .achievement:
            return !selectedAchievementCategory.isEmpty && !postContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .motivation:
            let trimmedContent = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedContent.count >= 5 && trimmedContent.count <= motivationCharacterLimit
        }
    }
    
    private func handleCreatePost() {
        guard canPost(), let currentUserId = session.currentUserId, let currentUser = session.currentUser else {
            self.alertMessage = "Cannot create post. Please check your input or login status."
            self.showingAlert = true
            return
        }
        
        isPosting = true
        
        Task {
            var imageUploadErrorOccurred = false
            
            do {
                var imageURLForPost: String? = nil
                if let imageData = selectedImageData {
                    do {
                        imageURLForPost = try await postService.uploadPostImage(imageData: imageData, forUser: currentUserId)
                    } catch {
                        imageUploadErrorOccurred = true
                        throw error
                    }
                }

                let postTypeForModel: PostType = selectedPostType
                var contentForModel: String = ""
                var categoryForModel: String? = nil
                var badgeNameForModel: String? = nil
                var achievementNameForModel: String? = nil
                
                switch selectedPostType {
                case .badge:
                    badgeNameForModel = selectedUIType.displayName
                    categoryForModel = badgeCategories().first(where: { $0.badges.contains(selectedUIType) })?.name
                    if categoryForModel == nil {
                         print("Error: Could not determine category for badge: \(selectedUIType.displayName)")
                         categoryForModel = "General"
                    }
                case .achievement:
                    categoryForModel = selectedAchievementCategory
                    contentForModel = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if selectedUIType.postTypeCategory == .achievement &&
                       badgeCategories().first(where: {$0.name == categoryForModel})?.badges.contains(selectedUIType) == true {
                        achievementNameForModel = selectedUIType.displayName
                    } else {
                        achievementNameForModel = nil
                    }

                case .motivation:
                    contentForModel = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
                }

                let newPost = Post(
                    authorId: currentUserId,
                    authorName: currentUser.fullName,
                    authorAvatarURL: currentUser.photoURL,
                    createdAt: Timestamp(date: Date()),
                    type: postTypeForModel,
                    category: categoryForModel,
                    content: contentForModel.isEmpty ? nil : contentForModel,
                    badgeName: badgeNameForModel,
                    achievementName: achievementNameForModel,
                    imageURL: imageURLForPost,
                    likesCount: 0,
                    commentsCount: 0,
                    status: .published
                )
                
                try await postService.createPost(newPost)
                
                await MainActor.run {
                    self.isPosting = false
                    self.alertMessage = "Post published successfully!"
                    self.showingAlert = true
                }
            } catch {
                await MainActor.run {
                    self.isPosting = false
                    if imageUploadErrorOccurred {
                        self.alertMessage = "Failed to upload image. Error: \(error.localizedDescription)"
                    } else {
                        self.alertMessage = "Failed to publish post: \(error.localizedDescription)"
                    }
                    self.showingAlert = true
                }
            }
        }
    }
}

struct PostTypeButton: View {
    let postType: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconNameFor(postType: postType))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? themeColorFor(postType: postType) : Color(hex: "#B0B3BA"))
                
                Text(displayNameFor(postType: postType))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color(hex: "#B0B3BA"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeColorFor(postType: postType).opacity(0.25) : Color(hex: "#1E1F25"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeColorFor(postType: postType) : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private func displayNameFor(postType: PostType) -> String {
        switch postType {
        case .badge: return "Badge"
        case .achievement: return "Achievement"
        case .motivation: return "Motivation"
        }
    }
    
    private func iconNameFor(postType: PostType) -> String {
        switch postType {
        case .badge: return "star.fill"
        case .achievement: return "trophy.fill"
        case .motivation: return "quote.bubble.fill"
        }
    }
    
    private func themeColorFor(postType: PostType) -> Color {
        switch postType {
        case .badge: return Color(hex: "#37C978")
        case .achievement: return Color(hex: "#FFA500")
        case .motivation: return Color(hex: "#C964FF")
        }
    }
}