import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct RescheduleAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    let appointment: Appointment
    
    @State private var selectedDate: Date
    @State private var selectedStartTime: Date
    @State private var duration: TimeInterval
    @State private var notes: String
    @State private var isUpdating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var conflicts: [Appointment] = []
    @State private var showConflictAlert = false
    
    private let durationOptions: [(String, TimeInterval)] = [
        ("30 minutes", 1800),
        ("45 minutes", 2700),
        ("1 hour", 3600),
        ("1.5 hours", 5400),
        ("2 hours", 7200)
    ]
    
    var selectedEndTime: Date {
        selectedStartTime.addingTimeInterval(duration)
    }
    
    init(appointment: Appointment) {
        self.appointment = appointment
        
        let appointmentStart = appointment.startTime.dateValue()
        let appointmentEnd = appointment.endTime.dateValue()
        let appointmentDuration = appointmentEnd.timeIntervalSince(appointmentStart)
        
        _selectedDate = State(initialValue: appointmentStart)
        _selectedStartTime = State(initialValue: appointmentStart)
        _duration = State(initialValue: appointmentDuration)
        _notes = State(initialValue: appointment.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Appointment Info
                        currentAppointmentCard
                        
                        // New Date & Time
                        dateTimeSection
                        
                        // Duration
                        durationSection
                        
                        // Notes
                        notesSection
                        
                        // Update Button
                        updateButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Reschedule Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FitConnectColors.textSecondary)
                }
            }
            .alert("Scheduling Conflict", isPresented: $showConflictAlert) {
                Button("Choose Different Time") { }
                Button("Continue Anyway") {
                    Task {
                        await updateAppointmentForcefully()
                    }
                }
            } message: {
                Text("You have \(conflicts.count) appointment(s) during this time. Please choose a different time or continue anyway.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var currentAppointmentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Appointment")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(FitConnectColors.accentPurple)
                    
                    Text(appointment.clientName ?? "Unknown Client")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.textTertiary)
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Spacer()
                    
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 14))
                        .foregroundColor(FitConnectColors.textTertiary)
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(FitConnectColors.accentPurple.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Date & Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            VStack(spacing: 16) {
                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(CompactDatePickerStyle())
                .foregroundColor(FitConnectColors.textPrimary)
                
                DatePicker(
                    "Start Time",
                    selection: $selectedStartTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(CompactDatePickerStyle())
                .foregroundColor(FitConnectColors.textPrimary)
                
                HStack {
                    Text("End Time")
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Spacer()
                    
                    Text(formatTime(selectedEndTime))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(durationOptions, id: \.1) { option in
                    Button {
                        duration = option.1
                    } label: {
                        Text(option.0)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(duration == option.1 ? .white : FitConnectColors.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                duration == option.1 ? FitConnectColors.accentPurple : FitConnectColors.inputBackground
                            )
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            TextEditor(text: $notes)
                .font(.system(size: 16))
                .foregroundColor(FitConnectColors.textPrimary)
                .background(Color.clear)
                .frame(minHeight: 100)
                .padding(12)
                .background(FitConnectColors.inputBackground)
                .cornerRadius(8)
                .overlay(
                    Group {
                        if notes.isEmpty {
                            HStack {
                                VStack {
                                    Text("Add notes about this appointment...")
                                        .font(.system(size: 16))
                                        .foregroundColor(FitConnectColors.textTertiary)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 20)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }
                )
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var updateButton: some View {
        Button {
            Task {
                await updateAppointment()
            }
        } label: {
            HStack {
                if isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isUpdating ? "Updating..." : "Update Appointment")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? FitConnectColors.accentPurple : FitConnectColors.textTertiary)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isUpdating)
    }
    
    private var isFormValid: Bool {
        selectedStartTime > Date() && hasChanges
    }
    
    private var hasChanges: Bool {
        let originalStart = appointment.startTime.dateValue()
        let originalEnd = appointment.endTime.dateValue()
        let newStart = combineDateTime(selectedDate, selectedStartTime)
        let newEnd = selectedEndTime
        
        return newStart != originalStart || 
               newEnd != originalEnd || 
               notes != (appointment.notes ?? "")
    }
    
    // MARK: - Actions
    
    private func updateAppointment() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isUpdating = true
        
        do {
            let newStartTime = combineDateTime(selectedDate, selectedStartTime)
            let newEndTime = selectedEndTime
            
            // Check for conflicts first (excluding current appointment)
            let conflictingAppointments = try await AppointmentService.shared.checkForConflicts(
                dietitianId: dietitianId,
                startTime: newStartTime,
                endTime: newEndTime,
                excludingAppointmentId: appointmentId
            )
            
            if !conflictingAppointments.isEmpty {
                conflicts = conflictingAppointments
                showConflictAlert = true
                isUpdating = false
                return
            }
            
            // Update the appointment
            try await AppointmentService.shared.updateAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                startTime: newStartTime,
                endTime: newEndTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isUpdating = false
                dismiss()
            }
            
        } catch let error as AppointmentError {
            await MainActor.run {
                setError(error.localizedDescription)
                isUpdating = false
            }
        } catch {
            await MainActor.run {
                setError("Failed to update appointment: \(error.localizedDescription)")
                isUpdating = false
            }
        }
    }
    
    private func updateAppointmentForcefully() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isUpdating = true
        
        do {
            let newStartTime = combineDateTime(selectedDate, selectedStartTime)
            let newEndTime = selectedEndTime
            
            try await AppointmentService.shared.updateAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                startTime: newStartTime,
                endTime: newEndTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isUpdating = false
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                setError("Failed to update appointment: \(error.localizedDescription)")
                isUpdating = false
            }
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func combineDateTime(_ date: Date, _ time: Date) -> Date {
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
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct RescheduleAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        RescheduleAppointmentView(
            appointment: Appointment(
                clientId: "client123",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                notes: "Regular nutrition consultation",
                status: .confirmed
            )
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
        .preferredColorScheme(.dark)
    }
}
#endif