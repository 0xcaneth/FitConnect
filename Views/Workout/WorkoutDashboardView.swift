import SwiftUI

/// Main Workout Dashboard - Apple HIG Compliant Design
@available(iOS 16.0, *)
struct WorkoutDashboardView: View {
    @StateObject private var workoutService = WorkoutService.shared
    @EnvironmentObject private var session: SessionStore
    
    // UI States
    @State private var selectedWorkoutType: WorkoutType?
    @State private var showingWorkoutDetail = false
    @State private var selectedWorkout: WorkoutSession?
    @State private var scrollOffset: CGFloat = 0
    @State private var searchText = ""
    @State private var showingSearch = false
    
    // Animation states
    @State private var headerAnimation = false
    @State private var cardsAnimation: [Bool] = Array(repeating: false, count: 10)
    
    private var filteredWorkouts: [WorkoutSession] {
        if searchText.isEmpty && selectedWorkoutType == nil {
            return workoutService.availableWorkouts
        }
        
        return workoutService.availableWorkouts.filter { workout in
            let matchesSearch = searchText.isEmpty || 
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.description?.localizedCaseInsensitiveContains(searchText) ?? false
            
            let matchesType = selectedWorkoutType == nil || workout.workoutType == selectedWorkoutType
            
            return matchesSearch && matchesType
        }
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Premium background
                    backgroundView
                    
                    // Scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Header with user greeting and stats
                            headerSection
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            // Quick stats overview
                            statsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            // Today's recommendations
                            recommendationsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 32)
                            
                            // Workout type filters
                            workoutTypeFilters
                                .padding(.horizontal, 20)
                                .padding(.top, 32)
                            
