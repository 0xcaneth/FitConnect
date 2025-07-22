import Foundation
import FirebaseFirestore

// MARK: - Advanced User Profile

/// Comprehensive user profile for advanced AI coaching
struct AdvancedUserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let fitnessLevel: FitnessLevel
    let motivationType: MotivationType
    let consistencyPattern: ConsistencyPattern
    let preferredIntensity: IntensityPreference
    let recoveryPattern: RecoveryPattern
    let socialInfluence: SocialInfluence
    let goalOrientation: GoalOrientation
    let personalityTraits: [PersonalityTrait]
    let lifestyleFactors: [LifestyleFactor]
    let lastUpdated: Date
    let analysisVersion: String
    
    init(
        userId: String,
        fitnessLevel: FitnessLevel,
        motivationType: MotivationType,
        consistencyPattern: ConsistencyPattern,
        preferredIntensity: IntensityPreference,
        recoveryPattern: RecoveryPattern,
        socialInfluence: SocialInfluence,
        goalOrientation: GoalOrientation,
        personalityTraits: [PersonalityTrait],
        lifestyleFactors: [LifestyleFactor],
        lastUpdated: Date,
        analysisVersion: String
    ) {
        self.userId = userId
        self.fitnessLevel = fitnessLevel
        self.motivationType = motivationType
        self.consistencyPattern = consistencyPattern
        self.preferredIntensity = preferredIntensity
        self.recoveryPattern = recoveryPattern
        self.socialInfluence = socialInfluence
        self.goalOrientation = goalOrientation
        self.personalityTraits = personalityTraits
        self.lifestyleFactors = lifestyleFactors
        self.lastUpdated = lastUpdated
        self.analysisVersion = analysisVersion
    }
}

// MARK: - Fitness Level Analysis

enum FitnessLevel: String, CaseIterable, Codable {
    case unknown = "unknown"
    case beginner = "beginner"
    case novice = "novice"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    case elite = "elite"
    
    var displayName: String {
        switch self {
        case .unknown: return "Analyzing..."
        case .beginner: return "Beginner"
        case .novice: return "Novice"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .elite: return "Elite Athlete"
        }
    }
    
    var description: String {
        switch self {
        case .unknown: return "We're still learning about your fitness level"
        case .beginner: return "Just starting your fitness journey"
        case .novice: return "Building your foundation"
        case .intermediate: return "Making consistent progress"
        case .advanced: return "Experienced and dedicated"
        case .expert: return "High-level fitness enthusiast"
        case .elite: return "Elite performance level"
        }
    }
}

// MARK: - Motivation Type Analysis

enum MotivationType: String, CaseIterable, Codable {
    case unknown = "unknown"
    case achievement = "achievement"
    case health = "health"
    case social = "social"
    case aesthetic = "aesthetic"
    case stress_relief = "stress_relief"
    case competition = "competition"
    case habit = "habit"
    case enjoyment = "enjoyment"
    
    var displayName: String {
        switch self {
        case .unknown: return "Analyzing..."
        case .achievement: return "Achievement Driven"
        case .health: return "Health Focused"
        case .social: return "Socially Motivated"
        case .aesthetic: return "Appearance Goals"
        case .stress_relief: return "Stress Management"
        case .competition: return "Competitive Spirit"
        case .habit: return "Habit Builder"
        case .enjoyment: return "Fun Seeker"
        }
    }
    
    var aiCoachingStyle: String {
        switch self {
        case .unknown: return "Personalized approach"
        case .achievement: return "Goal-focused with progress tracking"
        case .health: return "Health benefits and wellness focus"
        case .social: return "Community challenges and social features"
        case .aesthetic: return "Body transformation and visual progress"
        case .stress_relief: return "Mindfulness and recovery emphasis"
        case .competition: return "Challenges, leaderboards, and PRs"
        case .habit: return "Consistency building and streak maintenance"
        case .enjoyment: return "Fun workouts and variety"
        }
    }
}

// MARK: - Consistency Pattern Analysis

enum ConsistencyPattern: String, CaseIterable, Codable {
    case unknown = "unknown"
    case highly_consistent = "highly_consistent"
    case moderately_consistent = "moderately_consistent"
    case inconsistent = "inconsistent"
    case weekend_warrior = "weekend_warrior"
    case seasonal = "seasonal"
    case burst_training = "burst_training"
    case perfectionist = "perfectionist"
    
