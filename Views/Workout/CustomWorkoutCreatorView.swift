import SwiftUI

@available(iOS 16.0, *)
struct CustomWorkoutCreatorView: View {
    let onWorkoutCreated: (WorkoutSession) -> Void
    let onDismiss: () -> Void
    
    @StateObject private var workoutService = WorkoutService.shared
    @EnvironmentObject private var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    
    // Workout creation states
    @State private var workoutName: String = ""
    @State private var selectedWorkoutType: WorkoutType = .cardio
    @State private var selectedDifficulty: DifficultyLevel = .beginner
    @State private var selectedExercises: [WorkoutExercise] = []
    @State private var showingExercisePicker = false
    @State private var exercisePickerWorkoutType: WorkoutType = .cardio
    
    // UI states
    @State private var currentStep: CreationStep = .basic
    @State private var showingPreview = false
    @State private var isCreatingWorkout = false
    
    enum CreationStep: Int, CaseIterable {
        case basic = 0
        case exercises = 1
        case customize = 2
        case preview = 3
        
        var title: String {
            switch self {
            case .basic: return "Workout Info"
            case .exercises: return "Select Exercises"
            case .customize: return "Customize"
            case .preview: return "Preview"
            }
        }
        
        var description: String {
            switch self {
            case .basic: return "Name your workout and set the basics"
            case .exercises: return "Choose exercises for your workout"
            case .customize: return "Fine-tune sets, reps, and timing"
            case .preview: return "Review before creating"
            }
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .basic:
            return !workoutName.trimmingCharacters(in: .whitespaces).isEmpty
        case .exercises:
            return !selectedExercises.isEmpty
        case .customize, .preview:
            return true
        }
    }
    
    // FIXED: Completely rewritten duration calculation to match exact user expectations
    private var estimatedDuration: Int {
        guard !selectedExercises.isEmpty else { return 0 }
        
        var totalSeconds = 0
        
        print("[Duration] Calculating duration for \(selectedExercises.count) exercises:")
        
        for (index, exercise) in selectedExercises.enumerated() {
            print("[Duration] Exercise \(index + 1): \(exercise.name)")
            
            var exerciseSeconds = 0
            
            if let duration = exercise.duration {
                // Time-based exercise - just add the duration
                exerciseSeconds = Int(duration)
                print("[Duration]   - Time-based: \(exerciseSeconds)s")
            } else {
                // Rep-based exercise calculation
                let sets = exercise.sets ?? 1
                let reps = exercise.reps ?? 10
                let timePerRep = 3 // seconds per rep
                exerciseSeconds = sets * reps * timePerRep
                print("[Duration]   - Rep-based: \(sets) sets × \(reps) reps × 3s = \(exerciseSeconds)s")
            }
            
            totalSeconds += exerciseSeconds
            
            // Add rest time AFTER each exercise (except the last one)
            if index < selectedExercises.count - 1 {
                let restSeconds = Int(exercise.restTime ?? 15) // Default 15s rest
                totalSeconds += restSeconds
                print("[Duration]   - Rest after: \(restSeconds)s")
            }
            
            print("[Duration]   - Running total: \(totalSeconds)s")
        }
        
        print("[Duration] Final total: \(totalSeconds)s (\(totalSeconds/60)m \(totalSeconds%60)s)")
        return totalSeconds
    }

    // FIXED: Simplified calorie calculation
    private var estimatedCalories: Int {
        guard estimatedDuration > 0 else { return 0 }
        
        var totalCalories = 0.0
        
        for exercise in selectedExercises {
            let caloriesPerMinute: Double
            
            switch exercise.exerciseType {
            case .strength:
                caloriesPerMinute = 8.0
            case .cardio:
                caloriesPerMinute = 12.0
            case .plyometric:
                caloriesPerMinute = 15.0
            case .endurance:
                caloriesPerMinute = 10.0
            default:
                caloriesPerMinute = 6.0
            }
            
            let exerciseDurationInMinutes: Double
            if let duration = exercise.duration {
                exerciseDurationInMinutes = duration / 60.0
            } else {
                let sets = exercise.sets ?? 1
                let reps = exercise.reps ?? 10
                let totalTime = sets * reps * 3 + Int(exercise.restTime ?? 30) * max(sets - 1, 0)
                exerciseDurationInMinutes = Double(totalTime) / 60.0
            }
            
            totalCalories += caloriesPerMinute * exerciseDurationInMinutes
        }
        
        return Int(totalCalories)
    }
    
