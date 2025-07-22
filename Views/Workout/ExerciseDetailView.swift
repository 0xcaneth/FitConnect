import SwiftUI

/// Premium, production-ready view for displaying exercise details.
struct ExerciseDetailView: View {
    let exercise: WorkoutExercise
    let onAction: (Action) -> Void
    
    @State private var exerciseVideoURL: URL?
    @State private var showContent = false
    
    enum Action {
        case addToWorkout
        case dismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern background with a subtle, premium gradient
                LinearGradient(
                    colors: [Color.black, Color(hex: "#1C1C1E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Video Player Section
                        exerciseVideoSection
                            .padding(.top, 60) // Space for the top bar
                        
                        // Exercise Info Section (Title & Description)
                        exerciseInfoSection
                        
                        // Stats Section
                        statsGridSection
                        
                        // Target Muscles Section
                        targetMusclesSection
                        
                        // Instructions Section
                        instructionsSection
                        
                        Spacer(minLength: 120) // Bottom padding
                    }
                    .padding(.horizontal, 20)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .navigationBarHidden(true)
            .overlay(topBar, alignment: .top)
        }
        .onAppear(perform: handleOnAppear)
    }

    // MARK: - Subviews
    
    @ViewBuilder
    private var topBar: some View {
        HStack {
            CircularButton(icon: "xmark", action: { onAction(.dismiss) })
            Spacer()
            PillButton(
                text: "Add to Workout",
                icon: "plus.circle.fill",
                action: { onAction(.addToWorkout) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var exerciseVideoSection: some View {
        ExerciseVideoPlayer(
            videoURL: exerciseVideoURL,
            isPlaying: true,
            showControls: true
        )
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }

    @ViewBuilder
    private var exerciseInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let description = exercise.description {
                Text(description)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(.gray)
                    .lineSpacing(4)
            }
        }
    }

    @ViewBuilder
    private var statsGridSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
            if let sets = exercise.sets {
                ExerciseStatCardView(title: "Sets", value: "\(sets)", icon: "repeat", color: .blue)
            }
            if let reps = exercise.reps {
                ExerciseStatCardView(title: "Reps", value: "\(reps)", icon: "number", color: .green)
            }
            if let duration = exercise.duration, let formatted = exercise.formattedDuration {
                ExerciseStatCardView(title: "Duration", value: formatted, icon: "clock.fill", color: .orange)
            }
            if let restTime = exercise.restTime {
                ExerciseStatCardView(title: "Rest", value: "\(Int(restTime))s", icon: "pause.fill", color: .purple)
            }
        }
    }

    @ViewBuilder
    private var targetMusclesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Target Muscles")
            
            // Use a custom FlowLayout for perfect wrapping
            FlexibleLayout(data: exercise.targetMuscleGroups, spacing: 12, alignment: .leading) { muscle in
                MuscleTag(name: muscle.displayName, icon: muscle.icon)
            }
        }
    }
    
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "How to Perform")
            
            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                InstructionRow(index: index + 1, text: instruction)
            }
        }
    }

    // MARK: - Helper Methods
    
    private func handleOnAppear() {
        withAnimation(.easeOut(duration: 0.5)) {
            showContent = true
        }
        loadExerciseVideo()
    }

    private func loadExerciseVideo() {
        if let existingURL = exercise.videoURL, !existingURL.isEmpty {
            exerciseVideoURL = URL(string: existingURL)
            return
        }
        
        Task {
            let url = await ExerciseVideoService.shared.fetchExerciseVideo(for: exercise.name)
            await MainActor.run {
                self.exerciseVideoURL = url
            }
        }
    }
}

// MARK: - Reusable UI Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundColor(.white)
    }
}

struct CircularButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct PillButton: View {
    let text: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(text)
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.blue)
                    .shadow(color: .blue.opacity(0.4), radius: 5, y: 3)
            )
        }
    }
}

// Renamed to avoid conflict
struct ExerciseStatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#2C2C2E"))
        )
    }
}

struct MuscleTag: View {
    let name: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
            
            Text(name)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#2C2C2E"))
        )
    }
}

struct InstructionRow: View {
    let index: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(index)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(Color.blue.opacity(0.2))
                )
            
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .default))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
    }
}

// MARK: - Flexible Layout (for Tags)

struct FlexibleLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            _FlexibleLayout(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct _FlexibleLayout<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State var elementsSize: [Data.Element: CGSize] = [:]
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]
            
            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth
            }
            
            remainingWidth -= (elementSize.width + spacing)
        }
        
        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}


#Preview {
    ExerciseDetailView(
        exercise: WorkoutExercise(
            name: "Barbell Bench Press",
            description: "Classic chest builder and upper body strength foundation. Essential for developing pectoral muscles, deltoids, and triceps.",
            targetMuscleGroups: [.chest, .shoulders, .arms],
            sets: 3,
            reps: 8,
            duration: nil,
            restTime: 120,
            weight: 165,
            distance: nil,
            instructions: [
                "Lie on a flat bench with your eyes under the bar.",
                "Grip the bar slightly wider than shoulder-width.",
                "Lower the bar to your chest with controlled movement.",
                "Press the bar back up to the starting position until your arms are fully extended."
            ],
            imageURL: nil,
            videoURL: nil,
            caloriesPerMinute: 10.0,
            exerciseIcon: "lungs.fill"
        )
    ) { action in
        print("Action: \(action)")
    }
    .preferredColorScheme(.dark)
}