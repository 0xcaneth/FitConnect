import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@available(iOS 16.0, *)
struct DietitianDashboardView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = DietitianDashboardViewModel()
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Dark background matching the design
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header with dietitian info
                    VStack(spacing: 12) {
                        if let dietitianName = viewModel.dietitianName {
                            HStack {
                                // Profile image
                                AsyncImage(url: viewModel.dietitianPhotoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.title2)
                                                .foregroundColor(.white.opacity(0.6))
                                        )
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Welcome back,")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(dietitianName)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 40)
                    
                    // Metric Cards
                    HStack(spacing: 12) {
                        DashboardMetricCard(
                            icon: "person.3.fill",
                            count: "\(viewModel.activeClientsCount)",
                            label: "Active Clients",
                            isLoading: viewModel.isLoadingClients,
                            accentColor: Color(hex: "#22C55E") ?? .green
                        )
                        
                        DashboardMetricCard(
                            icon: "calendar.badge.clock",
                            count: "\(viewModel.todayAppointmentsCount)",
                            label: "Today's Appointments",
                            isLoading: viewModel.isLoadingAppointments,
                            accentColor: Color(hex: "#3B82F6") ?? .blue
                        )
                        
                        DashboardMetricCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            count: "\(viewModel.unreadMessagesCount)",
                            label: "Unread Messages",
                            isLoading: viewModel.isLoadingMessages,
                            accentColor: Color(hex: "#F59E0B") ?? .orange
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Today's Appointments Panel
                    TodaysAppointmentsPanel(
                        appointments: viewModel.todaysAppointments,
                        isLoading: viewModel.isLoadingAppointments
                    )
                    .padding(.horizontal, 16)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                    
                    // Client Progress Overview Panel
                    ClientProgressOverviewPanel(
                        progressSummaries: viewModel.clientProgressSummaries,
                        isLoading: viewModel.isLoadingClients
                    )
                    .padding(.horizontal, 16)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.4), value: showContent)
                    
                    Spacer(minLength: 100)
                }
            }
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 30)
            .animation(.easeOut(duration: 0.8), value: showContent)
        }
        .onAppear {
            if let dietitianId = session.currentUserId {
                viewModel.loadDashboardData(dietitianId: dietitianId)
            }
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

struct ClientProgressOverviewPanel: View {
    let progressSummaries: [ClientProgressSummary]
    let isLoading: Bool
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Client Progress Overview")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Content
            if isLoading {
                // Loading State
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading client progress...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if progressSummaries.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "person.3.sequence")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No clients with progress data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Client progress will appear here once they start logging health data")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Client Progress Cards - Horizontal Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(progressSummaries.prefix(10)) { summary in
                            ClientProgressCard(summary: summary)
                                .onTapGesture {
                                    // Navigate to client progress detail
                                    navigateToClientProgress(summary.clientId)
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#9333EA"), lineWidth: 1)
        )
    }
    
    private func navigateToClientProgress(_ clientId: String) {
        // Implementation for navigation to client progress detail
        // This would be handled by your navigation system
        print("Navigate to progress for client: \(clientId)")
    }
}

