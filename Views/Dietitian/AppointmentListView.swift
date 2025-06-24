import SwiftUI
import FirebaseFirestore
import Combine

@available(iOS 16.0, *)
struct AppointmentListView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var appointmentService = AppointmentService.shared
    @State private var appointments: [Appointment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showingNewAppointment = false
    @State private var selectedAppointment: Appointment?
    @State private var showingAppointmentDetail = false
    
    private let listenerKey = "todaysAppointments"
    
    var sortedAppointments: [Appointment] {
        appointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                FitConnectColors.backgroundDark
                    .ignoresSafeArea(.all)
                
                if isLoading && appointments.isEmpty {
                    loadingView
                } else if appointments.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    appointmentsListView
                }
            }
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewAppointment = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(FitConnectColors.accentPurple)
                    }
                }
            }
            .refreshable {
                await refreshAppointments()
            }
            .onAppear {
                startListening()
            }
            .onDisappear {
                stopListening()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    clearError()
                }
            } message: {
                Text(errorMessage ?? "Unable to load appointments. Pull to retry.")
            }
            .sheet(isPresented: $showingNewAppointment) {
                NewAppointmentView()
                    .environmentObject(session)
            }
            .sheet(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment)
                    .environmentObject(session)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentPurple))
                .scaleEffect(1.2)
            
            Text("Loading appointments...")
                .foregroundColor(FitConnectColors.textSecondary)
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 64))
                .foregroundColor(FitConnectColors.textTertiary)
            
            Text("No Appointments Today")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(FitConnectColors.textPrimary)
            
            Text("Your schedule is clear for today.\nPull down to refresh or tap + to add a new appointment.")
                .font(.body)
                .foregroundColor(FitConnectColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Button {
                showingNewAppointment = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("New Appointment")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(FitConnectColors.accentPurple)
                .cornerRadius(25)
            }
        }
        .padding()
    }
    
    private var appointmentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sortedAppointments) { appointment in
                    AppointmentRowView(
                        appointment: appointment,
                        onTap: {
                            selectedAppointment = appointment
                        },
                        onConfirm: {
                            Task {
                                await confirmAppointment(appointment)
                            }
                        },
                        onCancel: {
                            Task {
                                await cancelAppointment(appointment)
                            }
                        }
                    )
                    .animation(.easeInOut(duration: 0.3), value: sortedAppointments)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100) // Space for FAB
        }
    }
    
    // MARK: - Actions
    
    private func startListening() {
        guard let dietitianId = session.currentUserId, !dietitianId.isEmpty else {
            setError("Invalid dietitian ID")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let listener = appointmentService.listenForTodaysAppointments(for: dietitianId) { result in
            DispatchQueue.main.async {
                
                self.isLoading = false
                
                switch result {
                case .success(let fetchedAppointments):
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.appointments = fetchedAppointments
                    }
                    self.errorMessage = nil
                    self.showError = false
                case .failure(let error):
                    self.setError("Failed to load appointments: \(error.localizedDescription)")
                    print("[AppointmentListView] Error: \(error)")
                }
            }
        }
        
        appointmentService.startListening(key: listenerKey, listener: listener)
    }
    
    private func stopListening() {
        appointmentService.stopListening(key: listenerKey)
    }
    
    private func refreshAppointments() async {
        guard let dietitianId = session.currentUserId, !dietitianId.isEmpty else {
            setError("Invalid dietitian ID")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedAppointments = try await appointmentService.getTodaysAppointments(for: dietitianId)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.appointments = fetchedAppointments
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.setError("Failed to refresh appointments: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    private func confirmAppointment(_ appointment: Appointment) async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
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
    
    private func cancelAppointment(_ appointment: Appointment) async {
        guard let appointmentId = appointment.id,
              let dietitianId = session.currentUserId else {
            setError("Invalid appointment or dietitian ID")
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
    
    // MARK: - Helper Methods
    
    private func setError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
}

// MARK: - Enhanced Row View Component

@available(iOS 16.0, *)
struct AppointmentRowView: View {
    let appointment: Appointment
    let onTap: () -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with time and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.timeRangeString)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(FitConnectColors.textPrimary)
                        
                        Text(appointment.durationString)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(FitConnectColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Status badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appointment.status.color)
                            .frame(width: 8, height: 8)
                        
                        Text(appointment.status.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(appointment.status.color)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appointment.status.color.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Client info
                HStack(spacing: 12) {
                    // Avatar placeholder
                    Circle()
                        .fill(FitConnectColors.accentPurple.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(FitConnectColors.accentPurple)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appointment.clientName ?? "Unknown Client")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(FitConnectColors.textPrimary)
                        
                        Text("Client ID: \(appointment.clientId)")
                            .font(.system(size: 12))
                            .foregroundColor(FitConnectColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(FitConnectColors.textTertiary)
                }
                
                // Notes (if any)
                if let notes = appointment.notes, !notes.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 14))
                            .foregroundColor(FitConnectColors.textTertiary)
                        
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(FitConnectColors.textSecondary)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                }
                
                // Action buttons (only for pending appointments)
                if appointment.status == .pending {
                    HStack(spacing: 12) {
                        Button(action: {
                            onConfirm()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Confirm")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(FitConnectColors.accentGreen)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            onCancel()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Cancel")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
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
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct AppointmentListView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentListView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif
