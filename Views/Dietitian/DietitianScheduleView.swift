import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct DietitianScheduleView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = DietitianScheduleViewModel()
    @State private var showingAddAppointment = false
    @State private var selectedDate = Date()
    @State private var showContent = false
    @State private var showAllAppointments = false
    @State private var selectedAppointment: Appointment?
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                
                VStack(spacing: 0) {
                    headerView
                    
                    HStack {
                        Button(action: {
                            showAllAppointments.toggle()
                        }) {
                            Text(showAllAppointments ? "Show Today Only" : "Show All Appointments")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    dateSelectorView
                    
                    contentAreaView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAppointments()
                animateContent()
            }
            .sheet(isPresented: $showingAddAppointment) {
                NewAppointmentView()
                    .environmentObject(session)
            }
            .background(
                NavigationLink(
                    destination: selectedAppointment.map { appointment in
                        AppointmentDetailView(appointment: appointment)
                            .environmentObject(session)
                    },
                    isActive: Binding(
                        get: { selectedAppointment != nil },
                        set: { if !$0 { selectedAppointment = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var backgroundView: some View {
        Color(hex: "#121212")
            .ignoresSafeArea()
    }
    
    private var headerView: some View {
        Text("Schedule")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .padding(.top, 20)
            .padding(.bottom, 24)
    }
    
    private var dateSelectorView: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text(formatDatePill(selectedDate))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                }
                
                Spacer()
                
                Button(action: {
                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)
            
            #if DEBUG
            Text("Total: \(viewModel.appointments.count), Selected Date: \(appointmentsForSelectedDate.count)")
                .font(.caption)
                .foregroundColor(.yellow)
            #endif
        }
        .padding(.bottom, 32)
    }
    
    private var contentAreaView: some View {
        ZStack {
            mainContentView
            floatingActionButton
        }
    }
    
    private var mainContentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if currentAppointments.isEmpty {
                emptyStateView
            } else {
                appointmentsListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No appointments for this day")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var appointmentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(currentAppointments.enumerated()), id: \.element.id) { index, appointment in
                    appointmentCard(appointment: appointment, index: index)
                }
            }
            .padding(.vertical, 16)
        }
    }
    
    private func appointmentCard(appointment: Appointment, index: Int) -> some View {
        DietitianAppointmentCardView(
            appointment: appointment,
            onAccept: { viewModel.acceptAppointment(appointment) },
            onReject: { 
                if appointment.status == .pending {
                    viewModel.rejectAppointment(appointment)
                } else if appointment.status == .accepted {
                    viewModel.cancelAppointment(appointment)
                }
            },
            onCancel: { viewModel.cancelAppointment(appointment) },
            onTap: { appointment in
                if appointment.status == .accepted {
                    selectedAppointment = appointment
                }
            }
        )
        .padding(.horizontal, 20)
        .opacity(showContent ? 1.0 : 0.0)
        .offset(x: showContent ? 0 : -50)
        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: showContent)
    }
    
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: { showingAddAppointment = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 64, height: 64)
                        .background(fabGradient)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 32)
            }
        }
    }
    
    private var fabGradient: LinearGradient {
        LinearGradient(
            colors: [Color.purple, Color.indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func loadAppointments() {
        if let dietitianId = session.currentUserId {
            viewModel.loadAppointments(dietitianId: dietitianId)
        }
    }
    
    private func animateContent() {
        withAnimation {
            showContent = true
        }
    }
    
    private var currentAppointments: [Appointment] {
        if showAllAppointments {
            return viewModel.appointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
        } else {
            return appointmentsForSelectedDate
        }
    }
    
    private var appointmentsForSelectedDate: [Appointment] {
        let calendar = Calendar.current
        let filtered = showAllAppointments ? viewModel.appointments : viewModel.appointments.filter { appointment in
            let appointmentDate = appointment.startTime.dateValue()
            let isToday = calendar.isDate(appointmentDate, inSameDayAs: selectedDate)
            
            #if DEBUG
            if !isToday {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                print("[DietitianSchedule] Appointment on \(dateFormatter.string(from: appointmentDate)) doesn't match selected \(dateFormatter.string(from: selectedDate))")
            }
            #endif
            
            return isToday
        }.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
        
        #if DEBUG
        print("[DietitianSchedule] Filtering appointments: \(viewModel.appointments.count) total, \(filtered.count) for selected date")
        #endif
        
        return filtered
    }
    
    private func formatDatePill(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct DietitianAppointmentCardView: View {
    let appointment: Appointment
    let onAccept: () -> Void
    let onReject: () -> Void
    let onCancel: () -> Void
    let onTap: (Appointment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.clientName ?? "Unknown Client")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.green)
                    
                    if let notes = appointment.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(appointment.status.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(appointment.status.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(appointment.status.color.opacity(0.2))
                        .cornerRadius(6)
                    
                    Text(appointment.durationString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if appointment.status == .accepted {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if appointment.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Reject")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(action: onAccept) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Accept")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(appointment.status.color.opacity(0.5), lineWidth: 2)
        )
        .onTapGesture {
            onTap(appointment)
        }
        .contentShape(Rectangle())
    }
}

class DietitianScheduleViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var listeners: [ListenerRegistration] = []
    private var firestore = Firestore.firestore()
    
    func loadAppointments(dietitianId: String) {
        isLoading = true
        errorMessage = nil
        
        let listener = firestore.collection("dietitians")
            .document(dietitianId)
            .collection("appointments")
            .order(by: "startTime", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.appointments = []
                        return
                    }
                    
                    self?.appointments = documents.compactMap { doc in
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
            }
        
        listeners.append(listener)
    }
    
    func acceptAppointment(_ appointment: Appointment) {
        guard let appointmentId = appointment.id,
              let dietitianId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await AppointmentService.shared.updateAppointmentStatus(
                    dietitianId: dietitianId,
                    appointmentId: appointmentId,
                    status: .accepted
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to accept appointment: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func rejectAppointment(_ appointment: Appointment) {
        guard let appointmentId = appointment.id,
              let dietitianId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await AppointmentService.shared.updateAppointmentStatus(
                    dietitianId: dietitianId,
                    appointmentId: appointmentId,
                    status: .rejected
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to reject appointment: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func cancelAppointment(_ appointment: Appointment) {
        guard let appointmentId = appointment.id,
              let dietitianId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await AppointmentService.shared.updateAppointmentStatus(
                    dietitianId: dietitianId,
                    appointmentId: appointmentId,
                    status: .cancelled
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel appointment: \(error.localizedDescription)"
                }
            }
        }
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianScheduleView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianScheduleView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif