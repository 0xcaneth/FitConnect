import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct AppointmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    let appointment: Appointment
    
    @State private var notes: String = ""
    @State private var showingRescheduleSheet = false
    @State private var showingCancelAlert = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Card
                        headerCard
                        
                        // Client Info Card
                        clientInfoCard
                        
                        // Time & Duration Card
                        timeInfoCard
                        
                        // Notes Section
                        notesSection
                        
                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(FitConnectColors.accentPurple)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Edit Appointment") {
                            showingRescheduleSheet = true
                        }
                        
                        if appointment.status != .completed {
                            Button("Mark Complete") {
                                Task {
                                    await markComplete()
                                }
                            }
                        }
                        
                        Divider()
                        
                        Button("Cancel Appointment", role: .destructive) {
                            showingCancelAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(FitConnectColors.accentPurple)
                    }
                }
            }
            .onAppear {
                notes = appointment.notes ?? ""
            }
            .alert("Cancel Appointment", isPresented: $showingCancelAlert) {
                Button("Cancel", role: .destructive) {
                    Task {
                        await cancelAppointment()
                    }
                }
                Button("Keep Appointment", role: .cancel) { }
            } message: {
                Text("Are you sure you want to cancel this appointment? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .sheet(isPresented: $showingRescheduleSheet) {
                RescheduleAppointmentView(appointment: appointment)
                    .environmentObject(session)
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appointment.status.color)
                            .frame(width: 12, height: 12)
                        
                        Text(appointment.status.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(appointment.status.color)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Date")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(appointment.status.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var clientInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(FitConnectColors.accentPurple.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(FitConnectColors.accentPurple)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(appointment.clientName ?? "Unknown Client")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text("Client ID: \(appointment.clientId)")
                        .font(.system(size: 14))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Button("View Profile") {
                        // TODO: Navigate to client profile
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FitConnectColors.accentPurple)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var timeInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.accentPurple)
                        .frame(width: 24)
                    
                    Text("Time")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Spacer()
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
                }
                
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.accentPurple)
                        .frame(width: 24)
                    
                    Text("Duration")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(FitConnectColors.textSecondary)
                    
                    Spacer()
                    
                    Text(appointment.durationString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
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
            
            Button("Save Notes") {
                Task {
                    await saveNotes()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(FitConnectColors.accentPurple)
            .cornerRadius(8)
            .disabled(isLoading)
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if appointment.status == .pending {
                Button("Confirm Appointment") {
                    Task {
                        await confirmAppointment()
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(FitConnectColors.accentGreen)
                .cornerRadius(12)
                .disabled(isLoading)
            }
            
            Button("Reschedule") {
                showingRescheduleSheet = true
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(FitConnectColors.accentPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FitConnectColors.accentPurple.opacity(0.1))
            .cornerRadius(12)
            .disabled(isLoading)
            
            if appointment.status != .cancelled {
                Button("Cancel Appointment") {
                    showingCancelAlert = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .disabled(isLoading)
            }
        }
    }
    
    // MARK: - Actions
    
    private func confirmAppointment() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isLoading = true
        
        do {
            try await AppointmentService.shared.updateAppointmentStatus(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                status: .confirmed
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                setError("Failed to confirm appointment: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func markComplete() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isLoading = true
        
        do {
            try await AppointmentService.shared.updateAppointmentStatus(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                status: .completed
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                setError("Failed to mark appointment complete: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func cancelAppointment() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isLoading = true
        
        do {
            try await AppointmentService.shared.cancelAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId
            )
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                setError("Failed to cancel appointment: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func saveNotes() async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
            return
        }
        
        isLoading = true
        
        do {
            try await AppointmentService.shared.updateAppointment(
                dietitianId: dietitianId,
                appointmentId: appointmentId,
                startTime: appointment.startTime.dateValue(),
                endTime: appointment.endTime.dateValue(),
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isLoading = false
                // Show success feedback
            }
        } catch {
            await MainActor.run {
                setError("Failed to save notes: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AppointmentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentDetailView(
            appointment: Appointment(
                clientId: "client123",
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                notes: "Regular nutrition consultation",
                status: .pending
            )
        )
        .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
        .preferredColorScheme(.dark)
    }
}
#endif