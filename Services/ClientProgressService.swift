import Foundation
import FirebaseFirestore
import FirebaseAuth

class ClientProgressService: ObservableObject {
    private let firestore = Firestore.firestore()
    static let shared = ClientProgressService()
    
    private init() {}
    
    // MARK: - Fetch Client Progress Summaries
    func getClientProgressSummaries(
        for dietitianId: String,
        completion: @escaping (Result<[ClientProgressSummary], Error>) -> Void
    ) {
        // First, get all clients assigned to this dietitian
        firestore.collection("users")
            .whereField("assignedDietitianId", isEqualTo: dietitianId)
            .whereField("role", isEqualTo: "client")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let clients = documents.compactMap { doc -> FitConnectUser? in
                    do {
                        var user = try doc.data(as: FitConnectUser.self)
                        user.id = doc.documentID
                        return user
                    } catch {
                        print("Error decoding user: \(error)")
                        return nil
                    }
                }
                
                // Now fetch latest health data for each client
                self?.fetchHealthDataForClients(clients) { result in
                    completion(result)
                }
            }
    }
    
    private func fetchHealthDataForClients(
        _ clients: [FitConnectUser],
        completion: @escaping (Result<[ClientProgressSummary], Error>) -> Void
    ) {
        let group = DispatchGroup()
        var progressSummaries: [ClientProgressSummary] = []
        var fetchError: Error?
        
        for client in clients {
            guard let clientId = client.id else { continue }
            
            group.enter()
            getLatestHealthData(for: clientId) { result in
                defer { group.leave() }
                
                switch result {
                case .success(let healthData):
                    let summary = ClientProgressSummary(
                        clientId: clientId,
                        clientName: client.fullName,
                        clientAvatarURL: client.photoURL,
                        latestHealthData: healthData,
                        lastUpdateDate: healthData?.date.dateValue()
                    )
                    progressSummaries.append(summary)
                    
                case .failure(let error):
                    fetchError = error
                    // Still create a summary with no data
                    let summary = ClientProgressSummary(
                        clientId: clientId,
                        clientName: client.fullName,
                        clientAvatarURL: client.photoURL,
                        latestHealthData: nil,
                        lastUpdateDate: nil
                    )
                    progressSummaries.append(summary)
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = fetchError {
                completion(.failure(error))
            } else {
                // Sort by most recent update date
                let sortedSummaries = progressSummaries.sorted { summary1, summary2 in
                    guard let date1 = summary1.lastUpdateDate,
                          let date2 = summary2.lastUpdateDate else {
                        return summary1.lastUpdateDate != nil
                    }
                    return date1 > date2
                }
                completion(.success(sortedSummaries))
            }
        }
    }
    
    // MARK: - Get Latest Health Data for a Client
    private func getLatestHealthData(
        for clientId: String,
        completion: @escaping (Result<HealthData?, Error>) -> Void
    ) {
        firestore.collection("users")
            .document(clientId)
            .collection("healthData")
            .order(by: "date", descending: true)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents,
                      let document = documents.first else {
                    completion(.success(nil))
                    return
                }
                
                do {
                    var healthData = try document.data(as: HealthData.self)
                    healthData.id = document.documentID
                    completion(.success(healthData))
                } catch {
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - Listen for Client Progress Updates
    func listenForClientProgressUpdates(
        for dietitianId: String,
        completion: @escaping (Result<[ClientProgressSummary], Error>) -> Void
    ) -> ListenerRegistration {
        return firestore.collection("users")
            .whereField("assignedDietitianId", isEqualTo: dietitianId)
            .whereField("role", isEqualTo: "client")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let clients = documents.compactMap { doc -> FitConnectUser? in
                    do {
                        var user = try doc.data(as: FitConnectUser.self)
                        user.id = doc.documentID
                        return user
                    } catch {
                        print("Error decoding user: \(error)")
                        return nil
                    }
                }
                
                self?.fetchHealthDataForClients(clients) { result in
                    completion(result)
                }
            }
    }
}