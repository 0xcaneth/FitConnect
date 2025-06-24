import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
class AppointmentDetailViewModel: ObservableObject {
    @Published var appointment: Appointment
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false
    @Published var successMessage = ""
    
    private let appointmentService: AppointmentServiceProtocol
    private let dietitianId: String
    
    init(appointment: Appointment, dietitianId: String, appointmentService: AppointmentServiceProtocol = AppointmentService.shared) {
        self.appointment = appointment
        self.dietitianId = dietitianId
        self.appointmentService = appointmentService
    }
    
    // MARK: - Actions
    
    func confirmAppointment() async {
        guard let appointmentId = appointment.id else {
            setError("Invalid appointment ID")
            return
        }
        
        isLoading = true
        
        do {
            try await appointmentService.updateAppointmentStatus(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                status: .confirmed
            )
            
            appointment.status = .confirmed
            showSuccessMessage("Appointment confirmed successfully")
        } catch {
            setError("Failed to confirm appointment: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func cancelAppointment() async {
        guard let appointmentId = appointment.id else {
            setError("Invalid appointment ID")
            return
        }
        
        isLoading = true
        
        do {
            try await appointmentService.cancelAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId
            )
            
            appointment.status = .cancelled
            showSuccessMessage("Appointment cancelled")
        } catch {
            setError("Failed to cancel appointment: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func markAsCompleted() async {
        guard let appointmentId = appointment.id else {
            setError("Invalid appointment ID")
            return
        }
        
        isLoading = true
        
        do {
            try await appointmentService.updateAppointmentStatus(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                status: .completed
            )
            
            appointment.status = .completed
            showSuccessMessage("Appointment marked as complete")
        } catch {
            setError("Failed to mark appointment as complete: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Computed Properties
    
    var canConfirm: Bool {
        return appointment.status == .pending && appointment.isUpcoming()
    }
    
    var canCancel: Bool {
        return appointment.status != .cancelled && appointment.isUpcoming()
    }
    
    var statusColor: Color {
        return appointment.status.color
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: appointment.startTime.dateValue())
    }
    
    var formattedTime: String {
        return appointment.timeRangeString
    }
}
