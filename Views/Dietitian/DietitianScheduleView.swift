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
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#121212")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("Schedule")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                
                // Date Selector
                Button(action: {
                    // TODO: Show date picker
                }) {
                    Text(formatDatePill(selectedDate))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                }
                .padding(.bottom, 32)
                
                // Content Area with FAB
                ZStack {
                    // Appointments List or Empty State
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                            .scaleEffect(1.5)
                        Spacer()
                    } else if appointmentsForSelectedDate.isEmpty {
                        // Empty State
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No appointments for this day")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Appointments List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(Array(appointmentsForSelectedDate.enumerated()), id: \.element.id) { index, appointment in
                                    AppointmentCardView(appointment: appointment)
                                        .padding(.horizontal, 20)
                                        .opacity(showContent ? 1.0 : 0.0)
                                        .offset(x: showContent ? 0 : -50)
                                        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: showContent)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    
                    // Floating Action Button
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: { showingAddAppointment = true }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 72, height: 72)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            if let dietitianId = session.currentUserId {
                viewModel.loadAppointments(dietitianId: dietitianId)
            }
            
            withAnimation {
                showContent = true
            }
        }
        .sheet(isPresented: $showingAddAppointment) {
            AddAppointmentView(isPresented: $showingAddAppointment, selectedDate: selectedDate)
                .environmentObject(viewModel)
        }
    }
    
    private var appointmentsForSelectedDate: [Appointment] {
        let calendar = Calendar.current
        return viewModel.appointments.filter { appointment in
            calendar.isDate(appointment.startTime.dateValue(), inSameDayAs: selectedDate)
        }.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
    }
    
    private func formatDatePill(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct AppointmentCardView: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                )
            
            // Appointment Details
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
            
            // Status
            Text(appointment.status.displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(appointment.status.color)
        }
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(appointment.status.color.opacity(0.5), lineWidth: 2)
        )
    }
}