                            // Available workouts
                            availableWorkoutsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            // Bottom spacing for tab bar
                            Spacer(minLength: 100)
                        }
                        .background(
                            GeometryReader { scrollGeometry in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: -scrollGeometry.frame(in: .named("scroll")).origin.y
                                    )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        withAnimation(.easeOut(duration: 0.1)) {
                            scrollOffset = value
                        }
                    }
                    .refreshable {
                        await refreshData()
                    }
                    
                    // Search overlay
                    if showingSearch {
                        searchOverlay
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                initializeDashboard()
                startAnimationSequence()
            }
            .sheet(isPresented: $showingWorkoutDetail) {
                if let workout = selectedWorkout {
                    WorkoutDetailView(workout: workout) {
                        // Start workout action
                        startWorkout(workout)
                    }
                }
            }
            .task {
                if let userId = session.currentUserId {
                    await workoutService.initialize(for: userId)
                }
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Base gradient
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
            
            // Dynamic accent based on scroll
            if scrollOffset > 100 {
                LinearGradient(
                    colors: [
                        Color(hex: "#4A90E2").opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.3), value: scrollOffset)
            }
        }
    }
    
    // MARK: - Header Section
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Top bar with greeting and search
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Train?")
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .scaleEffect(headerAnimation ? 1.0 : 0.9)
                        .opacity(headerAnimation ? 1.0 : 0.0)
                    
                    if let userName = session.currentUser?.firstName {
                        Text("Hello, \(userName)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                            .scaleEffect(headerAnimation ? 1.0 : 0.9)
                            .opacity(headerAnimation ? 1.0 : 0.0)
                    }
                }
                
                Spacer()
                
                // Search and notification buttons
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showingSearch.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(action: {}) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "bell")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .scaleEffect(headerAnimation ? 1.0 : 0.8)
                .opacity(headerAnimation ? 1.0 : 0.0)
            }
        }
    }
    
    // MARK: - Stats Section
    
    @ViewBuilder
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("This Week")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                WorkoutStatsCard(
                    title: "Workouts",
                    value: "\(workoutService.workoutStats?.weeklyProgress ?? 0)",
                    subtitle: "of \(workoutService.workoutStats?.weeklyGoal ?? 3) goal",
                    icon: "figure.strengthtraining.traditional",
                    color: .blue,
                    trend: .up
                )
                .scaleEffect(cardsAnimation[0] ? 1.0 : 0.9)
                .opacity(cardsAnimation[0] ? 1.0 : 0.0)
                .offset(y: cardsAnimation[0] ? 0 : 20)
                
                WorkoutStatsCard(
                    title: "Streak",
                    value: "\(workoutService.workoutStats?.currentStreak ?? 0)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange,
                    trend: .stable
                )
                .scaleEffect(cardsAnimation[1] ? 1.0 : 0.9)
                .opacity(cardsAnimation[1] ? 1.0 : 0.0)
                .offset(y: cardsAnimation[1] ? 0 : 20)
                
                WorkoutStatsCard(
                    title: "Calories",
                    value: "\(workoutService.workoutStats?.monthlyCalorieProgress ?? 0)",
                    subtitle: "this month",
                    icon: "flame.fill",
                    color: .red,
                    trend: .up
                )
                .scaleEffect(cardsAnimation[2] ? 1.0 : 0.9)
                .opacity(cardsAnimation[2] ? 1.0 : 0.0)
                .offset(y: cardsAnimation[2] ? 0 : 20)
                
                WorkoutStatsCard(
                    title: "Duration",
                    value: formatTotalDuration(workoutService.workoutStats?.totalDuration ?? 0),
                    subtitle: "total time",
                    icon: "clock.fill",
                    color: .green,
                    trend: .up
                )
                .scaleEffect(cardsAnimation[3] ? 1.0 : 0.9)
                .opacity(cardsAnimation[3] ? 1.0 : 0.0)
                .offset(y: cardsAnimation[3] ? 0 : 20)
            }
        }
    }
    
    // MARK: - Recommendations Section
    
    @ViewBuilder
    private var recommendationsSection: some View {
        if !workoutService.todayRecommendations.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Recommended for You")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.yellow)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(workoutService.todayRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                            WorkoutCard(
                                workout: recommendation.workoutSession,
                                isRecommended: true,
                                onTap: {
                                    selectedWorkout = recommendation.workoutSession
                                    showingWorkoutDetail = true
                                }
                            )
                            .frame(width: 280)
                            .scaleEffect(cardsAnimation[4 + index] ? 1.0 : 0.9)
                            .opacity(cardsAnimation[4 + index] ? 1.0 : 0.0)
                            .offset(x: cardsAnimation[4 + index] ? 0 : 50)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
        }
    }
    
    // MARK: - Workout Type Filters
    
    @ViewBuilder
    private var workoutTypeFilters: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Types")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    // All types button
                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedWorkoutType = nil
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedWorkoutType == nil ? .blue : Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("All")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 70)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        WorkoutQuickActionButton(workoutType: type) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedWorkoutType = selectedWorkoutType == type ? nil : type
                            }
                        }
                        .opacity(selectedWorkoutType == nil || selectedWorkoutType == type ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
    
    // MARK: - Available Workouts Section
    
    @ViewBuilder
    private var availableWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(selectedWorkoutType?.displayName ?? "All Workouts")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(filteredWorkouts.count) workouts")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16)
            ], spacing: 20) {
                ForEach(Array(filteredWorkouts.enumerated()), id: \.element.id) { index, workout in
                    WorkoutCard(
                        workout: workout,
                        isRecommended: false,
                        onTap: {
                            selectedWorkout = workout
                            showingWorkoutDetail = true
                        }
                    )
                    .scaleEffect(cardsAnimation[6 + index] ? 1.0 : 0.9)
                    .opacity(cardsAnimation[6 + index] ? 1.0 : 0.0)
                    .offset(y: cardsAnimation[6 + index] ? 0 : 30)
                }
            }
        }
    }
    
    // MARK: - Search Overlay
    
    @ViewBuilder
    private var searchOverlay: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Search workouts...", text: $searchText)
                        .font(.system(size: 16))
                        .textFieldStyle(PlainTextFieldStyle())
                        .submitLabel(.search)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                
                Button("Cancel") {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showingSearch = false
                        searchText = ""
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Account for status bar
            .padding(.bottom, 20)
            .background(.thinMaterial)
            
            Spacer()
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Helper Methods
    
    private func initializeDashboard() {
        print("[WorkoutDashboardView] 🏠 Dashboard initialized")
    }
    
    private func startAnimationSequence() {
        // Header animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            headerAnimation = true
        }
        
        // Staggered card animations
        for index in 0..<cardsAnimation.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 + (Double(index) * 0.05)) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if index < cardsAnimation.count {
                        cardsAnimation[index] = true
                    }
                }
            }
        }
    }
    
    private func refreshData() async {
        if let userId = session.currentUserId {
            await workoutService.initialize(for: userId)
        }
    }
    
    private func startWorkout(_ workout: WorkoutSession) {
        Task {
            let result = await workoutService.startWorkout(workout)
            switch result {
            case .success(let workoutId):
                print("[WorkoutDashboardView] ✅ Workout started: \(workoutId)")
                // Navigate to workout timer view
                
            case .failure(let error):
                print("[WorkoutDashboardView] ❌ Failed to start workout: \(error)")
                // Show error alert
            }
        }
    }
    
    private func formatTotalDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(duration / 60)
            return "\(minutes)m"
        }
    }
}

// MARK: - Scroll Offset Preference Key remains the same

#if DEBUG
@available(iOS 16.0, *)
struct WorkoutDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionStore.previewStore(isLoggedIn: true)
        session.currentUser?.firstName = "Alex"
        
        return WorkoutDashboardView()
            .environmentObject(session)
            .preferredColorScheme(.dark)
    }
}
#endif