    var displayName: String {
        switch self {
        case .unknown: return "Analyzing..."
        case .highly_consistent: return "Highly Consistent"
        case .moderately_consistent: return "Moderately Consistent"
        case .inconsistent: return "Inconsistent"
        case .weekend_warrior: return "Weekend Warrior"
        case .seasonal: return "Seasonal Trainer"
        case .burst_training: return "Burst Trainer"
        case .perfectionist: return "All-or-Nothing"
        }
    }
    
    var aiCoachingApproach: String {
        switch self {
        case .unknown: return "Building your routine"
        case .highly_consistent: return "Optimize and challenge progression"
        case .moderately_consistent: return "Habit strengthening and flexibility"
        case .inconsistent: return "Motivation and barrier removal"
        case .weekend_warrior: return "Efficient high-impact sessions"
        case .seasonal: return "Adaptive planning for natural cycles"
        case .burst_training: return "Intensive periods with active recovery"
        case .perfectionist: return "Progress over perfection mindset"
        }
    }
}

// MARK: - Additional Profile Enums

enum IntensityPreference: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case variable = "variable"
    
    var displayName: String {
        switch self {
        case .low: return "Low Intensity"
        case .moderate: return "Moderate Intensity"
        case .high: return "High Intensity"
        case .variable: return "Mixed Intensity"
        }
    }
}

enum RecoveryPattern: String, CaseIterable, Codable {
    case fast = "fast"
    case normal = "normal"
    case slow = "slow"
    case variable = "variable"
    
    var displayName: String {
        switch self {
        case .fast: return "Quick Recovery"
        case .normal: return "Normal Recovery"
        case .slow: return "Extended Recovery"
        case .variable: return "Variable Recovery"
        }
    }
}

enum SocialInfluence: String, CaseIterable, Codable {
    case high = "high"
    case moderate = "moderate"
    case low = "low"
    case solo_preferrer = "solo_preferrer"
    
    var displayName: String {
        switch self {
        case .high: return "Highly Social"
        case .moderate: return "Moderately Social"
        case .low: return "Minimally Social"
        case .solo_preferrer: return "Solo Preferrer"
        }
    }
}

enum GoalOrientation: String, CaseIterable, Codable {
    case short_term = "short_term"
    case long_term = "long_term"
    case balanced = "balanced"
    case process_focused = "process_focused"
    
    var displayName: String {
        switch self {
        case .short_term: return "Short-term Goals"
        case .long_term: return "Long-term Vision"
        case .balanced: return "Balanced Approach"
        case .process_focused: return "Process Oriented"
        }
    }
}

enum PersonalityTrait: String, CaseIterable, Codable {
    case disciplined = "disciplined"
    case flexible = "flexible"
    case goal_oriented = "goal_oriented"
    case social = "social"
    case independent = "independent"
    case perfectionist = "perfectionist"
    case adventurous = "adventurous"
    case analytical = "analytical"
    
    var displayName: String {
        switch self {
        case .disciplined: return "Disciplined"
        case .flexible: return "Flexible"
        case .goal_oriented: return "Goal-Oriented"
        case .social: return "Social"
        case .independent: return "Independent"
        case .perfectionist: return "Perfectionist"
        case .adventurous: return "Adventurous"
        case .analytical: return "Analytical"
        }
    }
}

enum LifestyleFactor: String, CaseIterable, Codable {
    case active_lifestyle = "active_lifestyle"
    case sedentary_job = "sedentary_job"
    case high_stress = "high_stress"
    case sleep_deprived = "sleep_deprived"
    case frequent_traveler = "frequent_traveler"
    case family_commitments = "family_commitments"
    case shift_worker = "shift_worker"
    case student = "student"
    
    var displayName: String {
        switch self {
        case .active_lifestyle: return "Active Lifestyle"
        case .sedentary_job: return "Desk Job"
        case .high_stress: return "High Stress"
        case .sleep_deprived: return "Sleep Challenges"
        case .frequent_traveler: return "Frequent Travel"
        case .family_commitments: return "Family Focused"
        case .shift_worker: return "Shift Work"
        case .student: return "Student Life"
        }
    }
}

// MARK: - Behavior Analysis

