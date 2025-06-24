import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class MealService: ObservableObject {
    static let shared = MealService()
    
    private let db = Firestore.firestore()
    @Published var todayMeals: [Meal] = []
    @Published var weeklyMeals: [Meal] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var listeners: [ListenerRegistration] = []
    
    init() {
        print("✅ MealService initialized - Firestore already configured at app startup")
    }
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Listen to today's meals
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let todayListener = db.collection("users")
            .document(userId)
            .collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("timestamp", isLessThan: Timestamp(date: tomorrow))
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.todayMeals = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Meal.self)
                } ?? []
            }
        
        // Listen to weekly meals
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        
        let weeklyListener = db.collection("users")
            .document(userId)
            .collection("meals")
            .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: weekAgo))
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                self?.weeklyMeals = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Meal.self)
                } ?? []
            }
        
        listeners = [todayListener, weeklyListener]
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    func saveMeal(_ meal: Meal) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        if let mealId = meal.id {
            // Use the provided meal ID
            try await db.collection("users")
                .document(userId)
                .collection("meals")
                .document(mealId)
                .setData(from: meal)
        } else {
            // Let Firestore auto-generate ID
            try await db.collection("users")
                .document(userId)
                .collection("meals")
                .addDocument(from: meal)
        }
    }
    
    var todayCalories: Int {
        todayMeals.reduce(0) { $0 + $1.calories }
    }
    
    var weeklyCalories: Int {
        weeklyMeals.reduce(0) { $0 + $1.calories }
    }
}