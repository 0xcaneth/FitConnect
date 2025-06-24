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
        print("MealService initialized - Firestore already configured at app startup")
    }
    
    func startListening() {
        guard let userId = Auth.auth().currentUser?.uid else { 
            error = "User not authenticated"
            return 
        }
        
        // Clear previous error
        error = nil
        isLoading = true
        
        // Stop existing listeners
        stopListening()
        
        // Listen to today's meals using specific path
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = dateFormatter.string(from: today)
        
        let todayListener = db.collection("users")
            .document(userId)
            .collection("healthData")
            .document(todayString)
            .collection("meals")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("[MealService] Recent meals error for \(todayString): \(error.localizedDescription)")
                        self?.error = error.localizedDescription
                        self?.isLoading = false
                        return
                    }
                    
                    self?.todayMeals = snapshot?.documents.compactMap { doc in
                        var meal = try? doc.data(as: MealEntry.self)
                        meal?.id = doc.documentID
                        return meal
                    } ?? []
                    
                    print("[MealService] Loaded \(self?.todayMeals.count ?? 0) meals for today")
                    self?.isLoading = false
                }
            }
        
        fetchRecentMealsFromDates(userId: userId)
        
        fetchWeeklyMealsFromDates(userId: userId)
        
        listeners = [todayListener]
    }
    
    private func fetchRecentMealsFromDates(userId: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "meal-fetch-queue", attributes: .concurrent)
        
        // Use a thread-safe array to collect meals
        var tempMeals: [MealEntry] = []
        let lock = NSLock()
        
        // Check last 7 days for recent meals
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            dispatchGroup.enter()
            
            db.collection("users")
                .document(userId)
                .collection("healthData")
                .document(dateString)
                .collection("meals")
                .order(by: "timestamp", descending: true)
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("[MealService] Recent meals error for \(dateString): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let dayMeals: [MealEntry] = documents.compactMap { doc in
                        var meal = try? doc.data(as: MealEntry.self)
                        meal?.id = doc.documentID
                        return meal
                    }
                    
                    // Thread-safe append
                    lock.lock()
                    tempMeals.append(contentsOf: dayMeals)
                    lock.unlock()
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            // Sort all meals by timestamp and take top 10
            self.recentMeals = Array(tempMeals
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(10))
            
            print("[MealService] Loaded \(self.recentMeals.count) recent meals from specific dates")
        }
    }
    
    private func fetchWeeklyMealsFromDates(userId: String) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dispatchGroup = DispatchGroup()
        
        // Use a thread-safe array to collect meals
        var tempMeals: [MealEntry] = []
        let lock = NSLock()
        
        // Check last 7 days for weekly stats
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            dispatchGroup.enter()
            
            db.collection("users")
                .document(userId)
                .collection("healthData")
                .document(dateString)
                .collection("meals")
                .getDocuments { snapshot, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("[MealService] Weekly meals error for \(dateString): \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let dayMeals: [MealEntry] = documents.compactMap { doc in
                        try? doc.data(as: MealEntry.self)
                    }
                    
                    // Thread-safe append
                    lock.lock()
                    tempMeals.append(contentsOf: dayMeals)
                    lock.unlock()
                }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.weeklyMeals = tempMeals
            print("[MealService] Loaded \(self.weeklyMeals.count) weekly meals from specific dates")
        }
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    func saveMealEntry(_ mealEntry: MealEntry) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        var updatedEntry = mealEntry
        updatedEntry.userId = userId
        
        let dateString = dateFormatter.string(from: mealEntry.timestamp)
        
        let docRef = db.collection("users")
            .document(userId)
            .collection("healthData")
            .document(dateString)
            .collection("meals")
        
        if let mealId = mealEntry.id {
            try await docRef.document(mealId).setData(from: updatedEntry)
            print("[MealService] Updated meal: \(mealEntry.mealName)")
        } else {
            try await docRef.addDocument(from: updatedEntry)
            print("[MealService] Saved new meal: \(mealEntry.mealName)")
        }
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            fetchRecentMealsFromDates(userId: currentUserId)
        }
    }
    
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
    
    func fetchMealsForDate(_ date: Date) async throws -> [MealEntry] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "MealService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let dateString = dateFormatter.string(from: date)
        
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("healthData")
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
            .collection("healthData")
            .document(dateString)
            .collection("meals")
            .document(mealId)
            .delete()
        
        print("[MealService] Deleted meal: \(mealId)")
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            fetchRecentMealsFromDates(userId: currentUserId)
        }
    }
}