struct ClientProgressCard: View {
    let summary: ClientProgressSummary
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            AsyncImage(url: summary.clientAvatarURL.flatMap(URL.init)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.6))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Client Name
            Text(summary.clientName.components(separatedBy: " ").first ?? summary.clientName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Weight and Date
            VStack(spacing: 2) {
                Text(summary.displayWeight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(summary.lastUpdateString)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            // Secondary Metric (BMI or Body Fat)
            Text(summary.displaySecondaryMetric)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TodaysAppointmentsPanel: View {
    let appointments: [Appointment]
    let isLoading: Bool
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Today's Appointments")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                
                if !appointments.isEmpty {
                    Text("\(appointments.count)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#22C55E"))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Content
            if isLoading {
                // Loading State
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading appointments...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if appointments.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    Text("No appointments today")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    Text("Enjoy your free day!")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Appointments List
                LazyVStack(spacing: 12) {
                    ForEach(appointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }) { appointment in
                        DashboardAppointmentRowView(appointment: appointment)
                            .environmentObject(session)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: "#22C55E"), lineWidth: 1)
        )
    }
}

struct DashboardAppointmentRowView: View {
    let appointment: Appointment
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        Button(action: {
            // Navigate to appointment detail or chat
            // This would be implemented based on your navigation structure
        }) {
            HStack(spacing: 16) {
                // Time indicator
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.shortTimeString)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(appointment.durationString)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .frame(width: 70, alignment: .leading)
                
                // Client Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.clientName ?? "Unknown Client")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let notes = appointment.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Status
                Text(statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Chat Icon
                Button(action: {
                    // Navigate to chat with this client
                    navigateToClientChat()
                }) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#9333EA"))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusText: String {
        switch appointment.status {
        case .scheduled:
            return "Confirmed"
        case .cancelled, .noShow:
            return "Pending"
        case .completed:
            return "Completed"
        case .pending:
            return "Pending"
        case .confirmed:
            return "Confirmed"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        }
    }
    
    private var statusColor: Color {
        switch appointment.status {
        case .scheduled, .completed, .confirmed, .accepted:
            return .green
        case .cancelled, .noShow, .rejected:
            return .red
        case .pending:
            return .orange
        }
    }
    
    private func navigateToClientChat() {
        // This would navigate to the chat view for this client
        // Implementation depends on your navigation structure
        // You might need to find the chat ID for this client and navigate there
    }
}

@MainActor
class DietitianDashboardViewModel: ObservableObject {
    @Published var activeClientsCount: Int = 0
    @Published var todayAppointmentsCount: Int = 0
    @Published var unreadMessagesCount: Int = 0
    @Published var todaysAppointments: [Appointment] = []
    @Published var clientProgressSummaries: [ClientProgressSummary] = []
    @Published var dietitianName: String?
    @Published var dietitianPhotoURL: URL?
    
    // Loading states
    @Published var isLoadingClients: Bool = true
    @Published var isLoadingAppointments: Bool = true
    @Published var isLoadingMessages: Bool = true
    
    private var firestore = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let appointmentService = AppointmentService.shared
    
    func loadDashboardData(dietitianId: String) {
        loadDietitianProfile(dietitianId: dietitianId)
        setupRealtimeListeners(dietitianId: dietitianId)
    }
    
    private func loadDietitianProfile(dietitianId: String) {
        firestore.collection("users").document(dietitianId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading dietitian profile: \(error)")
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("Dietitian document not found")
                return
            }
            
            DispatchQueue.main.async {
                self.dietitianName = data["fullName"] as? String
                if let photoURLString = data["photoURL"] as? String {
                    self.dietitianPhotoURL = URL(string: photoURLString)
                }
            }
        }
    }
    
    private func setupRealtimeListeners(dietitianId: String) {
        setupClientsListener(dietitianId: dietitianId)
        setupAppointmentsListener(dietitianId: dietitianId)
        setupMessagesListener(dietitianId: dietitianId)
    }
    
    private func setupClientsListener(dietitianId: String) {
        let clientsListener = firestore.collection("dietitians")
            .document(dietitianId)
            .collection("clients")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to clients: \(error)")
                    DispatchQueue.main.async {
                        self.isLoadingClients = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.activeClientsCount = 0
                        self.isLoadingClients = false
                    }
                    return
                }
                
                let clientIds = documents.map { $0.documentID }
                
                DispatchQueue.main.async {
                    self.activeClientsCount = clientIds.count
                }
                
                // Fetch detailed client info for progress summaries
                self.fetchClientProgressSummaries(clientIds: clientIds)
            }
        
        listeners.append(clientsListener)
    }
    
    private func setupAppointmentsListener(dietitianId: String) {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let appointmentsListener = firestore.collection("dietitians")
            .document(dietitianId)
            .collection("appointments")
            .whereField("startTime", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("startTime", isLessThan: Timestamp(date: endOfDay))
            .order(by: "startTime")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to appointments: \(error)")
                    DispatchQueue.main.async {
                        self.isLoadingAppointments = false
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.todaysAppointments = []
                        self.todayAppointmentsCount = 0
                        self.isLoadingAppointments = false
                    }
                    return
                }
                
                let appointments = documents.compactMap { doc -> Appointment? in
                    do {
                        var appointment = try doc.data(as: Appointment.self)
                        appointment.id = doc.documentID
                        return appointment
                    } catch {
                        print("Error decoding appointment: \(error)")
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.todaysAppointments = appointments
                    self.todayAppointmentsCount = appointments.count
                    self.isLoadingAppointments = false
                }
            }
        
        listeners.append(appointmentsListener)
    }
    
    private func setupMessagesListener(dietitianId: String) {
        // Listen for messages where this dietitian is the recipient and read = false
        let messagesListener = firestore.collectionGroup("messages")
            .whereField("recipientId", isEqualTo: dietitianId)
            .whereField("read", isEqualTo: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to messages: \(error)")
                    DispatchQueue.main.async {
                        self.isLoadingMessages = false
                    }
                    return
                }
                
                let unreadCount = snapshot?.documents.count ?? 0
                
                DispatchQueue.main.async {
                    self.unreadMessagesCount = unreadCount
                    self.isLoadingMessages = false
                }
            }
        
        listeners.append(messagesListener)
    }
    
    private func fetchClientProgressSummaries(clientIds: [String]) {
        guard !clientIds.isEmpty else {
            DispatchQueue.main.async {
                self.clientProgressSummaries = []
                self.isLoadingClients = false
            }
            return
        }
        
        let group = DispatchGroup()
        var summaries: [ClientProgressSummary] = []
        
        for clientId in clientIds {
            group.enter()
            
            // Fetch client basic info
            firestore.collection("users").document(clientId).getDocument { [weak self] document, error in
                defer { group.leave() }
                
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching client \(clientId): \(error)")
                    return
                }
                
                guard let document = document,
                      document.exists,
                      let data = document.data() else {
                    print("Client document \(clientId) not found")
                    return
                }
                
                let clientName = data["fullName"] as? String ?? "Unknown Client"
                let avatarURL = data["photoURL"] as? String
                
                // Fetch latest health data for this client
                self.firestore.collection("users")
                    .document(clientId)
                    .collection("healthData")
                    .order(by: "date", descending: true)
                    .limit(to: 1)
                    .getDocuments { healthSnapshot, healthError in
                        var latestHealthData: HealthData?
                        var lastUpdateDate: Date?
                        
                        if let healthDoc = healthSnapshot?.documents.first {
                            do {
                                latestHealthData = try healthDoc.data(as: HealthData.self)
                                lastUpdateDate = latestHealthData?.date.dateValue()
                            } catch {
                                print("Error decoding health data: \(error)")
                            }
                        }
                        
                        let summary = ClientProgressSummary(
                            clientId: clientId,
                            clientName: clientName,
                            clientAvatarURL: avatarURL,
                            latestHealthData: latestHealthData,
                            lastUpdateDate: lastUpdateDate
                        )
                        
                        summaries.append(summary)
                    }
            }
        }
        
        group.notify(queue: .main) {
            // Sort by last update date (most recent first)
            self.clientProgressSummaries = summaries.sorted { first, second in
                guard let firstDate = first.lastUpdateDate else { return false }
                guard let secondDate = second.lastUpdateDate else { return true }
                return firstDate > secondDate
            }
            self.isLoadingClients = false
        }
    }
    
    func cleanup() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
}

struct DashboardMetricCard: View {
    let icon: String
    let count: String
    let label: String
    let isLoading: Bool
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(accentColor)
            
            // Count
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: accentColor))
                    .scaleEffect(0.8)
            } else {
                Text(count)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.3), value: count)
            }
            
            // Label
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress bar with accent color
            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 4)
                .frame(maxWidth: .infinity)
                .cornerRadius(2)
                .overlay(
                    Rectangle()
                        .fill(accentColor)
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(2)
                        .opacity(isLoading ? 0 : 1)
                        .animation(.easeInOut(duration: 0.5), value: isLoading)
                )
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    accentColor.opacity(0.6),
                    lineWidth: 1.5
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.05), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                )
        )
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianDashboardView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif