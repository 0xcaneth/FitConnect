import SwiftUI

// MARK: - View Model
class ExerciseSelectionViewModel: ObservableObject {
    @Published var exercises: [WorkoutExercise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var networkError = false
    
    func loadExercises(for workoutType: WorkoutType) {
        print("[ExerciseSelectionVM] 🚀 Loading exercises for: \(workoutType.displayName)")
        
        isLoading = true
        errorMessage = nil
        networkError = false
        
        // Get exercises from WorkoutService Firebase data
        Task { @MainActor in
            do {
                print("[ExerciseSelectionVM] 📡 Getting WorkoutService instance...")
                let workoutService = WorkoutService.shared
                
                print("[ExerciseSelectionVM] 🔍 Available templates: \(workoutService.workoutTemplates.count)")
                print("[ExerciseSelectionVM] 📋 Available workouts: \(workoutService.availableWorkouts.count)")
                
                let exercises = await getExercisesFromFirebase(for: workoutType, workoutService: workoutService)
                
                print("[ExerciseSelectionVM] 📊 Got \(exercises.count) exercises from Firebase")
                
                if exercises.isEmpty {
                    print("[ExerciseSelectionVM] ⚠️ No exercises found!")
                    self.errorMessage = "No exercises available for \(workoutType.displayName) at the moment. Please check back later."
                    self.networkError = true
                } else {
                    print("[ExerciseSelectionVM] ✅ Setting \(exercises.count) exercises")
                    self.exercises = exercises
                }
            } catch {
                print("[ExerciseSelectionVM] ❌ Error loading exercises: \(error)")
                self.errorMessage = "Unable to load exercises. Please check your connection and try again."
                self.networkError = true
            }
            
            print("[ExerciseSelectionVM] 🏁 Loading finished. isLoading = false")
            self.isLoading = false
        }
    }
    
    @MainActor
    private func getExercisesFromFirebase(for workoutType: WorkoutType, workoutService: WorkoutService) async -> [WorkoutExercise] {
        print("[ExerciseSelectionVM] Loading exercises for: \(workoutType.rawValue)")
        print("[ExerciseSelectionVM] Available templates: \(workoutService.workoutTemplates.count)")
        
        // Wait for templates if they're still loading
        var attempts = 0
        while workoutService.workoutTemplates.isEmpty && attempts < 10 {
            print("[ExerciseSelectionVM] Waiting for Firebase templates... (attempt \(attempts + 1))")
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            attempts += 1
        }
        
        // Get exercises from Firebase workout templates
        let matchingWorkouts = workoutService.workoutTemplates.filter { template in
            template.workoutType == workoutType
        }
        
        print("[ExerciseSelectionVM] Found \(matchingWorkouts.count) templates for \(workoutType.rawValue)")
        
        var allExercises: [WorkoutExercise] = []
        
        for workout in matchingWorkouts {
            print("[ExerciseSelectionVM] Processing: \(workout.name) (\(workout.exercises.count) exercises)")
            allExercises.append(contentsOf: workout.exercises)
        }
        
        print("[ExerciseSelectionVM] Total exercises loaded: \(allExercises.count)")
        return allExercises
    }
    
    func retryLoading(for workoutType: WorkoutType) {
        loadExercises(for: workoutType)
    }
    
    func getFilteredExercises(
        for workoutType: WorkoutType,
        muscleGroup: MuscleGroup?,
        difficulty: DifficultyLevel?,
        searchText: String
    ) -> [WorkoutExercise] {
        var filtered = exercises
        
        // Filter by muscle group
        if let muscleGroup = muscleGroup {
            filtered = filtered.filter { exercise in
                exercise.targetMuscleGroups.contains(muscleGroup)
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.description?.localizedCaseInsensitiveContains(searchText) ?? false ||
                exercise.targetMuscleGroups.contains { muscle in
                    muscle.displayName.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
}

struct ExerciseSelectionView: View {
    let workoutType: WorkoutType
    let onExercisesSelected: ([WorkoutExercise]) -> Void
    let onDismiss: (() -> Void)?
    @Binding var showExerciseSelection: Bool
    @StateObject private var viewModel = ExerciseSelectionViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // Default initializer (backward compatibility)
    init(workoutType: WorkoutType, onExercisesSelected: @escaping ([WorkoutExercise]) -> Void) {
        self.workoutType = workoutType
        self.onExercisesSelected = onExercisesSelected
        self.onDismiss = nil
        _showExerciseSelection = .constant(true)
    }
    
    // New initializer with custom dismiss handler
    init(workoutType: WorkoutType, onExercisesSelected: @escaping ([WorkoutExercise]) -> Void, onDismiss: (() -> Void)?) {
        self.workoutType = workoutType
        self.onExercisesSelected = onExercisesSelected
        self.onDismiss = onDismiss
        _showExerciseSelection = .constant(true)
    }
    
    // UI States
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var searchText = ""
    @State private var selectedExercises: Set<UUID> = []
    @State private var showingExerciseDetail = false
    @State private var selectedExercise: WorkoutExercise?
    @State private var showCustomWorkoutBuilder = false
    @State private var showWorkoutExecution = false
    @State private var builtWorkout: [WorkoutExercise] = []
    
    // Animation states
    @State private var showContent = false
    @State private var headerAnimation = false
    
    var filteredExercises: [WorkoutExercise] {
        viewModel.getFilteredExercises(
            for: workoutType,
            muscleGroup: selectedMuscleGroup,
            difficulty: selectedDifficulty,
            searchText: searchText
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                // Content
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search and Filters
                    searchAndFiltersSection
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Exercise List
                    exerciseListSection
                    
                    // Bottom Action Bar
                    if !selectedExercises.isEmpty {
                        bottomActionBar
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("[ExerciseSelection] 📱 ExerciseSelectionView appeared for: \(workoutType.displayName)")
            print("[ExerciseSelection] 🚀 ExerciseSelectionView body building for: \(workoutType.displayName)")
            viewModel.loadExercises(for: workoutType)
            
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
                headerAnimation = true
            }
        }
        .sheet(isPresented: $showingExerciseDetail) {
            if let exercise = selectedExercise {
                ExerciseDetailView(exercise: exercise) { action in
                    handleExerciseDetailAction(action, for: exercise)
                }
            }
        }
        .sheet(isPresented: $showCustomWorkoutBuilder) {
            CustomWorkoutBuilderView(
                selectedExercises: selectedExercises.compactMap { id in
                    viewModel.exercises.first { $0.id == id }
                },
                workoutType: workoutType
            ) { customWorkout in
                print("[ExerciseSelection] 🏗️ Custom workout built with \(customWorkout.count) exercises")
                builtWorkout = customWorkout
                showCustomWorkoutBuilder = false
                
                // Start workout execution immediately
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showWorkoutExecution = true
                }
            }
        }
        .fullScreenCover(isPresented: $showWorkoutExecution) {
            if !builtWorkout.isEmpty {
                WorkoutExecutionView(
                    workout: createWorkoutSession(from: builtWorkout),
                    onWorkoutComplete: { completionData in
                        // Handle workout completion - save to Firebase
                        handleWorkoutCompletion(completionData)
                        showWorkoutExecution = false
                        showExerciseSelection = false
                    },
                    onDismiss: {
                        // User exited without saving
                        showWorkoutExecution = false
                    }
                )
            }
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Gradient overlay based on workout type
            LinearGradient(
                colors: [
                    Color(hex: workoutType.primaryColor).opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation Bar
            HStack {
                Button(action: { 
                    // Use custom dismiss handler if provided, otherwise use environment dismiss
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Exercise count badge
                Text("\(filteredExercises.count) exercises")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                
                Spacer()
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Title Section
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: workoutType.primaryColor))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: workoutType.icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(headerAnimation ? 1.0 : 0.8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workoutType.displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose your exercises")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(headerAnimation ? 1.0 : 0.0)
                    .offset(x: headerAnimation ? 0 : -20)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Search and Filters Section
    @ViewBuilder
    private var searchAndFiltersSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search exercises...", text: $searchText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .tint(Color(hex: workoutType.primaryColor))
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
                
                if !selectedExercises.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedExercises.removeAll()
                        }
                    }) {
                        Text("Clear")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: workoutType.primaryColor))
                    }
                }
            }
            
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Muscle Group Filters
                    FilterChip(
                        title: "All Muscles",
                        isSelected: selectedMuscleGroup == nil,
                        color: Color(hex: workoutType.primaryColor)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedMuscleGroup = nil
                        }
                    }
                    
                    ForEach(MuscleGroup.allCases.filter { $0 != .cardio }, id: \.self) { muscle in
                        FilterChip(
                            title: muscle.displayName,
                            emoji: nil,
                            isSelected: selectedMuscleGroup == muscle,
                            color: Color(hex: workoutType.primaryColor)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedMuscleGroup = selectedMuscleGroup == muscle ? nil : muscle
                            }
                        }
                    }
                    
                    // Difficulty Filters
                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 1, height: 30)
                    
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        FilterChip(
                            title: difficulty.displayName,
                            emoji: difficulty.emoji,
                            isSelected: selectedDifficulty == difficulty,
                            color: Color(hex: difficulty.color)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
    
    // MARK: - Exercise List Section
    @ViewBuilder
    private var exerciseListSection: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ForEach(0..<6, id: \.self) { _ in
                        ExerciseCardSkeleton()
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.top, 20)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorStateView(
                    message: errorMessage,
                    isNetworkError: viewModel.networkError,
                    workoutType: workoutType
                ) {
                    print("[ExerciseSelection] 🔄 Retry button tapped")
                    viewModel.retryLoading(for: workoutType)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
            } else if filteredExercises.isEmpty {
                EmptyExerciseState(
                    searchText: searchText,
                    selectedMuscleGroup: selectedMuscleGroup,
                    workoutType: workoutType
                )
                .padding(.horizontal, 20)
                .padding(.top, 60)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(filteredExercises.enumerated()), id: \.element.id) { index, exercise in
                            ExerciseCard(
                                exercise: exercise,
                                isSelected: selectedExercises.contains(exercise.id),
                                workoutTypeColor: Color(hex: workoutType.primaryColor),
                                animationDelay: Double(index) * 0.05
                            ) { action in
                                handleExerciseAction(action, for: exercise)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, selectedExercises.isEmpty ? 100 : 160)
                }
            }
        }
        .onChange(of: viewModel.isLoading) { isLoading in
            print("[ExerciseSelection] Loading state changed: \(isLoading)")
        }
        .onChange(of: filteredExercises.count) { count in
            print("[ExerciseSelection] Filtered exercises count: \(count)")
        }
    }
    
    // MARK: - Bottom Action Bar
    @ViewBuilder
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)
                .opacity(0.3)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedExercises.count) exercises selected")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Ready to build your workout")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    showCustomWorkoutBuilder = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Build Workout")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: workoutType.primaryColor))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Helper Methods
    private func handleExerciseAction(_ action: ExerciseCard.Action, for exercise: WorkoutExercise) {
        switch action {
        case .tap:
            selectedExercise = exercise
            showingExerciseDetail = true
            
        case .select:
            withAnimation(.spring(response: 0.3)) {
                if selectedExercises.contains(exercise.id) {
                    selectedExercises.remove(exercise.id)
                } else {
                    selectedExercises.insert(exercise.id)
                }
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
    
    private func handleExerciseDetailAction(_ action: ExerciseDetailView.Action, for exercise: WorkoutExercise) {
        switch action {
        case .addToWorkout:
            withAnimation(.spring(response: 0.3)) {
                selectedExercises.insert(exercise.id)
            }
            showingExerciseDetail = false
            
        case .dismiss:
            showingExerciseDetail = false
        }
    }
    
    // MARK: - NEW Helper Methods for Workout Execution
    
    private func createWorkoutSession(from exercises: [WorkoutExercise]) -> WorkoutSession {
        let estimatedDuration = exercises.reduce(0) { total, exercise in
            if exercise.isTimeBasedExercise {
                return total + (exercise.duration ?? 30)
            } else {
                let setsTime = TimeInterval((exercise.sets ?? 3) * (exercise.reps ?? 10) * 3) // 3 seconds per rep
                let restTime = TimeInterval((exercise.sets ?? 3) * 15) // 15 seconds rest between sets
                return total + setsTime + restTime
            }
        }
        
        let estimatedCalories = Int(estimatedDuration / 60 * 8) // 8 calories per minute average
        
        return WorkoutSession(
            userId: "", // Will be set by WorkoutService
            workoutType: workoutType,
            name: "\(workoutType.displayName) Workout",
            description: "Custom workout with \(exercises.count) exercises",
            estimatedDuration: estimatedDuration,
            estimatedCalories: estimatedCalories,
            difficulty: .intermediate, // Could be calculated based on exercises
            targetMuscleGroups: Array(Set(exercises.flatMap { $0.targetMuscleGroups })),
            exercises: exercises,
            imageURL: nil
        )
    }
    
    private func handleWorkoutCompletion(_ completionData: WorkoutCompletionData) {
        print("[ExerciseSelection] 🎉 Workout completed! Duration: \(Int(completionData.totalDuration/60)) min, Calories: \(completionData.totalCaloriesBurned)")
        
        // Save to Firebase via WorkoutService
        Task {
            let workoutService = WorkoutService.shared
            let result = await workoutService.completeWorkout(
                workoutId: completionData.workoutId ?? UUID().uuidString,
                actualDuration: completionData.totalDuration,
                actualCalories: completionData.totalCaloriesBurned,
                rating: completionData.userRating
            )
            
            switch result {
            case .success():
                print("[ExerciseSelection] ✅ Workout data saved successfully")
                
                // Call the original callback to close all sheets
                onExercisesSelected([]) // Empty array since workout is already completed
                
            case .failure(let error):
                print("[ExerciseSelection] ❌ Failed to save workout: \(error)")
                // Still call callback to close sheets
                onExercisesSelected([])
            }
        }
    }
}

// MARK: - Exercise Card Component
struct ExerciseCard: View {
    let exercise: WorkoutExercise
    let isSelected: Bool
    let workoutTypeColor: Color
    let animationDelay: Double
    let onAction: (Action) -> Void
    
    @State private var showCard = false
    @State private var isPressed = false
    
    enum Action {
        case tap, select
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Thumbnail - Using fallback gradient design
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                workoutTypeColor.opacity(0.3),
                                workoutTypeColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // Exercise icon overlay
                Image(systemName: exercise.exerciseIcon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Exercise Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Selection indicator
                    Button(action: { onAction(.select) }) {
                        ZStack {
                            Circle()
                                .fill(isSelected ? workoutTypeColor : .white.opacity(0.2))
                                .frame(width: 24, height: 24)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Exercise info
                if let sets = exercise.sets, let reps = exercise.reps {
                    Text("\(sets) sets • \(reps) reps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(workoutTypeColor)
                } else if let duration = exercise.duration {
                    Text(exercise.formattedDuration ?? "")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(workoutTypeColor)
                }
                
                // Muscle groups
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(exercise.targetMuscleGroups.prefix(3)), id: \.self) { muscle in
                            Text(muscle.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.white.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // Info button
            Button(action: { onAction(.tap) }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? workoutTypeColor : .white.opacity(0.1),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(animationDelay)) {
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

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let emoji: String?
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    init(title: String, emoji: String? = nil, isSelected: Bool, color: Color, onTap: @escaping () -> Void) {
        self.title = title
        self.emoji = emoji
        self.isSelected = isSelected
        self.color = color
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
                    .fill(isSelected ? color : .white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Exercise Card Skeleton
struct ExerciseCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail skeleton
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(width: 80, height: 80)
                .opacity(isAnimating ? 0.5 : 1.0)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
                    .frame(height: 20)
                    .opacity(isAnimating ? 0.5 : 1.0)
                
                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 14)
                    .opacity(isAnimating ? 0.5 : 1.0)
                
                // Tags skeleton
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 24)
                            .opacity(isAnimating ? 0.5 : 1.0)
                    }
                    Spacer()
                }
            }
            
            // Info button skeleton
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 24, height: 24)
                .opacity(isAnimating ? 0.5 : 1.0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.3))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Empty Exercise State
struct EmptyExerciseState: View {
    let searchText: String
    let selectedMuscleGroup: MuscleGroup?
    let workoutType: WorkoutType
    
    var body: some View {
        VStack(spacing: 24) {
            // Empty state icon
            ZStack {
                Circle()
                    .fill(Color(hex: workoutType.primaryColor).opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(Color(hex: workoutType.primaryColor).opacity(0.6))
            }
            
            VStack(spacing: 12) {
                Text(emptyStateTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No exercises found"
        } else if selectedMuscleGroup != nil {
            return "No exercises for this muscle group"
        } else {
            return "Coming Soon!"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters to find exercises."
        } else if selectedMuscleGroup != nil {
            return "Try selecting a different muscle group or remove filters to see all exercises."
        } else {
            return "We're adding more \(workoutType.displayName.lowercased()) exercises. Check back soon for updates!"
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let message: String
    let isNetworkError: Bool
    let workoutType: WorkoutType
    let onRetry: () -> Void
    
    @State private var showRetryAnimation = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: isNetworkError ? "wifi.slash" : "exclamationmark.triangle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.red.opacity(0.6))
                    .scaleEffect(showRetryAnimation ? 1.1 : 1.0)
            }
            
            VStack(spacing: 12) {
                Text(isNetworkError ? "Connection Issue" : "Something went wrong")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Retry button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    showRetryAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showRetryAnimation = false
                    onRetry()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .rotationEffect(.degrees(showRetryAnimation ? 360 : 0))
                    
                    Text("Try Again")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(hex: workoutType.primaryColor))
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                showRetryAnimation = true
            }
        }
    }
}

#if DEBUG
struct ExerciseSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseSelectionView(workoutType: .strength) { exercises in
            print("Selected \(exercises.count) exercises")
        }
    }
}
#endif