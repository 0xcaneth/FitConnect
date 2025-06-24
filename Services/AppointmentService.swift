import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol AppointmentServiceProtocol {
    func getTodaysAppointments(for dietitianId: String, completion: @escaping (Result<[Appointment], Error>) -> Void)
    func listenForTodaysAppointments(for dietitianId: String, completion: @escaping (Result<[Appointment], Error>) -> Void) -> ListenerRegistration
    func getAppointmentCount(for dietitianId: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<Int, Error>) -> Void)
    func updateAppointmentStatus(dietitianId: String, appointmentId: String, status: AppointmentStatus) async throws
    func cancelAppointment(dietitianId: String, appointmentId: String) async throws
    func createAppointment(dietitianId: String, clientId: String, clientName: String, startTime: Date, endTime: Date, notes: String?) async throws -> String
    func getAppointmentsForDateRange(dietitianId: String, startDate: Date, endDate: Date) async throws -> [Appointment]
    func getTodaysAppointments(for dietitianId: String) async throws -> [Appointment]
    func updateAppointment(dietitianId: String, appointmentId: String, startTime: Date, endTime: Date, notes: String?) async throws
    func checkForConflicts(dietitianId: String, startTime: Date, endTime: Date, excludingAppointmentId: String?) async throws -> [Appointment]
    func rescheduleAppointment(dietitianId: String, appointmentId: String, newStartTime: Date, newEndTime: Date) async throws
    func getAppointmentById(dietitianId: String, appointmentId: String) async throws -> Appointment?
    func listenForAppointments(dietitianId: String, startDate: Date, endDate: Date, completion: @escaping (Result<[Appointment], Error>) -> Void) -> ListenerRegistration
}

@MainActor
class AppointmentService: ObservableObject, AppointmentServiceProtocol {
    private let firestore = Firestore.firestore()
    static let shared = AppointmentService()
    
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var listeners: [String: ListenerRegistration] = [:]
    
    private init() {
        setupFirestorePersistence()
    }
    