    // Memoized formatted duration for better performance
    private var formattedDuration: String {
        let totalSeconds = estimatedDuration
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
    
    // FIXED: Simplified muscle groups function
    private var getTargetMuscleGroups: [MuscleGroup] {
        var uniqueGroups = Set<MuscleGroup>()
        
        for exercise in selectedExercises {
            for group in exercise.targetMuscleGroups {
                uniqueGroups.insert(group)
            }
        }
        
        return Array(uniqueGroups)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(hex: "#0B0D17"),
                        Color(hex: "#1A1B25"),
                        Color(hex: "#2A2B35")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping outside
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Step content with keyboard handling
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            stepContent
                                .padding(.horizontal, 24)
                                .padding(.top, 32)
                            
                            // Extra bottom padding for keyboard
                            Spacer(minLength: 200)
                        }
                    }
                    .onTapGesture {
                        // Dismiss keyboard when scrolling area is tapped
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { _ in
                                // Dismiss keyboard immediately when scrolling starts
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        onDismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentStep == .preview {
                        Button("Create") {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            createWorkout()
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.1))
                        .disabled(isCreatingWorkout)
                    }
                }
            }
        }
        // Fixed bottom button overlay
        .overlay(alignment: .bottom) {
            fixedBottomActionBar
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExerciseSelectionView(
                workoutType: exercisePickerWorkoutType,
                allowMultipleSelection: true,
                preSelectedExercises: selectedExercises,
                onExercisesSelected: { exercises in
                    selectedExercises = exercises
                    showingExercisePicker = false
                },
                onDismiss: {
                    showingExercisePicker = false
                }
            )
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
        }
    }
    
    // MARK: - Progress Header
    
    @ViewBuilder
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Step indicators
            HStack {
                ForEach(CreationStep.allCases, id: \.rawValue) { step in
                    HStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? 
                                  Color(red: 0.3, green: 0.7, blue: 0.1) : 
                                  Color.white.opacity(0.3))
                            .frame(width: 12, height: 12)
                        
                        if step != CreationStep.allCases.last {
                            Rectangle()
                                .fill(step.rawValue < currentStep.rawValue ? 
                                      Color(red: 0.3, green: 0.7, blue: 0.1) : 
                                      Color.white.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Step info
            VStack(spacing: 4) {
                Text(currentStep.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(currentStep.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Material.ultraThinMaterial)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .basic:
            basicInfoStep
        case .exercises:
            exerciseSelectionStep
        case .customize:
            customizationStep
        case .preview:
            previewStep
        }
    }
    
    @ViewBuilder
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Workout name
            VStack(alignment: .leading, spacing: 12) {
                Text("Workout Name")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                TextField("e.g. My Upper Body Blast", text: $workoutName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)
                    .submitLabel(.done)
                    .onSubmit {
                        // Move to next step when done is pressed
                        if canProceedToNextStep {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if let nextStep = CreationStep(rawValue: currentStep.rawValue + 1) {
                                    currentStep = nextStep
                                }
                            }
                        }
                    }
            }
            
            // Workout type selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Workout Type")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        workoutTypeButton(for: type)
                    }
                }
            }
            
            // Difficulty selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Difficulty Level")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        difficultyButton(for: difficulty)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var exerciseSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            if selectedExercises.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white.opacity(0.4))
                        
                        VStack(spacing: 8) {
                            Text("Add Exercises")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Select exercises from different categories\nto build your custom workout")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Exercise category buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(WorkoutType.allCases.prefix(6)), id: \.self) { type in
                            Button(action: {
                                exercisePickerWorkoutType = type
                                showingExercisePicker = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(type.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: type.primaryColor).opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: type.primaryColor).opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                }
            } else {
                // Selected exercises list
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Selected Exercises (\(selectedExercises.count))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Add More") {
                            exercisePickerWorkoutType = selectedWorkoutType
                            showingExercisePicker = true
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.3, green: 0.7, blue: 0.1))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.3, green: 0.7, blue: 0.1).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color(red: 0.3, green: 0.7, blue: 0.1), lineWidth: 1)
                                )
                        )
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                            CustomWorkoutExerciseRow(
                                exercise: exercise,
                                index: index + 1,
                                onRemove: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedExercises.removeAll { $0.id == exercise.id }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var customizationStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Fine-tune Your Workout")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            if !selectedExercises.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                        CustomizableExerciseCard(
                            exercise: exercise,
                            onUpdate: { updatedExercise in
                                selectedExercises[index] = updatedExercise
                            }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var previewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Workout summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Workout Summary")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workoutName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                Text(selectedWorkoutType.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: selectedWorkoutType.primaryColor))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(selectedDifficulty.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: selectedDifficulty.color))
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(selectedExercises.count) exercises")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // FIXED: Simple identifier for UI refresh
                            Text("\(formattedDuration) • \(estimatedCalories) kcal")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .id("workout-stats-\(selectedExercises.count)")
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    
                }
            }
            
            // Exercise list preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Exercise Breakdown")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                LazyVStack(spacing: 8) {
                    ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { index, exercise in
                        WorkoutPreviewExerciseRow(
                            exercise: exercise,
                            index: index + 1
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Bottom Action Bar
    
    @ViewBuilder
    private var bottomActionBar: some View {
        // This is now empty since we use fixedBottomActionBar
        EmptyView()
    }
    
    // MARK: - Fixed Bottom Action Bar (Always Visible)
    
    @ViewBuilder
    private var fixedBottomActionBar: some View {
        VStack(spacing: 0) {
            // Gradient fade effect
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "#1A1B25").opacity(0.8),
                    Color(hex: "#1A1B25")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            // Action buttons container
            HStack(spacing: 12) {
                // Previous Button
                if currentStep.rawValue > 0 {
                    Button(action: {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep = CreationStep(rawValue: currentStep.rawValue - 1) ?? .basic
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Previous")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .transition(.opacity.combined(with: .scale))
                }
                
                // Next/Create Button
                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    
                    if currentStep == .preview {
                        createWorkout()
                    } else {
                        // Fast animation for better responsiveness
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if let nextStep = CreationStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = nextStep
                            }
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(currentStep == .preview ? "Create Workout" : "Next")
                            .font(.system(size: 16, weight: .bold))
                        
                        if currentStep != .preview {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                canProceedToNextStep ? 
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.8, blue: 0.2),
                                        Color(red: 0.3, green: 0.7, blue: 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) : 
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: canProceedToNextStep ? 
                                Color(red: 0.3, green: 0.7, blue: 0.1).opacity(0.3) : 
                                Color.clear, 
                                radius: 8, 
                                x: 0, 
                                y: 4
                            )
                    )
                }
                .disabled(!canProceedToNextStep || isCreatingWorkout)
                .scaleEffect(canProceedToNextStep ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.2), value: canProceedToNextStep)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                Color(hex: "#1A1B25")
                    .ignoresSafeArea(.container, edges: .bottom)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createWorkout() {
        guard let userId = session.currentUserId else { return }
        
        isCreatingWorkout = true
        
        let customWorkout = WorkoutSession(
            userId: userId,
            workoutType: selectedWorkoutType,
            name: workoutName,
            description: "Custom workout created by user",
            estimatedDuration: TimeInterval(estimatedDuration),
            estimatedCalories: estimatedCalories,
            difficulty: selectedDifficulty,
            targetMuscleGroups: getTargetMuscleGroups, 
            exercises: selectedExercises
        )
        
        // Delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCreatingWorkout = false
            onWorkoutCreated(customWorkout)
        }
        logPerformance("Workout created: \(workoutName)")
    }
    
    @ViewBuilder
    private func workoutTypeButton(for type: WorkoutType) -> some View {
        let isSelected = selectedWorkoutType == type
        let primaryColor = Color(hex: type.primaryColor)
        
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            selectedWorkoutType = type
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(type.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? primaryColor.opacity(0.3) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? primaryColor : .white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func difficultyButton(for difficulty: DifficultyLevel) -> some View {
        let isSelected = selectedDifficulty == difficulty
        let difficultyColor = Color(hex: difficulty.color)
        
        Button(action: {
            selectedDifficulty = difficulty
        }) {
            VStack(spacing: 6) {
                Text(difficulty.emoji)
                    .font(.system(size: 20))
                
                Text(difficulty.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? difficultyColor.opacity(0.3) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? difficultyColor : .white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct CustomWorkoutExerciseRow: View {
    let exercise: WorkoutExercise
    let index: Int
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Exercise number
            Text("\(index)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color(red: 0.3, green: 0.7, blue: 0.1).opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack {
                    if let sets = exercise.sets, let reps = exercise.reps {
                        Text("\(sets) sets × \(reps) reps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    } else if let duration = exercise.duration {
                        Text("\(Int(duration))s")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(.red.opacity(0.2))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct CustomizableExerciseCard: View {
    let exercise: WorkoutExercise
    let onUpdate: (WorkoutExercise) -> Void
    
    @State private var sets: Int
    @State private var reps: Int
    @State private var duration: Int
    @State private var restTime: Int
    
    init(exercise: WorkoutExercise, onUpdate: @escaping (WorkoutExercise) -> Void) {
        self.exercise = exercise
        self.onUpdate = onUpdate
        
        self._sets = State(initialValue: exercise.sets ?? 3)
        self._reps = State(initialValue: exercise.reps ?? 10)
        self._duration = State(initialValue: Int(exercise.duration ?? 30))
        self._restTime = State(initialValue: Int(exercise.restTime ?? 60))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(exercise.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            if exercise.isTimeBasedExercise {
                // Time-based exercise controls
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Button("-") {
                                if duration > 10 {
                                    duration -= 10
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                            
                            Text("\(duration)s")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 40)
                            
                            Button("+") {
                                if duration < 300 {
                                    duration += 10
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                        }
                    }
                    
                    Spacer()
                }
            } else {
                // Sets and reps controls
                HStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sets")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Button("-") {
                                if sets > 1 {
                                    sets -= 1
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                            
                            Text("\(sets)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 30)
                            
                            Button("+") {
                                if sets < 10 {
                                    sets += 1
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack {
                            Button("-") {
                                if reps > 1 {
                                    reps -= 1
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                            
                            Text("\(reps)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 30)
                            
                            Button("+") {
                                if reps < 50 {
                                    reps += 1
                                    updateExercise()
                                }
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(.white.opacity(0.2)))
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func updateExercise() {
        let updatedExercise = WorkoutExercise(
            name: exercise.name,
            description: exercise.description,
            exerciseType: exercise.exerciseType,
            targetMuscleGroups: exercise.targetMuscleGroups,
            sets: exercise.isTimeBasedExercise ? nil : sets,
            reps: exercise.isTimeBasedExercise ? nil : reps,
            duration: exercise.isTimeBasedExercise ? TimeInterval(duration) : nil,
            restTime: TimeInterval(restTime),
            weight: exercise.weight,
            distance: exercise.distance,
            instructions: exercise.instructions,
            imageURL: exercise.imageURL,
            videoURL: exercise.videoURL,
            caloriesPerMinute: exercise.caloriesPerMinute,
            exerciseIcon: exercise.exerciseIcon
        )
        
        onUpdate(updatedExercise)
    }
}

struct WorkoutPreviewExerciseRow: View {
    let exercise: WorkoutExercise
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(.white.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if let sets = exercise.sets, let reps = exercise.reps {
                    Text("\(sets) × \(reps) reps")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                } else if let duration = exercise.duration {
                    Text("\(Int(duration))s")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            if let restTime = exercise.restTime {
                Text("\(Int(restTime))s rest")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.05))
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct CustomWorkoutCreatorView_Previews: PreviewProvider {
    static var previews: some View {
        CustomWorkoutCreatorView(
            onWorkoutCreated: { workout in
                print("Workout created: \(workout.name)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: true))
    }
}
#endif

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension CustomWorkoutCreatorView {
    private func logPerformance(_ message: String) {
        #if DEBUG
        print("[CustomWorkoutCreator] \(message)")
        #endif
    }
}