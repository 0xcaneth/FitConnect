import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    
    @State private var selectedClient: ClientProfile?
    @State private var selectedDate = Date()
    @State private var selectedStartTime = Date()
    @State private var duration: TimeInterval = 3600 // 1 hour default
    @State private var notes = ""
    @State private var searchText = ""
    @State private var searchResults: [ClientProfile] = []
    @State private var isSearching = false
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var conflicts: [Appointment] = []
    @State private var showConflictAlert = false
    @State private var allClients: [ClientProfile] = []
    
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
    
    var body: some View {
        NavigationView {
            ZStack {
                FitConnectColors.backgroundDark.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Client Selection
                        clientSelectionSection
                        
                        // Date & Time
                        dateTimeSection
                        
                        // Duration
                        durationSection
                        
                        // Notes
                        notesSection
                        
                        // Create Button
                        createButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("New Appointment")
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
                        await createAppointmentForcefully()
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
            .onAppear {
                loadAllClients()
            }
        }
    }
    
    private var clientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Client")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(FitConnectColors.textPrimary)
            
            VStack(spacing: 12) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(FitConnectColors.textTertiary)
                    
                    TextField("Search clients by name or email", text: $searchText)
                        .font(.system(size: 16))
                        .foregroundColor(FitConnectColors.textPrimary)
                        .onChange(of: searchText) { newValue in
                            if newValue.isEmpty {
                                // Show all clients when search is empty
                                searchResults = Array(allClients.prefix(10))
                            } else {
                                Task {
                                    await searchClients(query: newValue)
                                }
                            }
                        }
                        .onTapGesture {
                            // Show all clients when field is tapped
                            if searchResults.isEmpty {
                                searchResults = Array(allClients.prefix(10))
                            }
                        }
                }
                .padding(12)
                .background(FitConnectColors.inputBackground)
                .cornerRadius(8)
                
                // Selected Client or Search Results
                if let selectedClient = selectedClient {
                    selectedClientView(selectedClient)
                } else if !searchResults.isEmpty {
                    searchResultsView
                } else if isSearching {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: FitConnectColors.accentPurple))
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .font(.system(size: 14))
                            .foregroundColor(FitConnectColors.textSecondary)
                    }
                    .padding(.vertical, 20)
                } else if !searchText.isEmpty {
                    Text("No clients found")
                        .font(.system(size: 14))
                        .foregroundColor(FitConnectColors.textSecondary)
                        .padding(.vertical, 20)
                }
            }
        }
        .padding(20)
        .background(FitConnectColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func selectedClientView(_ client: ClientProfile) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(FitConnectColors.accentPurple.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(FitConnectColors.accentPurple)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FitConnectColors.textPrimary)
                
                Text(client.email)
                    .font(.system(size: 14))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
            
            Spacer()
            
            Button("Change") {
                selectedClient = nil
                searchText = ""
                searchResults = []
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(FitConnectColors.accentPurple)
        }
        .padding(12)
        .background(FitConnectColors.accentPurple.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var searchResultsView: some View {
        VStack(spacing: 8) {
            ForEach(searchResults.prefix(5)) { client in
                Button {
                    selectedClient = client
                    searchText = client.name
                    searchResults = []
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(FitConnectColors.accentPurple.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(FitConnectColors.accentPurple)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(client.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(FitConnectColors.textPrimary)
                            
                            Text(client.email)
                                .font(.system(size: 12))
                                .foregroundColor(FitConnectColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .background(FitConnectColors.inputBackground)
        .cornerRadius(8)
    }
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
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
                .colorScheme(.dark)
                
                DatePicker(
                    "Start Time",
                    selection: $selectedStartTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(CompactDatePickerStyle())
                .foregroundColor(FitConnectColors.textPrimary)
                .colorScheme(.dark)
                
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
                                duration == option.1 ? 
                                LinearGradient(
                                    colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) : 
                                LinearGradient(
                                    colors: [FitConnectColors.inputBackground, FitConnectColors.inputBackground],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
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
    
    private var createButton: some View {
        Button {
            Task {
                await createAppointment()
            }
        } label: {
            HStack {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isCreating ? "Creating..." : "Create Appointment")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isFormValid ? 
                LinearGradient(
                    colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                    startPoint: .leading,
                    endPoint: .trailing
                ) : 
                LinearGradient(
                    colors: [FitConnectColors.textTertiary, FitConnectColors.textTertiary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isCreating)
    }
    
    private var isFormValid: Bool {
        selectedClient != nil
    }
    
    // MARK: - Actions
    
    private func searchClients(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        guard let dietitianId = session.currentUserId else {
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
            return
        }
        
        print("[NewAppointment] Searching for clients with query: '\(query)' for dietitian: \(dietitianId)")
        
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("dietitians")
                .document(dietitianId)
                .collection("clients")
                .getDocuments()
            
            print("[NewAppointment] Found \(snapshot.documents.count) client documents")
            
            let clients = snapshot.documents.compactMap { doc -> ClientProfile? in
                do {
                    let client = try doc.data(as: ClientProfile.self)
                    print("[NewAppointment] Loaded client: \(client.name) (\(client.email))")
                    return client
                } catch {
                    print("[NewAppointment] Error decoding client: \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.allClients = clients
                self.searchResults = clients.filter { client in
                    client.name.localizedCaseInsensitiveContains(query) ||
                    client.email.localizedCaseInsensitiveContains(query)
                }
                self.isSearching = false
                print("[NewAppointment] Filtered results: \(self.searchResults.count) clients")
            }
        } catch {
            print("[NewAppointment] Error fetching clients: \(error)")
            await MainActor.run {
                searchResults = []
                isSearching = false
            }
        }
    }
    
    private func createAppointment() async {
        guard let client = selectedClient,
              let dietitianId = session.currentUserId else {
            setError("Missing required information")
            return
        }
        
        isCreating = true
        
        do {
            // Check for conflicts first
            let conflictingAppointments = try await AppointmentService.shared.checkForConflicts(
                dietitianId: dietitianId,
                startTime: combineDateTime(selectedDate, selectedStartTime),
                endTime: selectedEndTime
            )
            
            if !conflictingAppointments.isEmpty {
                conflicts = conflictingAppointments
                showConflictAlert = true
                isCreating = false
                return
            }
            
            // Create the appointment
            let _ = try await AppointmentService.shared.createAppointment(
                dietitianId: dietitianId,
                clientId: client.id ?? "",
                clientName: client.name,
                startTime: combineDateTime(selectedDate, selectedStartTime),
                endTime: selectedEndTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isCreating = false
                dismiss()
            }
            
        } catch let error as AppointmentError {
            await MainActor.run {
                setError(error.localizedDescription)
                isCreating = false
            }
        } catch {
            await MainActor.run {
                setError("Failed to create appointment: \(error.localizedDescription)")
                isCreating = false
            }
        }
    }
    
    private func createAppointmentForcefully() async {
        guard let client = selectedClient,
              let dietitianId = session.currentUserId else {
            setError("Missing required information")
            return
        }
        
        isCreating = true
        
        do {
            let _ = try await AppointmentService.shared.createAppointment(
                dietitianId: dietitianId,
                clientId: client.id ?? "",
                clientName: client.name,
                startTime: combineDateTime(selectedDate, selectedStartTime),
                endTime: selectedEndTime,
                notes: notes.isEmpty ? nil : notes
            )
            
            await MainActor.run {
                isCreating = false
                dismiss()
            }
            
        } catch {
            await MainActor.run {
                setError("Failed to create appointment: \(error.localizedDescription)")
                isCreating = false
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
    
    private func loadAllClients() {
        guard let dietitianId = session.currentUserId else { return }
        
        print("[NewAppointment] Loading all clients for dietitian: \(dietitianId)")
        
        Task {
            do {
                let db = Firestore.firestore()
                let snapshot = try await db.collection("dietitians")
                    .document(dietitianId)
                    .collection("clients")
                    .getDocuments()
                
                print("[NewAppointment] Found \(snapshot.documents.count) total clients in dietitians collection")
                
                let clients = snapshot.documents.compactMap { doc -> ClientProfile? in
                    do {
                        let client = try doc.data(as: ClientProfile.self)
                        print("[NewAppointment] Client: \(client.name) (\(client.email))")
                        return client
                    } catch {
                        print("[NewAppointment] Error decoding client: \(error)")
                        return nil
                    }
                }
                
                await MainActor.run {
                    self.allClients = clients
                    if searchText.isEmpty {
                        self.searchResults = Array(clients.prefix(10))
                    }
                    
                    // If no clients found in dietitians collection, try users collection
                    if clients.isEmpty {
                        print("[NewAppointment] No clients in dietitians collection, trying users collection...")
                        self.loadClientsFromUsers()
                    }
                }
                
            } catch {
                print("[NewAppointment] Error loading clients: \(error)")
                // Fallback to users collection
                loadClientsFromUsers()
            }
        }
    }
    
    private func loadClientsFromUsers() {
        guard let dietitianId = session.currentUserId else { return }
        
        print("[NewAppointment] Loading clients from users collection where expertId = \(dietitianId)")
        
        Task {
            do {
                let db = Firestore.firestore()
                let snapshot = try await db.collection("users")
                    .whereField("expertId", isEqualTo: dietitianId)
                    .getDocuments()
                
                print("[NewAppointment] Found \(snapshot.documents.count) users with this dietitian as expert")
                
                let clients = snapshot.documents.compactMap { doc -> ClientProfile? in
                    let data = doc.data()
                    
                    let name = data["fullName"] as? String ?? "Unknown"
                    let email = data["email"] as? String ?? ""
                    
                    print("[NewAppointment] User: \(name) (\(email))")
                    
                    return ClientProfile(
                        name: name,
                        email: email,
                        assignedDietitianId: dietitianId
                    )
                }
                
                await MainActor.run {
                    if self.allClients.isEmpty {
                        self.allClients = clients
                        self.searchResults = Array(clients.prefix(10))
                        print("[NewAppointment] Loaded \(clients.count) clients from users collection")
                    }
                }
                
            } catch {
                print("[NewAppointment] Error loading from users collection: \(error)")
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct NewAppointmentView_Previews: PreviewProvider {
    static var previews: some View {
        NewAppointmentView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif