import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
class AppointmentFormViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var selectedStartTime = Date()
    @Published var selectedEndTime = Date()
    @Published var selectedClientId = ""
    @Published var selectedClientName = ""
    @Published var notes = ""
    @Published var availableClients: [ClientProfile] = []
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    @Published var existingAppointments: [Appointment] = []
    
    private let appointmentService: AppointmentServiceProtocol
    private let dietitianId: String
    private let editingAppointment: Appointment?
    private var cancellables = Set<AnyCancellable>()
    
    var isEditing: Bool {
        return editingAppointment != nil
    }
    
    init(dietitianId: String, editingAppointment: Appointment? = nil, appointmentService: AppointmentServiceProtocol = AppointmentService.shared) {
        self.dietitianId = dietitianId
        self.editingAppointment = editingAppointment
        self.appointmentService = appointmentService
        
        setupInitialValues()
        setupValidation()
        loadAvailableClients()
    }
    
    // MARK: - Setup
    
    private func setupInitialValues() {
        if let appointment = editingAppointment {
            // Editing existing appointment
            selectedDate = appointment.startTime.dateValue()
            selectedStartTime = appointment.startTime.dateValue()
            selectedEndTime = appointment.endTime.dateValue()
            selectedClientId = appointment.clientId
            selectedClientName = appointment.clientName ?? ""
            notes = appointment.notes ?? ""
        } else {
            // Creating new appointment
            setupDefaultTimes()
        }
    }
    
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        let now = Date()
        
        // Set default start time to next hour
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let startOfHour = calendar.date(bySetting: .minute, value: 0, of: nextHour) ?? nextHour
        selectedStartTime = startOfHour
        
        // Set default end time to 1 hour after start time
        selectedEndTime = calendar.date(byAdding: .hour, value: 1, to: selectedStartTime) ?? selectedStartTime
        
        // Set default date to today
        selectedDate = calendar.startOfDay(for: now)
    }
    
    private func setupValidation() {
        // Update end time when start time changes
        $selectedStartTime
            .sink { [weak self] startTime in
                guard let self = self else { return }
                
                // Ensure end time is at least 30 minutes after start time
                let minimumEndTime = Calendar.current.date(byAdding: .minute, value: 30, to: startTime) ?? startTime
                if self.selectedEndTime <= startTime {
                    self.selectedEndTime = minimumEndTime
                }
            }
            .store(in: &cancellables)
        
        // Load existing appointments when date changes
        $selectedDate
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] date in
                self?.loadExistingAppointments(for: date)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadAvailableClients() {
        isLoading = true
        
        // TODO: Replace with actual Firestore query
        // For now, using mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.availableClients = [
                ClientProfile(name: "John Smith", email: "john@example.com", assignedDietitianId: self.dietitianId),
                ClientProfile(name: "Jane Doe", email: "jane@example.com", assignedDietitianId: self.dietitianId),
                ClientProfile(name: "Mike Johnson", email: "mike@example.com", assignedDietitianId: self.dietitianId),
                ClientProfile(name: "Sarah Williams", email: "sarah@example.com", assignedDietitianId: self.dietitianId),
                ClientProfile(name: "David Brown", email: "david@example.com", assignedDietitianId: self.dietitianId)
            ]
            self.isLoading = false
        }
    }
    
    func loadExistingAppointments(for date: Date) {
        Task {
            do {
                let startOfDay = Calendar.current.startOfDay(for: date)
                let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                
                let appointments = try await appointmentService.getAppointmentsForDateRange(
                    dietitianId: dietitianId,
                    startDate: startOfDay,
                    endDate: endOfDay
                )
                
                await MainActor.run {
                    // Exclude the appointment we're editing from conflicts
                    if let editingId = self.editingAppointment?.id {
                        self.existingAppointments = appointments.filter { $0.id != editingId && $0.status != .cancelled }
                    } else {
                        self.existingAppointments = appointments.filter { $0.status != .cancelled }
                    }
                }
            } catch {
                await MainActor.run {
                    self.setError("Failed to load existing appointments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveAppointment() async {
        guard isFormValid else {
            setError("Please fill in all required fields")
            return
        }
        
        guard !hasTimeConflict else {
            setError("Selected time conflicts with an existing appointment")
            return
        }
        
        isSaving = true
        clearError()
        
        let combinedStartTime = combinedDateTime(date: selectedDate, time: selectedStartTime)
        let combinedEndTime = combinedDateTime(date: selectedDate, time: selectedEndTime)
        
        do {
            if isEditing {
                // TODO: Implement update appointment
                // For now, just show success
                showSuccessMessage("Appointment updated successfully!")
            } else {
                _ = try await appointmentService.createAppointment(
                    dietitianId: dietitianId,
                    clientId: selectedClientId,
                    clientName: selectedClientName,
                    startTime: combinedStartTime,
                    endTime: combinedEndTime,
                    notes: notes.isEmpty ? nil : notes
                )
                
                showSuccessMessage("Appointment created successfully!")
                resetForm()
            }
        } catch {
            setError("Failed to save appointment: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    func deleteAppointment() async {
        guard let appointment = editingAppointment,
              let appointmentId = appointment.id else {
            setError("Cannot delete appointment")
            return
        }
        
        isSaving = true
        
        do {
            try await appointmentService.cancelAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId
            )
            
            showSuccessMessage("Appointment deleted successfully!")
        } catch {
            setError("Failed to delete appointment: \(error.localizedDescription)")
        }
        
        isSaving = false
    }
    
    // MARK: - Validation
    
    var isFormValid: Bool {
        return !selectedClientId.isEmpty &&
               !selectedClientName.isEmpty &&
               selectedStartTime < selectedEndTime &&
               combinedDateTime(date: selectedDate, time: selectedStartTime) > Date()
    }
    
    var hasTimeConflict: Bool {
        let combinedStartTime = combinedDateTime(date: selectedDate, time: selectedStartTime)
        let combinedEndTime = combinedDateTime(date: selectedDate, time: selectedEndTime)
        
        let proposedAppointment = Appointment(
            startTime: Timestamp(date: combinedStartTime),
            endTime: Timestamp(date: combinedEndTime),
            clientId: selectedClientId,
            clientName: selectedClientName
        )
        
        return existingAppointments.contains { existing in
            existing.status == .confirmed && proposedAppointment.overlaps(with: existing)
        }
    }
    
    var timeConflictMessage: String? {
        guard hasTimeConflict else { return nil }
        
        let combinedStartTime = combinedDateTime(date: selectedDate, time: selectedStartTime)
        let combinedEndTime = combinedDateTime(date: selectedDate, time: selectedEndTime)
        
        let proposedAppointment = Appointment(
            startTime: Timestamp(date: combinedStartTime),
            endTime: Timestamp(date: combinedEndTime),
            clientId: selectedClientId,
            clientName: selectedClientName
        )
        
        if let conflicting = existingAppointments.first(where: { existing in
            existing.status == .confirmed && proposedAppointment.overlaps(with: existing)
        }) {
            return "Conflicts with appointment with \(conflicting.clientName ?? "client") at \(conflicting.timeRangeString)"
        }
        
        return "Time slot is not available"
    }
    
    // MARK: - Helper Methods
    
    private func combinedDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        
        return calendar.date(from: combined) ?? date
    }
    
    private func resetForm() {
        selectedClientId = ""
        selectedClientName = ""
        notes = ""
        setupDefaultTimes()
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
        
        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSuccess = false
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    func selectClient(_ client: ClientProfile) {
        selectedClientId = client.id ?? UUID().uuidString
        selectedClientName = client.name
    }
    
    // MARK: - Computed Properties
    
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let start = formatter.string(from: selectedStartTime)
        let end = formatter.string(from: selectedEndTime)
        
        return "\(start) - \(end)"
    }
    
    var selectedDuration: String {
        let duration = selectedEndTime.timeIntervalSince(selectedStartTime)
        let minutes = Int(duration / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}