struct BehaviorAnalysis: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let workoutFrequencyPattern: WorkoutFrequencyPattern
    let preferredWorkoutTimes: [TimeSlot]
    let workoutDurationPreference: DurationPreference
    let skipPatterns: [SkipPattern]
    let motivationalTriggers: [MotivationalTrigger]
    let barrierFactors: [BarrierFactor]
    let progressResponsePattern: ProgressResponsePattern
    let socialEngagementLevel: SocialEngagementLevel
    let goalAchievementRate: Double
    let consistencyScore: Double
    let lastAnalyzed: Date
    
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        return dictionary ?? [:]
    }
}

enum WorkoutFrequencyPattern: String, CaseIterable, Codable {
    case daily = "daily"
    case every_other_day = "every_other_day"
    case three_times_week = "three_times_week"
    case weekends_only = "weekends_only"
    case sporadic = "sporadic"
    case seasonal = "seasonal"
}

struct TimeSlot: Codable {
    let hour: Int
    let frequency: Double // 0.0 to 1.0
    let preference: Double // 0.0 to 1.0
}

enum DurationPreference: String, CaseIterable, Codable {
    case short = "short" // 15-30 min
    case medium = "medium" // 30-45 min
    case long = "long" // 45+ min
    case variable = "variable"
}

struct SkipPattern: Codable {
    let trigger: String
    let frequency: Double
    let timeOfWeek: [Int] // Days of week (1-7)
    let seasonality: SeasonalFactor?
}

enum MotivationalTrigger: String, CaseIterable, Codable {
    case progress_tracking = "progress_tracking"
    case social_comparison = "social_comparison"
    case streak_maintenance = "streak_maintenance"
    case reward_system = "reward_system"
    case deadline_pressure = "deadline_pressure"
    case variety_seeking = "variety_seeking"
    case habit_stacking = "habit_stacking"
}

enum BarrierFactor: String, CaseIterable, Codable {
    case time_constraints = "time_constraints"
    case energy_levels = "energy_levels"
    case motivation_lack = "motivation_lack"
    case equipment_access = "equipment_access"
    case weather_dependency = "weather_dependency"
    case social_obligations = "social_obligations"
    case injury_concerns = "injury_concerns"
    case boredom = "boredom"
}

enum ProgressResponsePattern: String, CaseIterable, Codable {
    case linear_progress = "linear_progress"
    case plateau_breaker = "plateau_breaker"
    case momentum_dependent = "momentum_dependent"
    case comeback_strong = "comeback_strong"
    case steady_incremental = "steady_incremental"
}

enum SocialEngagementLevel: String, CaseIterable, Codable {
    case highly_engaged = "highly_engaged"
    case moderately_engaged = "moderately_engaged"
    case minimally_engaged = "minimally_engaged"
    case not_engaged = "not_engaged"
}

// MARK: - AI Insights

struct AdvancedAIInsight: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: InsightType
    let title: String
    let message: String
    let confidence: Double
    let priority: Int
    let category: InsightCategory
    let actionable: Bool
    let actionText: String?
    let supportingData: [String: Any]
    let generatedAt: Date
    let expiresAt: Date?
    let userInteraction: UserInteraction?
    
    func toDictionary() throws -> [String: Any] {
        return [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "message": message,
            "confidence": confidence,
            "priority": priority,
            "category": category.rawValue,
            "actionable": actionable,
            "actionText": actionText as Any,
            "supportingData": supportingData,
            "generatedAt": Timestamp(date: generatedAt),
            "expiresAt": expiresAt != nil ? Timestamp(date: expiresAt!) : nil,
            "userInteraction": userInteraction?.rawValue as Any
        ]
    }
}

enum InsightType: String, CaseIterable, Codable {
    case behavioral_pattern = "behavioral_pattern"
    case progress_analysis = "progress_analysis"
    case motivation_boost = "motivation_boost"
    case barrier_identification = "barrier_identification"
    case optimization_opportunity = "optimization_opportunity"
    case health_correlation = "health_correlation"
    case social_influence = "social_influence"
    case predictive_warning = "predictive_warning"
}

enum InsightCategory: String, CaseIterable, Codable {
    case performance = "performance"
    case consistency = "consistency"
    case motivation = "motivation"
    case health = "health"
    case lifestyle = "lifestyle"
    case social = "social"
    case goal_progress = "goal_progress"
}

enum UserInteraction: String, CaseIterable, Codable {
    case viewed = "viewed"
    case dismissed = "dismissed"
    case acted_upon = "acted_upon"
    case shared = "shared"
    case saved = "saved"
}

