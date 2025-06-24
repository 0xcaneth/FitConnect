import Foundation
import Combine
import FirebaseFirestore

@MainActor
class AppointmentListViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let appointmentService: AppointmentServiceProtocol
    private var appointmentListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    private weak var sessionStore: SessionStore?
    
    init(appointmentService: AppointmentServiceProtocol = AppointmentService.shared, sessionStore: SessionStore? = nil) {
        self.appointmentService = appointmentService
        self.sessionStore = sessionStore
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    func startListening(for dietitianId: String) {
        guard !dietitianId.isEmpty else {
            setError("Invalid dietitian ID")
            return
        }
        
        cleanup()
        isLoading = true
        errorMessage = nil
        
        appointmentListener = appointmentService.listenForTodaysAppointments(for: dietitianId) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let appointments):
                    self.appointments = appointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
                    self.errorMessage = nil
                    self.showError = false
                case .failure(let error):
                    self.setError("Failed to load appointments: \(error.localizedDescription)")
                    print("[AppointmentListVM] Error: \(error)")
                }
            }
        }
    }
    
    func refreshAppointments(for dietitianId: String) async {
        guard !dietitianId.isEmpty else {
            setError("Invalid dietitian ID")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedAppointments = try await appointmentService.getTodaysAppointments(for: dietitianId)
            appointments = fetchedAppointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
        } catch {
            setError("Failed to refresh appointments: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func fetchAppointments() async {
        guard let dietitianId = sessionStore?.currentUserId else {
            setError("No dietitian ID available")
            return
        }
        
        await refreshAppointments(for: dietitianId)
    }

    func confirmAppointment(_ appointment: Appointment, dietitianId: String) async {
        guard let appointmentId = appointment.id else {
            setError("Invalid appointment ID")
            return
        }
        
        do {
            try await appointmentService.updateAppointmentStatus(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                status: .confirmed
            )
        } catch {
            setError("Failed to confirm appointment: \(error.localizedDescription)")
        }
    }
    
    func cancelAppointment(_ appointment: Appointment, dietitianId: String) async {
        guard let appointmentId = appointment.id else {
            setError("Invalid appointment ID")
            return
        }
        
        do {
            try await appointmentService.cancelAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId
            )
        } catch {
            setError("Failed to cancel appointment: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Computed Properties
    
    var todaysAppointments: [Appointment] {
        return appointments.filter { $0.isToday() }
    }
    
    var upcomingAppointments: [Appointment] {
        return appointments.filter { $0.isUpcoming() && $0.status != .cancelled }
    }
    
    var confirmedAppointments: [Appointment] {
        return appointments.filter { $0.status == .confirmed }
    }
    
    var pendingAppointments: [Appointment] {
        return appointments.filter { $0.status == .pending }
    }
    
    var hasAppointments: Bool {
        return !appointments.isEmpty
    }
    
    // MARK: - Error Handling
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        appointmentListener?.remove()
        appointmentListener = nil
    }
    
    // MARK: - Utility Methods
    
    func appointment(with id: String) -> Appointment? {
        return appointments.first { $0.id == id }
    }
}
