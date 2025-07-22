import SwiftUI

struct WorkoutTypeSelectionView: View {
    @StateObject private var viewModel = WorkoutTypeSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onWorkoutTypeSelected: (WorkoutType) -> Void
    
    // MARK: - Animation States
    @State private var showContent = false
    @State private var selectedDifficulty: DifficultyLevel? = nil
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                // Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                        searchAndFiltersSection
                        workoutTypesGrid
                        Spacer(minLength: 100)
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation Bar
            HStack {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Title Section
            VStack(spacing: 12) {
                Text("Choose Your")
                    .font(.system(size: 32, weight: .light, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Workout Type")
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(.white)
                
                Text("Find the perfect workout that matches your mood and fitness goals")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Search and Filters Section
    @ViewBuilder
    private var searchAndFiltersSection: some View {
        VStack(spacing: 20) {
            // Search Bar
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search workouts...", text: $searchText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .tint(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            
            // Difficulty Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    DifficultyFilterChip(
                        title: "All",
                        isSelected: selectedDifficulty == nil
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDifficulty = nil
                        }
                    }
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        DifficultyFilterChip(
                            title: difficulty.displayName,
                            emoji: difficulty.emoji,
                            color: Color(hex: difficulty.color),
                            isSelected: selectedDifficulty == difficulty
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDifficulty = difficulty
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Workout Types Grid
    @ViewBuilder
    private var workoutTypesGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 16
        ) {
            ForEach(Array(filteredWorkoutTypes.enumerated()), id: \.element) { index, workoutType in
                WorkoutTypeCategoryCard(
                    workoutType: workoutType,
                    workoutCount: viewModel.getWorkoutCount(for: workoutType),
                    animationDelay: Double(index) * 0.1
                ) {
                    // Navigate to Exercise Selection
                    dismiss()
                    onWorkoutTypeSelected(workoutType)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Computed Properties
    private var filteredWorkoutTypes: [WorkoutType] {
        let types = WorkoutType.allCases
        
        var filtered = types
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { type in
                type.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
}

// MARK: - Workout Type Category Card
struct WorkoutTypeCategoryCard: View {
    let workoutType: WorkoutType
    let workoutCount: Int
    let animationDelay: Double
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var showCard = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Image Section with Clean Background Image
                ZStack {
                    // Background Image from Assets
                    Image(workoutType.backgroundImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 20)
                        )
                        .overlay(
                            // Minimal dark overlay for text visibility only
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.black.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .bottom,
                                        endPoint: .center
                                    )
                                )
                        )
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutType.displayName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text("\(workoutCount) workouts")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: workoutType.primaryColor))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .shadow(
            color: Color(hex: workoutType.primaryColor).opacity(0.3),
            radius: 20,
            x: 0,
            y: 10
        )
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 30)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(animationDelay)) {
                showCard = true
            }
        }
        .onLongPressGesture(minimumDuration: 0.0) {
            // This won't execute, but the gesture recognizes the press
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

// MARK: - Difficulty Filter Chip
struct DifficultyFilterChip: View {
    let title: String
    let emoji: String?
    let color: Color?
    let isSelected: Bool
    let onTap: () -> Void
    
    init(
        title: String,
        emoji: String? = nil,
        color: Color? = nil,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.emoji = emoji
        self.color = color
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected ? 
                        (color ?? .white) : 
                        Color.clear
                    )
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(isSelected ? 1.0 : 0.8)
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? 
                                .clear : 
                                .white.opacity(0.2), 
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model
@MainActor
class WorkoutTypeSelectionViewModel: ObservableObject {
    @Published var workoutCounts: [WorkoutType: Int] = [:]
    @Published var isLoading = false
    
    private let workoutService = WorkoutService.shared
    
    init() {
        loadWorkoutCounts()
    }
    
    func loadWorkoutCounts() {
        isLoading = true
        
        Task {
            await calculateWorkoutCounts()
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func calculateWorkoutCounts() async {
        print("[WorkoutTypeSelectionVM] 📊 Calculating workout counts from Firebase templates")
        
        // Wait for templates to load if needed
        var attempts = 0
        let maxAttempts = 10
        
        while workoutService.workoutTemplates.isEmpty && attempts < maxAttempts {
            print("[WorkoutTypeSelectionVM] ⏳ Waiting for Firebase templates... (attempt \(attempts + 1))")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            attempts += 1
        }
        
        var counts: [WorkoutType: Int] = [:]
        
        // Count exercises for each workout type from Firebase templates
        for workoutType in WorkoutType.allCases {
            let matchingTemplates = workoutService.workoutTemplates.filter { template in
                template.workoutType == workoutType
            }
            
            let exerciseCount = matchingTemplates.reduce(0) { total, template in
                total + template.exercises.count
            }
            
            counts[workoutType] = exerciseCount
            print("[WorkoutTypeSelectionVM] 📋 \(workoutType.displayName): \(exerciseCount) exercises")
        }
        
        await MainActor.run {
            self.workoutCounts = counts
        }
        
        print("[WorkoutTypeSelectionVM] ✅ Workout counts calculated successfully")
    }
    
    func getWorkoutCount(for workoutType: WorkoutType) -> Int {
        return workoutCounts[workoutType] ?? 0
    }
    
    func retryLoadingCounts() {
        loadWorkoutCounts()
    }
}

#Preview {
    WorkoutTypeSelectionView { workoutType in
        print("Selected: \(workoutType.displayName)")
    }
}