// MARK: - Advanced AI Recommendations

struct AdvancedAIRecommendation: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let type: RecommendationType
    let title: String
    let description: String
    let icon: String
    let color: String
    let priority: Int
    let confidence: Double
    let reasoning: String
    let category: RecommendationCategory
    let timesSuggested: Int
    let userFeedback: UserFeedback?
    let contextualTriggers: [String]
    let expectedOutcome: String
    let difficultyLevel: DifficultyLevel
    let estimatedTimeInvestment: TimeInterval
    let generatedAt: Date
    let validUntil: Date?
    
    func toDictionary() throws -> [String: Any] {
        return [
            "userId": userId,
            "type": type.rawValue,
            "title": title,
            "description": description,
            "icon": icon,
            "color": color,
            "priority": priority,
            "confidence": confidence,
            "reasoning": reasoning,
            "category": category.rawValue,
            "timesSuggested": timesSuggested,
            "userFeedback": userFeedback?.rawValue as Any,
            "contextualTriggers": contextualTriggers,
            "expectedOutcome": expectedOutcome,
            "difficultyLevel": difficultyLevel.rawValue,
            "estimatedTimeInvestment": estimatedTimeInvestment,
            "generatedAt": Timestamp(date: generatedAt),
            "validUntil": validUntil != nil ? Timestamp(date: validUntil!) : nil
        ]
    }
}

enum RecommendationType: String, CaseIterable, Codable {
    case workout_suggestion = "workout_suggestion"
    case habit_formation = "habit_formation"
    case motivation_boost = "motivation_boost"
    case barrier_removal = "barrier_removal"
    case goal_adjustment = "goal_adjustment"
    case recovery_optimization = "recovery_optimization"
    case social_engagement = "social_engagement"
    case lifestyle_integration = "lifestyle_integration"
}

enum RecommendationCategory: String, CaseIterable, Codable {
    case starter = "starter"
    case maintenance = "maintenance"
    case challenge = "challenge"
    case recovery = "recovery"
    case social = "social"
    case seasonal = "seasonal"
    case optimization = "optimization"
    case intervention = "intervention"
}

// MARK: - Workout Prediction

struct WorkoutPrediction: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    let predictedWorkoutType: WorkoutType
    let recommendation: String
    let confidence: Double
    let reasoning: String
    let optimalTiming: Date
    let expectedDuration: TimeInterval
    let expectedCalories: Int
    let expectedOutcome: ExpectedOutcome
    let riskFactors: [RiskFactor]
    let successProbability: Double
    let generatedAt: Date
}

struct ExpectedOutcome: Codable {
    let energyLevel: EnergyLevel
    let moodImprovement: Double
    let stressReduction: Double
    let sleepQualityImpact: Double
    let motivationBoost: Double
}

enum RiskFactor: String, CaseIterable, Codable {
    case low_energy = "low_energy"
    case time_constraints = "time_constraints"
    case weather_conditions = "weather_conditions"
    case high_stress = "high_stress"
    case poor_sleep = "poor_sleep"
    case social_conflicts = "social_conflicts"
    case equipment_unavailable = "equipment_unavailable"
}

// MARK: - Weather and Environment

struct WeatherConditions: Codable {
    let temperature: Double
    let humidity: Double
    let condition: WeatherType
    let airQuality: AirQuality
    let uvIndex: Int
}

enum WeatherType: String, CaseIterable, Codable {
    case sunny = "sunny"
    case cloudy = "cloudy"
    case rainy = "rainy"
    case snowy = "snowy"
    case stormy = "stormy"
}

enum AirQuality: String, CaseIterable, Codable {
    case good = "good"
    case moderate = "moderate"
    case unhealthy_sensitive = "unhealthy_sensitive"
    case unhealthy = "unhealthy"
    case hazardous = "hazardous"
}

struct ScheduleContext: Codable {
    let availability: ScheduleAvailability
    let upcomingCommitments: [TimeSlot]
    let preferredWorkoutWindows: [TimeSlot]
    let travelPlans: [TravelPlan]?
}

struct TravelPlan: Codable {
    let startDate: Date
    let endDate: Date
    let destination: String
    let type: TravelType
}

enum TravelType: String, CaseIterable, Codable {
    case business = "business"
    case leisure = "leisure"
    case family = "family"
}