import Foundation
import FirebaseFirestore
import FirebaseAuth

struct HydrationEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var amount: Int // in mL
    var timestamp: Timestamp
    var userId: String
    
    init(amount: Int, timestamp: Timestamp = Timestamp(date: Date()), userId: String) {
        self.amount = amount
        self.timestamp = timestamp
        self.userId = userId
    }
}

@MainActor
class HydrationService: ObservableObject {
    @Published var todayEntries: [HydrationEntry] = []
    @Published var todayTotal: Int = 0
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    static let shared = HydrationService()
    
    private init() {}
    
    func fetchEntries(from startDate: Date, to endDate: Date, for userId: String) async throws -> [HydrationEntry] {
        let startTimestamp = Timestamp(date: startDate)
        let endTimestamp = Timestamp(date: endDate)
        
        let query = db.collection("users")
            .document(userId)
            .collection("hydrationEntries")
            .whereField("timestamp", isGreaterThanOrEqualTo: startTimestamp)
            .whereField("timestamp", isLessThan: endTimestamp)
            .order(by: "timestamp", descending: true)
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: HydrationEntry.self)
        }
    }
    
    func fetchTodayEntries(for userId: String) async {
        isLoading = true
        
        do {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
            
            todayEntries = try await fetchEntries(from: startOfDay, to: endOfDay, for: userId)
            todayTotal = todayEntries.reduce(0) { $0 + $1.amount }
        } catch {
            print("[HydrationService] Error fetching today's entries: \(error.localizedDescription)")
            todayEntries = []
            todayTotal = 0
        }
        
        isLoading = false
    }
    
    func addEntry(amount: Int, for userId: String) async throws {
        let entry = HydrationEntry(amount: amount, userId: userId)
        
        try await db.collection("users")
            .document(userId)
            .collection("hydrationEntries")
            .addDocument(from: entry)
        
        // Refresh today's data
        await fetchTodayEntries(for: userId)
    }
}