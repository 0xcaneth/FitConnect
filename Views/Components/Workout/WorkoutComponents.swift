import SwiftUI

// MARK: - Enhanced Workout Components following Apple HIG

/// Modern workout card with glassmorphism design
struct WorkoutCard: View {
    let workout: WorkoutSession
    let isRecommended: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            ZStack {
                // Background gradient (removing imageURL support)
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: workout.workoutType.primaryColor).opacity(0.15),
                                Color(hex: workout.workoutType.secondaryColor).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                
                // Dark overlay for text readability
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.6),
                                Color.black.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Glassmorphism overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.2)
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    // Header with image and badges
                    headerSection
                    
                    Spacer()
                    
                    // Content
                    contentSection
                    
                    // Footer with stats
                    footerSection
                }
                .padding(20)
            }
        }
        .buttonStyle(WorkoutCardButtonStyle())
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .shadow(
            color: Color(hex: workout.workoutType.primaryColor).opacity(0.2),
            radius: isRecommended ? 20 : 10,
            x: 0,
            y: isRecommended ? 10 : 5
        )
        .overlay(
            // Recommended glow border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: isRecommended ? [
                            Color(hex: workout.workoutType.primaryColor).opacity(0.6),
                            Color(hex: workout.workoutType.secondaryColor).opacity(0.4)
                        ] : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isRecommended ? 2 : 0
                )
        )
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack {
            // Workout type icon
            ZStack {
                Circle()
                    .fill(Color(hex: workout.workoutType.primaryColor))
                    .frame(width: 44, height: 44)
                
                Image(systemName: workout.workoutType.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Badges
            HStack(spacing: 8) {
                if isRecommended {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: workout.workoutType.primaryColor))
                    )
                }
                
                // Difficulty badge
                Text(workout.difficulty.displayName.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: workout.difficulty.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: workout.difficulty.color).opacity(0.15))
                    )
            }
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(workout.name)
                .font(.system(size: 22, weight: .bold, design: .default))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Description
            if let description = workout.description {
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Muscle groups
            if !workout.targetMuscleGroups.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 4)
                ], spacing: 4) {
                    ForEach(Array(workout.targetMuscleGroups.prefix(4)), id: \.self) { muscle in
                        HStack(spacing: 2) {
                            Image(systemName: muscle.icon)
                                .font(.system(size: 8))
                            Text(muscle.displayName)
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: 16) {
            // Duration
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: workout.workoutType.primaryColor))
                
                Text(formatDuration(workout.estimatedDuration))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // Calories
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                
                Text("\(workout.estimatedCalories) kcal")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Start button
            HStack(spacing: 4) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                
                Text("START")
                    .font(.system(size: 12, weight: .bold))
                    .fixedSize()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(hex: workout.workoutType.primaryColor))
            )
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

/// Stats card for dashboard metrics
struct WorkoutStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .orange
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend.color)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
}

/// Circular progress ring for workout progress
struct WorkoutProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60, color: Color = .blue) {
        self.progress = max(0, min(1, progress))
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.6)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270 * progress - 90)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

/// Quick action button for workout types
struct WorkoutQuickActionButton: View {
    let workoutType: WorkoutType
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Icon container - restored to original gradient design
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: workoutType.primaryColor),
                                    Color(hex: workoutType.secondaryColor)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: workoutType.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Label
                Text(workoutType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 70)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.0) {
            // This won't execute, but the gesture recognizes the press
        } onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }
    }
}

/// Personal record achievement badge
struct PersonalRecordBadge: View {
    let record: PersonalRecord
    let isNew: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.yellow)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Personal Record")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if isNew {
                        Text("NEW!")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(.red)
                            )
                    }
                }
                
                Text(record.displayText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                if let exerciseName = record.exerciseName {
                    Text(exerciseName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
}

/// Workout recommendation reason badge
struct RecommendationReasonBadge: View {
    let reason: WorkoutRecommendation.RecommendationReason
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: reason.icon)
                .font(.system(size: 10, weight: .bold))
            
            Text(reason.displayText)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.blue.opacity(0.8))
        )
    }
}

// MARK: - Button Styles

struct WorkoutCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}