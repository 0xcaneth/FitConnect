import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Recent Activities ViewModel
// Handles fetching and managing the 5 most recent meal entries across all dates
@available(iOS 16.0, *)
@MainActor
final class RecentActivitiesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recentMeals: [MealEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let mealService = MealService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        // Subscribe to MealService's recent meals
        mealService.$recentMeals
            .receive(on: DispatchQueue.main)
            .sink { [weak self] meals in
                self?.recentMeals = Array(meals.prefix(5)) // Take only first 5
            }
            .store(in: &cancellables)
        
        // Subscribe to loading state
        mealService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoading = isLoading
            }
            .store(in: &cancellables)
        
        // Subscribe to error state
        mealService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
        
        // Start listening if user is authenticated
        if Auth.auth().currentUser != nil {
            mealService.startListening()
        }
    }
    
    deinit {
        mealService.stopListening()
    }
    
    // MARK: - Public Methods
    
    /// Fetches the 5 most recent meals for the current user
    func fetchRecentMeals() {
        guard Auth.auth().currentUser != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        // MealService will automatically update through listeners
        mealService.startListening()
    }
    
    /// Refreshes the recent meals data
    func refresh() {
        fetchRecentMeals()
    }
    
    /// Clears the current error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Manually adds a meal entry (for testing or immediate updates)
    func addMealEntry(_ meal: MealEntry) {
        // Insert at the beginning since it's the most recent
        recentMeals.insert(meal, at: 0)
        
        // Keep only the 5 most recent
        if recentMeals.count > 5 {
            recentMeals = Array(recentMeals.prefix(5))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns true if there are any recent meals to display
    var hasRecentMeals: Bool {
        return !recentMeals.isEmpty
    }
    
    /// Returns the total calories from recent meals
    var totalRecentCalories: Int {
        return recentMeals.reduce(0) { $0 + $1.nutrition.calories }
    }
}