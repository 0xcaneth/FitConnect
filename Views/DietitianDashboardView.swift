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
                    // Header
                    Text("Dashboard")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                    
                    // Metric Cards
                    HStack(spacing: 12) {
                        DashboardMetricCard(
                            icon: "person.3.fill",
                            count: "\(viewModel.activeClientsCount)",
                            label: "Active Clients"
                        )
                        
                        DashboardMetricCard(
                            icon: "calendar.badge.clock",
                            count: "\(viewModel.todayAppointmentsCount)",
                            label: "Appointments"
                        )
                        
                        DashboardMetricCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            count: "\(viewModel.unreadMessagesCount)",
                            label: "Messages"
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // Today's Appointments Panel
                    TodaysAppointmentsPanel(appointments: viewModel.todaysAppointments)
                        .padding(.horizontal, 16)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: showContent)
                    
                    // Client Progress Overview Panel
                    ClientProgressOverviewPanel(progressSummaries: viewModel.clientProgressSummaries)
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
    }
}

struct ClientProgressOverviewPanel: View {
    let progressSummaries: [ClientProgressSummary]
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
            if progressSummaries.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Text("No clients with progress data")
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
            Circle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 50, height: 50)
                .overlay(
                    Group {
                        if let avatarURL = summary.clientAvatarURL, !avatarURL.isEmpty {
                            AsyncImage(url: URL(string: avatarURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                )
            
            // Client Name
            Text(summary.clientName.components(separatedBy: " ").first ?? summary.clientName)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Weight and Date
            VStack(spacing: 2) {
                Text(summary.displayWeight)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                
                Text(summary.lastUpdateString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            // Secondary Metric (BMI or Body Fat)
            Text(summary.displaySecondaryMetric)
                .font(.system(size: 12, weight: .medium))
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
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Today's Appointments")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
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
            if appointments.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Text("No appointments scheduled for today")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Appointments List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appointments.sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }) { appointment in
                            DashboardAppointmentRowView(appointment: appointment)
                                .environmentObject(session)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: 300) // Responsive height limit
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
                // Client Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.clientName ?? "Unknown Client")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Status
                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor)
                
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
        case .scheduled, .completed:
            return .green
        case .cancelled, .noShow:
            return .orange
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .accepted:
            return .green
        case .rejected:
            return .red
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
    
    private var firestore = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let clientProgressService = ClientProgressService.shared
    
    func loadDashboardData(dietitianId: String) {
        loadTodaysAppointments(dietitianId: dietitianId)
        loadActiveClientsCount(dietitianId: dietitianId)
        loadUnreadMessagesCount(dietitianId: dietitianId)
        loadClientProgressSummaries(dietitianId: dietitianId)
    }
    
    private func loadClientProgressSummaries(dietitianId: String) {
        // For demo purposes, create sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let sampleSummaries = [
                ClientProgressSummary(
                    clientId: "client1",
                    clientName: "Anna Mills",
                    clientAvatarURL: nil,
                    latestHealthData: HealthData(
                        userId: "client1",
                        date: Date(),
                        weight: 68.5,
                        height: 165,
                        bmi: 25.2
                    ),
                    lastUpdateDate: Date()
                ),
                ClientProgressSummary(
                    clientId: "client2",
                    clientName: "Sarah Cooper",
                    clientAvatarURL: nil,
                    latestHealthData: HealthData(
                        userId: "client2",
                        date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                        weight: 72.1,
                        bodyFatPercentage: 24.8
                    ),
                    lastUpdateDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
                ),
                ClientProgressSummary(
                    clientId: "client3",
                    clientName: "Michael Zhang",
                    clientAvatarURL: nil,
                    latestHealthData: nil,
                    lastUpdateDate: nil
                )
            ]
            
            self.clientProgressSummaries = sampleSummaries
        }
    }
    
    private func loadTodaysAppointments(dietitianId: String) {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        // For demo purposes, create sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Create sample appointments for today
            var sampleAppointments: [Appointment] = []
            
            // Anna Mills appointment
            if let startTime = calendar.date(byAdding: .hour, value: 2, to: today),
               let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) {
                let appointment1 = Appointment(
                    clientId: "anna_mills",
                    startTime: startTime,
                    endTime: endTime,
                    notes: "Meal planning consultation",
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
                    notes: "Follow-up session",
                    status: .scheduled
                )
                var appointment2WithData = appointment2
                appointment2WithData.clientName = "Stephanie Cooper"
                sampleAppointments.append(appointment2WithData)
            }
            
            self.todaysAppointments = sampleAppointments
            self.todayAppointmentsCount = sampleAppointments.count
        }
    }
    
    private func loadActiveClientsCount(dietitianId: String) {
        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.activeClientsCount = 12
        }
    }
    
    private func loadUnreadMessagesCount(dietitianId: String) {
        // Mock data for demo
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.unreadMessagesCount = 3
        }
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
}

struct DashboardMetricCard: View {
    let icon: String
    let count: String
    let label: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
            
            // Count
            Text(count)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(.white)
            
            // Label
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress bar (empty state)
            Rectangle()
                .fill(Color(red: 0.25, green: 0.25, blue: 0.3))
                .frame(height: 4)
                .frame(maxWidth: .infinity)
                .cornerRadius(2)
        }
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    Color.purple.opacity(0.8),
                    lineWidth: 1.5
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
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