    private func setupFirestorePersistence() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        firestore.settings = settings
    }
    
    deinit {
        Task { @MainActor in
            await self.cleanupAsync()
        }
    }
    
    private func cleanupAsync() async {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Fetch Today's Appointments
    func getTodaysAppointments(
        for dietitianId: String,
        completion: @escaping (Result<[Appointment], Error>) -> Void
    ) {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("startTime", isLessThan: Timestamp(date: endOfDay))
            .order(by: "startTime")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let appointments = documents.compactMap { doc -> Appointment? in
                    do {
                        var appointment = try doc.data(as: Appointment.self)
                        appointment.id = doc.documentID
                        return appointment
                    } catch {
                        print("Error decoding appointment: \(error)")
                        return nil
                    }
                }
                
                completion(.success(appointments))
            }
    }
    
    func getTodaysAppointments(for dietitianId: String) async throws -> [Appointment] {
        return try await withCheckedThrowingContinuation { continuation in
            getTodaysAppointments(for: dietitianId) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // MARK: - Listen for Today's Appointments
    func listenForTodaysAppointments(
        for dietitianId: String,
        completion: @escaping (Result<[Appointment], Error>) -> Void
    ) -> ListenerRegistration {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        return listenForAppointments(
            dietitianId: dietitianId,
            startDate: startOfDay,
            endDate: endOfDay,
            completion: completion
        )
    }
    
    func listenForAppointments(
        dietitianId: String,
        startDate: Date,
        endDate: Date,
        completion: @escaping (Result<[Appointment], Error>) -> Void
    ) -> ListenerRegistration {
        return firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThan: Timestamp(date: endDate))
            .order(by: "startTime")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let appointments = documents.compactMap { doc -> Appointment? in
                    do {
                        var appointment = try doc.data(as: Appointment.self)
                        appointment.id = doc.documentID
                        return appointment
                    } catch {
                        print("Error decoding appointment: \(error)")
                        return nil
                    }
                }
                
                // Update published property
                Task { @MainActor in
                    self?.appointments = appointments
                }
                
                completion(.success(appointments))
            }
    }
    
    // MARK: - Get Appointment Count for Date Range
    func getAppointmentCount(
        for dietitianId: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThan: Timestamp(date: endDate))
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let count = snapshot?.documents.count ?? 0
                completion(.success(count))
            }
    }
    
    // MARK: - Conflict Prevention
    func checkForConflicts(
        dietitianId: String,
        startTime: Date,
        endTime: Date,
        excludingAppointmentId: String? = nil
    ) async throws -> [Appointment] {
        var query = firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .whereField("startTime", isLessThan: Timestamp(date: endTime))
            .whereField("endTime", isGreaterThan: Timestamp(date: startTime))
            .whereField("status", in: [AppointmentStatus.pending.rawValue, AppointmentStatus.confirmed.rawValue, AppointmentStatus.scheduled.rawValue])
        
        let snapshot = try await query.getDocuments()
        
        var conflicts = snapshot.documents.compactMap { doc -> Appointment? in
            // Exclude the appointment being updated
            if let excludingId = excludingAppointmentId, doc.documentID == excludingId {
                return nil
            }
            
            do {
                var appointment = try doc.data(as: Appointment.self)
                appointment.id = doc.documentID
                return appointment
            } catch {
                print("Error decoding appointment: \(error)")
                return nil
            }
        }
        
        // Additional validation to ensure actual overlap
        conflicts = conflicts.filter { appointment in
            let appointmentStart = appointment.startTime.dateValue()
            let appointmentEnd = appointment.endTime.dateValue()
            return appointmentStart < endTime && appointmentEnd > startTime
        }
        
        return conflicts
    }
    
    // MARK: - Create Appointment with Conflict Check
    func createAppointment(
        dietitianId: String,
        clientId: String,
        clientName: String,
        startTime: Date,
        endTime: Date,
        notes: String?
    ) async throws -> String {
        // Check for conflicts first
        let conflicts = try await checkForConflicts(
            dietitianId: dietitianId,
            startTime: startTime,
            endTime: endTime
        )
        
        if !conflicts.isEmpty {
            throw AppointmentError.timeSlotUnavailable(conflicts: conflicts)
        }
        
        let appointment = Appointment(
            clientId: clientId,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            status: .pending
        )
        
        var appointmentData = try Firestore.Encoder().encode(appointment)
        appointmentData["clientName"] = clientName
        appointmentData["createdAt"] = FieldValue.serverTimestamp()
        
        let docRef = try await firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .addDocument(data: appointmentData)
        
        return docRef.documentID
    }
    
    // MARK: - Update Appointment Status
    func updateAppointmentStatus(dietitianId: String, appointmentId: String, status: AppointmentStatus) async throws {
        var updateData: [String: Any] = ["status": status.rawValue]
        
        switch status {
        case .confirmed:
            updateData["confirmedAt"] = FieldValue.serverTimestamp()
        case .completed:
            updateData["completedAt"] = FieldValue.serverTimestamp()
        case .cancelled:
            updateData["cancelledAt"] = FieldValue.serverTimestamp()
        default:
            break
        }
        
        try await firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .document(appointmentId)
            .updateData(updateData)
    }
    
    // MARK: - Cancel Appointment
    func cancelAppointment(dietitianId: String, appointmentId: String) async throws {
        try await updateAppointmentStatus(
            dietitianId: dietitianId,
            appointmentId: appointmentId,
            status: .cancelled
        )
    }
    
    func updateAppointment(
        dietitianId: String,
        appointmentId: String,
        startTime: Date,
        endTime: Date,
        notes: String?
    ) async throws {
        // Check for conflicts (excluding current appointment)
        let conflicts = try await checkForConflicts(
            dietitianId: dietitianId,
            startTime: startTime,
            endTime: endTime,
            excludingAppointmentId: appointmentId
        )
        
        if !conflicts.isEmpty {
            throw AppointmentError.timeSlotUnavailable(conflicts: conflicts)
        }
        
        var updateData: [String: Any] = [
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let notes = notes {
            updateData["notes"] = notes
        }
        
        try await firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .document(appointmentId)
            .updateData(updateData)
    }
    
    func rescheduleAppointment(
        dietitianId: String,
        appointmentId: String,
        newStartTime: Date,
        newEndTime: Date
    ) async throws {
        try await updateAppointment(
            dietitianId: dietitianId,
            appointmentId: appointmentId,
            startTime: newStartTime,
            endTime: newEndTime,
            notes: nil
        )
    }
    
    func getAppointmentById(dietitianId: String, appointmentId: String) async throws -> Appointment? {
        let document = try await firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .document(appointmentId)
            .getDocument()
        
        guard document.exists else { return nil }
        
        var appointment = try document.data(as: Appointment.self)
        appointment.id = document.documentID
        return appointment
    }
    
    func getAppointmentsForDateRange(dietitianId: String, startDate: Date, endDate: Date) async throws -> [Appointment] {
        let snapshot = try await firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField("startTime", isLessThan: Timestamp(date: endDate))
            .order(by: "startTime")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Appointment? in
            do {
                var appointment = try doc.data(as: Appointment.self)
                appointment.id = doc.documentID
                return appointment
            } catch {
                print("Error decoding appointment: \(error)")
                return nil
            }
        }
    }
    
    // MARK: - Listener Management
    func startListening(key: String, listener: ListenerRegistration) {
        stopListening(key: key)
        listeners[key] = listener
    }
    
    func stopListening(key: String) {
        listeners[key]?.remove()
        listeners.removeValue(forKey: key)
    }
    
    func cleanup() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
}

// MARK: - Error Types
enum AppointmentError: LocalizedError {
    case timeSlotUnavailable(conflicts: [Appointment])
    case appointmentNotFound
    case invalidTimeRange
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .timeSlotUnavailable(let conflicts):
            if conflicts.count == 1 {
                return "Time slot unavailable. Another appointment is scheduled during this time."
            } else {
                return "Time slot unavailable. \(conflicts.count) appointments are scheduled during this time."
            }
        case .appointmentNotFound:
            return "Appointment not found"
        case .invalidTimeRange:
            return "Invalid time range. End time must be after start time"
        case .unauthorized:
            return "You don't have permission to modify this appointment"
        }
    }
}
