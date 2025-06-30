import SwiftUI
import Combine
import FirebaseFirestore
import PhotosUI

// --- Top-Level Type Definitions ---

@available(iOS 16.0, *)
struct PremiumBadgeSelectionGridView: View {
    @Binding var selectedUIType: UITypeForPost
    @Binding var selectedBadgeName: String
    @Binding var selectedAchievementName: String
    let selectedPostType: PostType
    let categories: [PremiumBadgeCategory]
    
    @State private var animationTrigger = false
    @State private var selectedCategoryIndex: Int? = nil

    var body: some View {
        VStack(spacing: 28) {
            ForEach(Array(categories.enumerated()), id: \.element.name) { categoryIndex, category in
                VStack(alignment: .leading, spacing: 20) {
                    // Premium category header
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedCategoryIndex = selectedCategoryIndex == categoryIndex ? nil : categoryIndex
                        }
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                category.color.opacity(0.2),
                                                category.color.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .shadow(color: category.color.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: category.iconName)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [category.color, category.color.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("\(category.badges.count) achievements")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: selectedCategoryIndex == categoryIndex ? "chevron.up" : "chevron.down")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(category.color)
                                .rotationEffect(.degrees(selectedCategoryIndex == categoryIndex ? 180 : 0))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategoryIndex == categoryIndex)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.08),
                                            Color.white.opacity(0.04)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    category.color.opacity(0.4),
                                                    Color.white.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    
                    // Expandable badge grid
                    if selectedCategoryIndex == categoryIndex {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 20) {
                            ForEach(Array(category.badges.enumerated()), id: \.element.rawValue) { badgeIndex, uiBadgeType in
                                premiumBadgeCard(uiBadgeType, categoryColor: category.color, index: badgeIndex)
                            }
                        }
                        .padding(.horizontal, 8)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .bottom))
                        ))
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedCategoryIndex)
            }
        }
        .onAppear {
            // Auto-expand first category
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    selectedCategoryIndex = 0
                    animationTrigger = true
                }
            }
        }
    }

    @ViewBuilder
    private func premiumBadgeCard(_ uiType: UITypeForPost, categoryColor: Color, index: Int) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
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
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            selectedUIType == uiType ?
                            LinearGradient(
                                colors: [
                                    uiType.color.opacity(0.3),
                                    uiType.color.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedUIType == uiType ? 
                                    LinearGradient(
                                        colors: [uiType.color, uiType.color.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) : 
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: selectedUIType == uiType ? 2.5 : 1
                                )
                        )
                        .shadow(
                            color: selectedUIType == uiType ? uiType.color.opacity(0.3) : .black.opacity(0.1),
                            radius: selectedUIType == uiType ? 12 : 6,
                            x: 0,
                            y: selectedUIType == uiType ? 6 : 3
                        )
                    
                    ZStack {
                        // Glow effect for selected
                        if selectedUIType == uiType {
                            Circle()
                                .fill(uiType.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .blur(radius: 8)
                        }
                        
                        Image(systemName: uiType.iconName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(
                                selectedUIType == uiType ?
                                LinearGradient(
                                    colors: [uiType.color, uiType.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(selectedUIType == uiType ? 1.15 : 1.0)
                            .shadow(
                                color: selectedUIType == uiType ? uiType.color.opacity(0.4) : .clear,
                                radius: 6,
                                x: 0,
                                y: 3
                            )
                    }
                }
                
                Text(uiType.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedUIType == uiType ? .white : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .minimumScaleFactor(0.8)
            }
            .scaleEffect(selectedUIType == uiType ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedUIType == uiType)
            .opacity(animationTrigger ? 1.0 : 0.0)
            .scaleEffect(animationTrigger ? 1.0 : 0.8)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(Double(index) * 0.1),
                value: animationTrigger
            )
        }
        .buttonStyle(.plain)
    }
}

// Enhanced UITypeForPost enum
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
        case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k: return "figure.walk"
        case .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000: return "flame.fill"
        case .fitnessWorkout3days, .fitnessWorkout7days: return "dumbbell.fill"
        case .fitnessActiveMinutes30, .fitnessActiveMinutes60: return "timer"
        case .fitnessStairsClimbed: return "arrow.up.circle.fill"
        case .nutritionWater2L, .nutritionWater3L: return "drop.fill"
        case .nutritionVeggie5servings: return "leaf.fill"
        case .nutritionMealLog5days: return "fork.knife"
        case .nutritionSugarFreeDay: return "xmark.shield.fill"
        case .nutritionProteinGoal: return "bolt.heart.fill"
        case .nutritionHealthyBreakfast: return "sunrise.fill"
        case .wellnessMeditation5min, .wellnessMeditation15min: return "brain.head.profile"
        case .wellnessSleep8hours: return "moon.stars.fill"
        case .wellnessStressFreeDay: return "figure.mind.and.body"
        case .wellnessMindfulEating: return "mouth.fill"
        case .goalsChallengeComplete: return "checkmark.seal.fill"
        case .goalsWeeklyGoal: return "calendar.badge.checkmark"
        case .goalsMonthlyGoal: return "calendar"
        case .goalsSocialSupport: return "person.3.fill"
        case .goalsMotivatorBadge: return "star.leadinghalf.filled"
        }
    }

    var color: Color {
        switch self {
        case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k: return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000: return Color(red: 0.94, green: 0.27, blue: 0.27)
        case .fitnessWorkout3days, .fitnessWorkout7days: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .fitnessActiveMinutes30, .fitnessActiveMinutes60: return Color(red: 0.23, green: 0.51, blue: 0.96)
        case .fitnessStairsClimbed: return Color(red: 0.39, green: 0.40, blue: 0.95)
        case .nutritionWater2L, .nutritionWater3L: return Color(red: 0.02, green: 0.71, blue: 0.84)
        case .nutritionVeggie5servings: return Color(red: 0.52, green: 0.80, blue: 0.09)
        case .nutritionMealLog5days: return Color(red: 0.98, green: 0.45, blue: 0.09)
        case .nutritionSugarFreeDay: return Color(red: 0.93, green: 0.28, blue: 0.60)
        case .nutritionProteinGoal: return Color(red: 0.06, green: 0.73, blue: 0.51)
        case .nutritionHealthyBreakfast: return Color(red: 0.98, green: 0.80, blue: 0.08)
        case .wellnessMeditation5min, .wellnessMeditation15min: return Color(red: 0.66, green: 0.33, blue: 0.97)
        case .wellnessSleep8hours: return Color(red: 0.31, green: 0.27, blue: 0.90)
        case .wellnessStressFreeDay: return Color(red: 0.06, green: 0.65, blue: 0.91)
        case .wellnessMindfulEating: return Color(red: 0.85, green: 0.27, blue: 0.94)
        case .goalsChallengeComplete: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .goalsWeeklyGoal: return Color(red: 0.85, green: 0.47, blue: 0.02)
        case .goalsMonthlyGoal: return Color(red: 0.71, green: 0.32, blue: 0.04)
        case .goalsSocialSupport: return Color(red: 0.58, green: 0.20, blue: 0.92)
        case .goalsMotivatorBadge: return Color(red: 0.88, green: 0.11, blue: 0.28)
        }
    }
    
    var postTypeCategory: PostType {
        switch self {
        case .fitnessSteps20k, .fitnessCalories1000, .fitnessWorkout7days, .fitnessActiveMinutes60, .fitnessStairsClimbed,
             .nutritionWater3L, .nutritionMealLog5days, .nutritionProteinGoal, .nutritionHealthyBreakfast,
             .wellnessMeditation15min, .wellnessSleep8hours, .wellnessStressFreeDay, .wellnessMindfulEating,
             .goalsChallengeComplete, .goalsWeeklyGoal, .goalsMonthlyGoal, .goalsSocialSupport, .goalsMotivatorBadge:
            return .achievement
        default:
            return .badge
        }
    }
}