struct AddAppointmentView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: DietitianScheduleViewModel
    @EnvironmentObject var session: SessionStore
    
    let selectedDate: Date
    
    @State private var selectedClient: ClientProfile?
    @State private var appointmentDateTime = Date()
    @State private var selectedDuration: TimeInterval = 3600 // 1 hour default
    @State private var notes = ""
    @State private var clients: [ClientProfile] = []
    @State private var searchText = ""
    @State private var showClientList = false
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = "Missing or insufficient permissions"
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal Container
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("New Appointment")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Client Selector
                        VStack(spacing: 12) {
                            Button(action: { showClientList.toggle() }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    if let client = selectedClient {
                                        AsyncImage(url: URL(string: client.avatarURL ?? "")) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.white.opacity(0.3))
                                                .overlay(
                                                    Text(client.name.prefix(1))
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                        
                                        Text(client.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    } else {
                                        Text("Search clients...")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 50)
                                .background(Color(hex: "#1E1E1E"))
                                .cornerRadius(16)
                            }
                            
                            if showClientList {
                                if filteredClients.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "person.2")
                                            .font(.system(size: 32))
                                            .foregroundColor(.gray)
                                        
                                        Text("No clients found")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 24)
                                } else {
                                    LazyVStack(spacing: 8) {
                                        ForEach(filteredClients) { client in
                                            ClientSelectionRow(
                                                client: client,
                                                isSelected: selectedClient?.id == client.id
                                            ) {
                                                selectedClient = client
                                                showClientList = false
                                            }
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // Date & Time Picker
                        VStack(spacing: 16) {
                            // Date/Time Pill Display
                            Text(formatDateTime(appointmentDateTime))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(25)
                            
                            // Date Picker
                            DatePicker("Select Date & Time", selection: $appointmentDateTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .colorScheme(.dark)
                                .background(Color(hex: "#1E1E1E"))
                                .cornerRadius(16)
                        }
                        
                        // Duration Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 0) {
                                DurationButton(title: "30 minutes", duration: 1800, selectedDuration: $selectedDuration)
                                DurationButton(title: "1 hour", duration: 3600, selectedDuration: $selectedDuration)
                                DurationButton(title: "1.5 hours", duration: 5400, selectedDuration: $selectedDuration)
                                DurationButton(title: "2 hours", duration: 7200, selectedDuration: $selectedDuration)
                            }
                        }
                        
                        // Notes Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            TextEditor(text: $notes)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color(hex: "#1E1E1E"))
                                .cornerRadius(16)
                                .overlay(
                                    HStack {
                                        if notes.isEmpty {
                                            Text("Add notes...")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white.opacity(0.6))
                                                .padding(.leading, 16)
                                                .padding(.top, 20)
                                        }
                                        Spacer()
                                    },
                                    alignment: .topLeading
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Error Banner
                if showError {
                    HStack {
                        Text(errorMessage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color(hex: "#FF4C4C"))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Create Button
                VStack(spacing: 0) {
                    Button(action: createAppointment) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                                Spacer().frame(width: 8)
                            }
                            
                            Text("Create Appointment")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .opacity(isFormValid ? 1.0 : 0.5)
                    }
                    .disabled(!isFormValid || isCreating)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
            .background(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .padding(.horizontal, UIScreen.main.bounds.width * 0.05)
            .padding(.top, UIScreen.main.bounds.height * 0.2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .onAppear {
            loadClients()
            setupInitialDateTime()
        }
        .animation(.easeInOut(duration: 0.3), value: showError)
    }
    
    private var isFormValid: Bool {
        selectedClient != nil && appointmentDateTime > Date()
    }
    
    private var filteredClients: [ClientProfile] {
        if searchText.isEmpty {
            return clients
        } else {
            return clients.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy h:mm a"
        return formatter.string(from: date)
    }
    
    private func setupInitialDateTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = calendar.component(.hour, from: Date()) + 1
        components.minute = 0
        appointmentDateTime = calendar.date(from: components) ?? Date()
    }
    
    private func loadClients() {
        guard let dietitianId = session.currentUserId else { return }
        
        // Mock data for demo
        clients = [
            ClientProfile(
                name: "Lucy Olson",
                email: "lucy@example.com",
                assignedDietitianId: dietitianId,
                avatarURL: nil
            ),
            ClientProfile(
                name: "John Smith",
                email: "john@example.com",
                assignedDietitianId: dietitianId,
                avatarURL: nil
            ),
            ClientProfile(
                name: "Sarah Wilson",
                email: "sarah@example.com",
                assignedDietitianId: dietitianId,
                avatarURL: nil
            )
        ]
    }
    
    private func createAppointment() {
        guard let client = selectedClient,
              let dietitianId = session.currentUserId else { return }
        
        isCreating = true
        showError = false
        
        let endTime = appointmentDateTime.addingTimeInterval(selectedDuration)
        
        viewModel.createAppointment(
            clientId: client.id ?? "",
            clientName: client.name,
            startTime: appointmentDateTime,
            endTime: endTime,
            notes: notes.isEmpty ? nil : notes
        ) { success, error in
            DispatchQueue.main.async {
                isCreating = false
                
                if success {
                    isPresented = false
                } else {
                    errorMessage = error?.localizedDescription ?? "Missing or insufficient permissions"
                    showError = true
                    
                    // Auto-hide error after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        showError = false
                    }
                }
            }
        }
    }
}

struct DurationButton: View {
    let title: String
    let duration: TimeInterval
    @Binding var selectedDuration: TimeInterval
    
    var isSelected: Bool {
        selectedDuration == duration
    }
    
    var body: some View {
        Button(action: { selectedDuration = duration }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ?
                    LinearGradient(
                        colors: [Color.purple, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color(hex: "#1E1E1E") ?? .gray, Color(hex: "#1E1E1E") ?? .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
        }
    }
}

struct ClientSelectionRow: View {
    let client: ClientProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: client.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.fitConnectPurple.opacity(0.3))
                        .overlay(
                            Text(client.name.prefix(1))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(client.email)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.fitConnectPurple)
                }
            }
            .padding(12)
            .background(isSelected ? Color.fitConnectPurple.opacity(0.1) : Color.darkCardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.fitConnectPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
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
        
        // For demo purposes, create some sample appointments
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let today = Date()
            let calendar = Calendar.current
            
            // Create appointments for today
            var sampleAppointments: [Appointment] = []
            
            // Anna Mills appointment
            if let startTime = calendar.date(byAdding: .hour, value: 2, to: today),
               let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) {
                let appointment1 = Appointment(
                    clientId: "anna_mills",
                    startTime: startTime,
                    endTime: endTime,
                    notes: "Meal planning consult",
                    status: .scheduled
                )
                var appointment1WithData = appointment1
                appointment1WithData.clientName = "Anna Mills"
                sampleAppointments.append(appointment1WithData)
            }
            
            // Stephanie Cooper appointment
            if let startTime = calendar.date(byAdding: .hour, value: 4, to: today),
               let endTime = calendar.date(byAdding: .minute, value: 45, to: startTime) {
                let appointment2 = Appointment(
                    clientId: "stephanie_cooper",
                    startTime: startTime,
                    endTime: endTime,
                    notes: "Meal planning consult",
                    status: .scheduled
                )
                var appointment2WithData = appointment2
                appointment2WithData.clientName = "Stephanie Cooper"
                sampleAppointments.append(appointment2WithData)
            }
            
            self.appointments = sampleAppointments
            self.isLoading = false
        }
        
        // Real implementation would use Firestore listener
        /*
        let listener = firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
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
        */
    }
    
    func createAppointment(
        clientId: String,
        clientName: String,
        startTime: Date,
        endTime: Date,
        notes: String?,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        guard let dietitianId = Auth.auth().currentUser?.uid else {
            completion(false, NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return
        }
        
        let appointmentData: [String: Any] = [
            "clientId": clientId,
            "clientName": clientName,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "notes": notes ?? "",
            "status": AppointmentStatus.scheduled.rawValue
        ]
        
        firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .addDocument(data: appointmentData) { error in
                completion(error == nil, error)
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
