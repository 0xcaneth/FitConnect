import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class MealService: ObservableObject {
    static let shared = MealService()
    
    private let db = Firestore.firestore()
    @Published var todayMeals: [MealEntry] = []
    @Published var weeklyMeals: [MealEntry] = []
    @Published var recentMeals: [MealEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listeners: [ListenerRegistration] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init() {
        print("✅ MealService initialized - Firestore already configured at app startup")
    }
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to today's meals using unified path structure
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = dateFormatter.string(from: today)
        
        let todayListener = db.collection("users")
            .document(userId)
            .collection("healthdata")
            .document(todayString)
            .collection("meals")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.todayMeals = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: MealEntry.self)
                } ?? []
                
                print("[MealService] ✅ Loaded \(self?.todayMeals.count ?? 0) meals for today")
            }
        
        // Listen to recent meals across all dates using collectionGroup
        let recentListener = db.collectionGroup("meals")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.recentMeals = snapshot?.documents.compactMap { doc in
                    var meal = try? doc.data(as: MealEntry.self)
                    meal?.id = doc.documentID
                    return meal
                } ?? []
                
                print("[MealService] ✅ Loaded \(self?.recentMeals.count ?? 0) recent meals")
            }
        
        // Listen to weekly meals for stats
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        let weeklyListener = db.collectionGroup("meals")
            .whereField("userId", isEqualTo: userId)
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: weekAgo))
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.weeklyMeals = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: MealEntry.self)
                } ?? []
                
                print("[MealService] ✅ Loaded \(self?.weeklyMeals.count ?? 0) weekly meals")
            }
        
        listeners = [todayListener, recentListener, weeklyListener]
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Save Methods
    
    /// Save MealEntry to unified path structure
    func saveMealEntry(_ mealEntry: MealEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var updatedEntry = mealEntry
        updatedEntry.userId = userId
        
        let dateString = dateFormatter.string(from: mealEntry.timestamp)
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("healthdata")
            .document(dateString)
            .collection("meals")
        
        if let mealId = mealEntry.id {
            // Update existing meal
            try await docRef.document(mealId).setData(from: updatedEntry)
            print("[MealService] ✅ Updated meal: \(mealEntry.mealName)")
        } else {
            // Create new meal
            try await docRef.addDocument(from: updatedEntry)
            print("[MealService] ✅ Saved new meal: \(mealEntry.mealName)")
        }
    }
    
    /// Legacy method - converts old Meal model to MealEntry and saves
    func saveMeal(_ meal: Meal) async throws {
        let nutrition = NutritionData(
            calories: meal.calories,
            protein: meal.protein,
            fat: meal.fat,
            carbs: meal.carbs
        )
        
        let mealEntry = MealEntry(
            mealName: meal.mealName,
            mealType: meal.mealType.rawValue,
            nutrition: nutrition,
            timestamp: meal.timestamp,
            userId: meal.userId,
            imageURL: meal.imageURL,
            confidence: meal.confidence
        )
        
        try await saveMealEntry(mealEntry)
    }
    
    /// Save meal from analysis (for scan meal functionality)
    func saveMealFromAnalysis(
        mealName: String,
        mealType: String,
        analysis: MealAnalysis,
        timestamp: Date = Date(),
        imageURL: String? = nil
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let nutrition = NutritionData(from: analysis)
        
        let mealEntry = MealEntry(
            mealName: mealName,
            mealType: mealType,
            nutrition: nutrition,
            timestamp: timestamp,
            userId: userId,
            imageURL: imageURL,
            confidence: analysis.confidence
        )
        
        try await saveMealEntry(mealEntry)
    }
    
    // MARK: - Computed Properties
    
    var todayCalories: Int {
        todayMeals.reduce(0) { $0 + $1.nutrition.calories }
    }
    
    var weeklyCalories: Int {
        weeklyMeals.reduce(0) { $0 + $1.nutrition.calories }
    }
    
    var todayProtein: Double {
        todayMeals.reduce(0) { $0 + $1.nutrition.protein }
    }
    
    var todayCarbs: Double {
        todayMeals.reduce(0) { $0 + $1.nutrition.carbs }
    }
    
    var todayFat: Double {
        todayMeals.reduce(0) { $0 + $1.nutrition.fat }
    }
    
    // MARK: - Fetch Methods
    
    func fetchMealsForDate(_ date: Date) async throws -> [MealEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dateString = dateFormatter.string(from: date)
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("healthdata")
            .document(dateString)
            .collection("meals")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            var meal = try? doc.data(as: MealEntry.self)
            meal?.id = doc.documentID
            return meal
        }
    }
    
    func deleteMeal(mealId: String, date: Date) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dateString = dateFormatter.string(from: date)
        
        try await db.collection("users")
            .document(userId)
            .collection("healthdata")
            .document(dateString)
            .collection("meals")
            .document(mealId)
            .delete()
        
        print("[MealService] ✅ Deleted meal: \(mealId)")
    }
}