struct PremiumBadgeCategory {
    let name: String
    let iconName: String
    let color: Color
    let badges: [UITypeForPost]
}

// --- Main Create Post View ---

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
    
    // Animation states
    @State private var hasAppearedOnce = false
    @State private var typeSelectionAnimation = false
    @State private var contentAnimation = false
    @State private var backgroundParticleOffset: CGFloat = 0
    
    private let motivationCharacterLimit = 300
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 24, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Premium dynamic background
                premiumBackgroundView
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero section
                        if hasAppearedOnce {
                            premiumHeroSection
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.9)).combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .scale(scale: 0.9))
                                ))
                        }
                        
                        // Post type selection
                        premiumPostTypeSelection
                            .opacity(typeSelectionAnimation ? 1.0 : 0.0)
                            .scaleEffect(typeSelectionAnimation ? 1.0 : 0.9)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: typeSelectionAnimation)
                        
                        // Content input based on type
                        Group {
                            switch selectedPostType {
                            case .badge:
                                premiumBadgeInputSection
                            case .achievement:
                                premiumAchievementInputSection
                            case .motivation:
                                premiumMotivationInputSection
                            }
                        }
                        .opacity(contentAnimation ? 1.0 : 0.0)
                        .scaleEffect(contentAnimation ? 1.0 : 0.95)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: contentAnimation)
                        .id(selectedPostType) // Force recreation on type change
                        
                        // Premium attachment section
                        premiumAttachmentSection
                            .opacity(contentAnimation ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: contentAnimation)
                        
                        // Bottom spacing
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    premiumPostButton
                }
            }
            .photosPicker(isPresented: $showingAttachmentOptions, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    await handleImageSelection(newItem)
                }
            }
            .onChange(of: selectedPostType) { newType in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    contentAnimation = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        contentAnimation = true
                    }
                }
                resetContentForNewType(newType)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Post Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("successfully") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        alertMessage = ""
                    }
                )
            }
            .onAppear {
                startInitialAnimations()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Premium Background
    @ViewBuilder
    private var premiumBackgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.03, green: 0.04, blue: 0.06), location: 0.0),
                    .init(color: Color(red: 0.06, green: 0.07, blue: 0.10), location: 0.3),
                    .init(color: Color(red: 0.04, green: 0.05, blue: 0.08), location: 0.7),
                    .init(color: Color(red: 0.02, green: 0.03, blue: 0.05), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating creative particles
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.15),
                                Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.08),
                                Color(red: 0.96, green: 0.62, blue: 0.04).opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 30...100), height: CGFloat.random(in: 30...100))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height) + backgroundParticleOffset
                    )
                    .blur(radius: CGFloat.random(in: 20...40))
                    .animation(
                        .linear(duration: Double.random(in: 25...45))
                        .repeatForever(autoreverses: false),
                        value: backgroundParticleOffset
                    )
            }
            
            // Radial glow effects
            RadialGradient(
                colors: [
                    Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.04),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Premium Hero Section
    @ViewBuilder
    private var premiumHeroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Animated rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.3 - Double(index) * 0.1),
                                    Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.3 - Double(index) * 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index * 20), height: 80 + CGFloat(index * 20))
                        .rotationEffect(.degrees(Double(index * 120)))
                        .animation(
                            .linear(duration: 10 + Double(index * 2))
                            .repeatForever(autoreverses: false),
                            value: hasAppearedOnce
                        )
                }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91),
                                Color(red: 0.00, green: 0.83, blue: 1.00)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.4), radius: 15, x: 0, y: 8)
            }
            
            VStack(spacing: 12) {
                Text("Share Your Journey")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Inspire others with your achievements,\nbadges, and motivational thoughts")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Premium Post Type Selection
    @ViewBuilder
    private var premiumPostTypeSelection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("What would you like to share?")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }
            
            HStack(spacing: 16) {
                ForEach(PostType.allCases, id: \.self) { type in
                    PremiumPostTypeButton(
                        postType: type,
                        isSelected: selectedPostType == type
                    ) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedPostType = type
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Content Input Sections
    @ViewBuilder
    private var premiumBadgeInputSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.13, green: 0.77, blue: 0.37))
                
                Text("Select Your Badge")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            PremiumBadgeSelectionGridView(
                selectedUIType: $selectedUIType,
                selectedBadgeName: $selectedBadgeName,
                selectedAchievementName: .constant(""),
                selectedPostType: .badge,
                categories: premiumBadgeCategoriesForType(.badge)
            )
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var premiumAchievementInputSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.96, green: 0.62, blue: 0.04))
                
                Text("Share Your Achievement")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Category selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Achievement Category")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
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
                            .foregroundColor(selectedAchievementCategory.isEmpty ? .white.opacity(0.5) : .white)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedAchievementCategory.isEmpty ? 
                                        Color.white.opacity(0.1) : 
                                        getCategoryColor(selectedAchievementCategory).opacity(0.4),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            
            // Description input
            if !selectedAchievementCategory.isEmpty {
                premiumTextInputField(
                    title: "Describe Your Achievement",
                    placeholder: "Tell us about your accomplishment...",
                    text: $postContent,
                    minHeight: 100,
                    maxHeight: 150
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var premiumMotivationInputSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 0.43, green: 0.34, blue: 0.91))
                
                Text("Share Inspiration")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Character count
                Text("\(postContent.count)/\(motivationCharacterLimit)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(
                        postContent.count > motivationCharacterLimit ? .red : .white.opacity(0.6)
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            premiumTextInputField(
                title: nil,
                placeholder: "Share a motivational quote or thought that inspires you...",
                text: $postContent,
                minHeight: 120,
                maxHeight: 200,
                characterLimit: motivationCharacterLimit
            )
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Premium Text Input Field
    @ViewBuilder
    private func premiumTextInputField(
        title: String?,
        placeholder: String,
        text: Binding<String>,
        minHeight: CGFloat,
        maxHeight: CGFloat,
        characterLimit: Int? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(minHeight: minHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                text.wrappedValue.isEmpty ? 
                                Color.white.opacity(0.1) : 
                                Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.4),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .scrollContentBackground(.hidden)
                    .onChange(of: text.wrappedValue) { newValue in
                        if let limit = characterLimit, newValue.count > limit {
                            text.wrappedValue = String(newValue.prefix(limit))
                        }
                    }
            }
        }
    }
    
    // MARK: - Premium Attachment Section
    @ViewBuilder
    private var premiumAttachmentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Image preview
            if let imagePreview {
                ZStack(alignment: .topTrailing) {
                    imagePreview
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.imagePreview = nil
                            self.selectedImageData = nil
                            self.selectedPhotoItem = nil
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(12)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
            }

            // Add photo button
            Button {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                showingAttachmentOptions = true
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.2),
                                        Color(red: 0.00, green: 0.83, blue: 1.00).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: selectedImageData == nil ? "plus.circle.fill" : "photo.badge.plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.43, green: 0.34, blue: 0.91),
                                        Color(red: 0.00, green: 0.83, blue: 1.00)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedImageData == nil ? "Add Photo" : "Change Photo")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Make your post more engaging")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.06),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Premium Post Button
    @ViewBuilder
    private var premiumPostButton: some View {
        Button(action: {
            handleCreatePost()
        }) {
            ZStack {
                if isPosting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Post")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 80, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        canPost() && !isPosting ?
                        LinearGradient(
                            colors: [
                                Color(red: 0.43, green: 0.34, blue: 0.91),
                                Color(red: 0.00, green: 0.83, blue: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: canPost() && !isPosting ? 
                        Color(red: 0.43, green: 0.34, blue: 0.91).opacity(0.4) : .clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .disabled(!canPost() || isPosting)
        .scaleEffect(canPost() && !isPosting ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canPost())
    }
    
    // MARK: - Helper Functions
    private var achievementCategories: [String] {
        premiumBadgeCategories().map { $0.name }.filter { $0 != "Achievements & Goals" }.sorted()
    }

    private func premiumBadgeCategoriesForType(_ type: PostType) -> [PremiumBadgeCategory] {
        return premiumBadgeCategories()
    }

    private func premiumBadgeCategories() -> [PremiumBadgeCategory] {
        return [
            PremiumBadgeCategory(
                name: "Fitness & Activity",
                iconName: "figure.run",
                color: Color(red: 0.13, green: 0.77, blue: 0.37),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .fitnessSteps10k, .fitnessSteps15k, .fitnessSteps20k, .fitnessCalories500, .fitnessCalories750, .fitnessCalories1000, .fitnessWorkout3days, .fitnessWorkout7days, .fitnessActiveMinutes30, .fitnessActiveMinutes60, .fitnessStairsClimbed:
                        return true
                    default: return false
                    }
                }
            ),
            PremiumBadgeCategory(
                name: "Nutrition & Health",
                iconName: "leaf.fill",
                color: Color(red: 0.02, green: 0.71, blue: 0.84),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .nutritionWater2L, .nutritionWater3L, .nutritionVeggie5servings, .nutritionMealLog5days, .nutritionSugarFreeDay, .nutritionProteinGoal, .nutritionHealthyBreakfast:
                        return true
                    default: return false
                    }
                }
            ),
            PremiumBadgeCategory(
                name: "Wellness & Mindfulness",
                iconName: "brain.head.profile",
                color: Color(red: 0.66, green: 0.33, blue: 0.97),
                badges: UITypeForPost.allCases.filter { uiType in
                    switch uiType {
                    case .wellnessMeditation5min, .wellnessMeditation15min, .wellnessSleep8hours, .wellnessStressFreeDay, .wellnessMindfulEating:
                        return true
                    default: return false
                    }
                }
            ),
            PremiumBadgeCategory(
                name: "Achievements & Goals",
                iconName: "trophy.fill",
                color: Color(red: 0.96, green: 0.62, blue: 0.04),
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
        return premiumBadgeCategories().first(where: { $0.name == categoryName })?.color ?? .gray
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
    
    private func resetContentForNewType(_ newType: PostType) {
        postContent = ""
        selectedAchievementCategory = ""
        
        if newType == .badge {
            selectedUIType = premiumBadgeCategoriesForType(.badge).first?.badges.first ?? UITypeForPost.fitnessSteps10k
            selectedBadgeName = selectedUIType.displayName
        } else {
            selectedBadgeName = ""
            selectedUIType = UITypeForPost.fitnessSteps10k
        }
    }
    
    private func startInitialAnimations() {
        // Start background animation
        withAnimation(.linear(duration: 0.1)) {
            backgroundParticleOffset = -UIScreen.main.bounds.height * 2
        }
        
        // Staggered content animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                hasAppearedOnce = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                typeSelectionAnimation = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                contentAnimation = true
            }
        }
    }
    
    @MainActor
    private func handleImageSelection(_ newItem: PhotosPickerItem?) async {
        guard let newItem else {
            selectedImageData = nil
            imagePreview = nil
            return
        }
        
        do {
            if let data = try await newItem.loadTransferable(type: Data.self) {
                selectedImageData = data
                if let uiImage = UIImage(data: data) {
                    imagePreview = Image(uiImage: uiImage)
                    
                    // Success feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                } else {
                    imagePreview = nil
                }
            } else {
                selectedImageData = nil
                imagePreview = nil
            }
        } catch {
            print("[CreatePostView] Error loading image: \(error)")
            selectedImageData = nil
            imagePreview = nil
            
            // Error feedback
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }
    
    private func handleCreatePost() {
        guard canPost(), let currentUserId = session.currentUserId, let currentUser = session.currentUser else {
            alertMessage = "Cannot create post. Please check your input or login status."
            showingAlert = true
            return
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
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
                    categoryForModel = premiumBadgeCategories().first(where: { $0.badges.contains(selectedUIType) })?.name
                    if categoryForModel == nil {
                         print("Error: Could not determine category for badge: \(selectedUIType.displayName)")
                         categoryForModel = "General"
                    }
                case .achievement:
                    categoryForModel = selectedAchievementCategory
                    contentForModel = postContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if selectedUIType.postTypeCategory == .achievement &&
                       premiumBadgeCategories().first(where: {$0.name == categoryForModel})?.badges.contains(selectedUIType) == true {
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
                    // Success feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    isPosting = false
                    alertMessage = "🎉 Post published successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    // Error feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.error)
                    
                    isPosting = false
                    if imageUploadErrorOccurred {
                        alertMessage = "Failed to upload image. Error: \(error.localizedDescription)"
                    } else {
                        alertMessage = "Failed to publish post: \(error.localizedDescription)"
                    }
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Premium Post Type Button
struct PremiumPostTypeButton: View {
    let postType: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    themeColorFor(postType: postType).opacity(0.3),
                                    themeColorFor(postType: postType).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? themeColorFor(postType: postType) : Color.white.opacity(0.1),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? themeColorFor(postType: postType).opacity(0.3) : .black.opacity(0.1),
                            radius: isSelected ? 12 : 6,
                            x: 0,
                            y: isSelected ? 6 : 3
                        )
                    
                    Image(systemName: iconNameFor(postType: postType))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            isSelected ?
                            LinearGradient(
                                colors: [themeColorFor(postType: postType), themeColorFor(postType: postType).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.7), Color.white.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .shadow(
                            color: isSelected ? themeColorFor(postType: postType).opacity(0.4) : .clear,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                }
                
                Text(displayNameFor(postType: postType))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(.plain)
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
        case .badge: return Color(red: 0.13, green: 0.77, blue: 0.37)
        case .achievement: return Color(red: 0.96, green: 0.62, blue: 0.04)
        case .motivation: return Color(red: 0.43, green: 0.34, blue: 0.91)
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionStore.previewStore(isLoggedIn: true)
        let postService = PostService.shared
        postService.configure(sessionStore: session)
        
        return CreatePostView()
            .environmentObject(session)
            .environmentObject(postService)
            .preferredColorScheme(.dark)
    }
}
#endif