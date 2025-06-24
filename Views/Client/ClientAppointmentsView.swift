import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientAppointmentsView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ClientAppointmentsViewModel()
    @State private var showingBookAppointment = false
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Content
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.appointments.isEmpty {
                        emptyStateView
                    } else {
                        appointmentsList
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBookAppointment) {
                ClientBookAppointmentView()
                    .environmentObject(session)
                    .environmentObject(viewModel)
            }
            .onAppear {
                if let clientId = session.currentUserId,
                   let expertId = session.currentUser?.expertId, !expertId.isEmpty {
                    print("[ClientAppointments] Loading appointments - clientId: \(clientId), expertId: \(expertId)")
                    print("[ClientAppointments] User expertId: \(session.currentUser?.expertId ?? "nil")")
                    print("[ClientAppointments] User email: \(session.currentUser?.email ?? "nil")")
                    viewModel.loadAppointments(
                        clientId: clientId,
                        dietitianId: expertId
                    )
                    viewModel.expertId = expertId
                } else {
                    print("[ClientAppointments] Missing clientId or expertId - clientId: \(session.currentUserId ?? "nil"), expertId: \(session.currentUser?.expertId ?? "nil")")
                    print("[ClientAppointments] Full user object: \(session.currentUser ?? nil)")
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button {
                // Back navigation
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            
            Spacer()
            
            Text("My Appointments")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            Spacer()
            
            Button {
                showingBookAppointment = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(FitConnectColors.accentPurple)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentPurple))
                .scaleEffect(1.2)
            
            Text("Loading appointments...")
                .font(.system(size: 16))
                .foregroundColor(FitConnectColors.textSecondary)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundColor(FitConnectColors.textTertiary)
            
            VStack(spacing: 8) {
                Text("No Appointments Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Text("Book your first appointment with your dietitian")
                    .font(.system(size: 16))
                    .foregroundColor(FitConnectColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingBookAppointment = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Book Appointment")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(FitConnectColors.accentPurple)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var appointmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.upcomingAppointments) { appointment in
                    ClientAppointmentCardView(
                        appointment: appointment,
                        viewModel: viewModel
                    )
                        .padding(.horizontal, 20)
                }
                
                if !viewModel.pastAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Past Appointments")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(FitConnectColors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        ForEach(viewModel.pastAppointments) { appointment in
                            ClientAppointmentCardView(
                                appointment: appointment,
                                isPast: true,
                                viewModel: viewModel
                            )
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
}

struct ClientAppointmentCardView: View {
    let appointment: Appointment
    var isPast: Bool = false
    let viewModel: ClientAppointmentsViewModel
    
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(FitConnectColors.textPrimary)
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 14))
                        .foregroundColor(FitConnectColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(appointment.status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(appointment.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appointment.status.color.opacity(0.2))
                        .cornerRadius(6)
                    
                    Text(appointment.durationString)
                        .font(.system(size: 12))
                        .foregroundColor(FitConnectColors.textTertiary)
                    
                    if !isPast && appointment.isUpcoming() {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(FitConnectColors.accentBlue)
                    }
                }
            }
            
            if let notes = appointment.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 14))
                    .foregroundColor(FitConnectColors.textSecondary)
                    .padding(.top, 4)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 20))
                    .foregroundColor(FitConnectColors.accentBlue)
                
                Text("Your Dietitian")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(16)
        .opacity(isPast ? 0.7 : 1.0)
        .onTapGesture {
            if !isPast && appointment.isUpcoming() {
                showingDetail = true
            }
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showingDetail) {
            ClientAppointmentDetailModal(
                appointment: appointment,
                onCancel: {
                    viewModel.cancelAppointment(appointment)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

class ClientAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    var expertId: String = ""
    
    private var listener: ListenerRegistration?
    
    var upcomingAppointments: [Appointment] {
        appointments
            .filter { $0.startTime.dateValue() > Date() }
            .sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
    }
    
    var pastAppointments: [Appointment] {
        appointments
            .filter { $0.startTime.dateValue() <= Date() }
            .sorted { $0.startTime.dateValue() > $1.startTime.dateValue() }
    }
    
    func loadAppointments(clientId: String, dietitianId: String) {
        isLoading = true
        
        print("[ClientAppointments] Loading appointments for client: \(clientId), dietitian: \(dietitianId)")
        
        listener = Firestore.firestore()
            .collection("dietitians")
            .document(dietitianId)
            .collection("appointments")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("[ClientAppointments] Error loading appointments: \(error)")
                        self?.showError(error.localizedDescription)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("[ClientAppointments] No documents found")
                        self?.appointments = []
                        return
                    }
                    
                    print("[ClientAppointments] Found \(documents.count) appointment documents")
                    
                    let allAppointments = documents.compactMap { doc -> Appointment? in
                        do {
                            var appointment = try doc.data(as: Appointment.self)
                            appointment.id = doc.documentID
                            return appointment
                        } catch {
                            print("[ClientAppointments] Error decoding appointment: \(error)")
                            return nil
                        }
                    }
                    
                    self?.appointments = allAppointments
                        .filter { $0.clientId == clientId }
                        .sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
                    
                    print("[ClientAppointments] Final filtered appointments count: \(self?.appointments.count ?? 0)")
                }
            }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    deinit {
        listener?.remove()
    }
    
    func cancelAppointment(_ appointment: Appointment) {
        guard let appointmentId = appointment.id, !expertId.isEmpty else { 
            print("[ClientAppointments] Cancel failed - appointmentId: \(appointment.id ?? "nil"), expertId: \(expertId)")
            showError("Unable to cancel appointment. Missing appointment information.")
            return 
        }
        
        print("[ClientAppointments] Attempting to cancel appointment \(appointmentId) for dietitian \(expertId)")
        
        Task {
            do {
                try await AppointmentService.shared.updateAppointmentStatus(
                    dietitianId: expertId,
                    appointmentId: appointmentId,
                    status: .cancelled
                )
                
                print("[ClientAppointments] Successfully cancelled appointment \(appointmentId)")
                
            } catch {
                await MainActor.run {
                    print("[ClientAppointments] Failed to cancel appointment: \(error)")
                    self.showError("Failed to cancel appointment: \(error.localizedDescription)")
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct ClientAppointmentsView_Previews: PreviewProvider {
    static var previews: some View {
        ClientAppointmentsView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "client"))
            .preferredColorScheme(.dark)
    }
}
#endif