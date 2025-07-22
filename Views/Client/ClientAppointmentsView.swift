import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct ClientAppointmentsView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = ClientAppointmentsViewModel()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showingBookAppointment = false
    @State private var showingNetworkAlert = false
    @State private var showingWiFiGuide = false
    @State private var lastOfflineTime: Date?
    @State private var headerOffset: CGFloat = 0
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(
                    colors: [
                        FitConnectColors.backgroundDark,
                        Color.black.opacity(0.95),
                        Color.black
                    ],
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 600
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    modernHeader
                        .offset(y: headerOffset)
                    
                    networkStatusBanner
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: networkMonitor.isConnected)
                    
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingBookAppointment) {
                ClientBookAppointmentView()
                    .environmentObject(session)
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showingWiFiGuide) {
                UltraModernWiFiGuideModal()
            }
            .onAppear {
                loadAppointmentsIfPossible()
                withAnimation(.easeOut(duration: 1.0)) {
                    headerOffset = 0
                }
            }
            .onReceive(networkMonitor.$isConnected) { isConnected in
                handleNetworkChange(isConnected: isConnected)
            }
            .alert("Network Status", isPresented: $showingNetworkAlert) {
                Button("OK") { }
                Button("WiFi Guide") {
                    showingWiFiGuide = true
                }
            } message: {
                Text(networkMonitor.getNetworkGuidance().message)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
                if !networkMonitor.isConnected {
                    Button("Retry When Online") {
                        viewModel.clearError()
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
    
    private var modernHeader: some View {
        HStack(spacing: 0) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.2), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(AdvancedPressEffectStyle())
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("My Appointments")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                FitConnectColors.accentPurple.opacity(0.8),
                                FitConnectColors.accentBlue.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                
                if networkMonitor.hasInitialized {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(networkMonitor.isConnected ? Color.green : .orange)
                            .frame(width: 6, height: 6)
                        
                        Text(networkMonitor.isConnected ? networkMonitor.connectionType.rawValue : "Offline")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
            }
            
            Spacer()
            
            Button {
                if networkMonitor.isConnected {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showingBookAppointment = true
                    }
                } else {
                    showingNetworkAlert = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            networkMonitor.isConnected ?
                            LinearGradient(
                                colors: [
                                    FitConnectColors.accentPurple,
                                    FitConnectColors.accentBlue
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [.gray.opacity(0.6), .gray.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(
                            color: networkMonitor.isConnected ? 
                                FitConnectColors.accentPurple.opacity(0.4) : 
                                .clear,
                            radius: 12, x: 0, y: 6
                        )
                    
                    Image(systemName: networkMonitor.isConnected ? "plus" : "wifi.slash")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(AdvancedPressEffectStyle())
            .disabled(!networkMonitor.isConnected)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    @ViewBuilder
    private var networkStatusBanner: some View {
        if !networkMonitor.isConnected {
            premiumOfflineBanner
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
        } else if networkMonitor.isExpensive {
            premiumLimitedDataBanner
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
        }
    }
    
    private var premiumOfflineBanner: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.orange.opacity(0.4), lineWidth: 1)
                    )
                
                Image(systemName: "wifi.slash")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Internet Connection")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Showing cached appointments only")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            
            Spacer()
            
            Button("WiFi Guide") {
                showingWiFiGuide = true
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(.white.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .buttonStyle(AdvancedPressEffectStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.9), .orange.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.1))
        )
    }
    
    private var premiumLimitedDataBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(FitConnectColors.accentBlue)
            
            Text("Limited Data Connection")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(FitConnectColors.accentBlue.opacity(0.7))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    FitConnectColors.accentBlue.opacity(0.15),
                    FitConnectColors.accentBlue.opacity(0.08)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .overlay(
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.05))
        )
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            premiumLoadingView
        } else if !networkMonitor.isConnected && viewModel.appointments.isEmpty {
            premiumOfflineEmptyState
        } else if viewModel.appointments.isEmpty {
            premiumEmptyState
        } else {
            premiumAppointmentsList
        }
    }
    
    private var premiumLoadingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if networkMonitor.isConnected {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: 0.8)
                        .stroke(
                            LinearGradient(
                                colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: UUID())
                }
                
                Text("Loading appointments...")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.orange)
                    
                    Text("Connecting...")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Waiting for internet connection")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
    }
    
    private var premiumOfflineEmptyState: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange.opacity(0.2), .orange.opacity(0.05)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(.orange.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "icloud.slash")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Offline Mode")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("No cached appointments available.\nConnect to internet to view your appointments.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 16) {
                Button {
                    showingWiFiGuide = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "wifi")
                            .font(.system(size: 18, weight: .bold))
                        
                        Text("WiFi Connection Guide")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20)
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 15, x: 0, y: 8)
                }
                .buttonStyle(AdvancedPressEffectStyle())
                
                Button {
                    loadAppointmentsIfPossible()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Try Again")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(FitConnectColors.accentPurple)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(FitConnectColors.accentPurple.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(AdvancedPressEffectStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var premiumEmptyState: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                FitConnectColors.accentPurple.opacity(0.2),
                                FitConnectColors.accentPurple.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(FitConnectColors.accentPurple.opacity(0.3), lineWidth: 1)
                    )
                
                Image(systemName: "calendar")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            VStack(spacing: 16) {
                Text("No Appointments Yet")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Book your first appointment with your dietitian")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                if networkMonitor.isConnected {
                    showingBookAppointment = true
                } else {
                    showingNetworkAlert = true
                }
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: networkMonitor.isConnected ? "calendar.badge.plus" : "wifi.slash")
                        .font(.system(size: 18, weight: .bold))
                    
                    Text(networkMonitor.isConnected ? "Book Appointment" : "Connect to Internet")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    networkMonitor.isConnected ?
                    LinearGradient(
                        colors: [FitConnectColors.accentPurple, FitConnectColors.accentBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20)
                )
                .shadow(
                    color: networkMonitor.isConnected ?
                        FitConnectColors.accentPurple.opacity(0.4) :
                        .orange.opacity(0.4),
                    radius: 15, x: 0, y: 8
                )
            }
            .buttonStyle(AdvancedPressEffectStyle())
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    private var premiumAppointmentsList: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.upcomingAppointments) { appointment in
                    UltraModernAppointmentCard(
                        appointment: appointment,
                        viewModel: viewModel,
                        isOffline: !networkMonitor.isConnected
                    )
                    .padding(.horizontal, 28)
                }
                
                if !viewModel.pastAppointments.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Past Appointments")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white.opacity(0.8), .white.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Spacer()
                            
                            if !networkMonitor.isConnected && lastOfflineTime != nil {
                                Text("Cached")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(.orange.opacity(0.2))
                                            .overlay(
                                                Capsule()
                                                    .stroke(.orange.opacity(0.4), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 32)
                        
                        ForEach(viewModel.pastAppointments) { appointment in
                            UltraModernAppointmentCard(
                                appointment: appointment,
                                isPast: true,
                                viewModel: viewModel,
                                isOffline: !networkMonitor.isConnected
                            )
                            .padding(.horizontal, 28)
                        }
                    }
                }
            }
            .padding(.bottom, 120)
        }
        .refreshable {
            if networkMonitor.isConnected {
                loadAppointmentsIfPossible()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAppointmentsIfPossible() {
        if let clientId = session.currentUserId,
           let expertId = session.currentUser?.expertId, !expertId.isEmpty {
            print("[ClientAppointments] Loading appointments - clientId: \(clientId), expertId: \(expertId), isOnline: \(networkMonitor.isConnected)")
            viewModel.loadAppointments(
                clientId: clientId,
                dietitianId: expertId,
                isOffline: !networkMonitor.isConnected
            )
            viewModel.expertId = expertId
        } else {
            print("[ClientAppointments] Missing clientId or expertId - clientId: \(session.currentUserId ?? "nil"), expertId: \(session.currentUser?.expertId ?? "nil")")
        }
    }
    
    private func handleNetworkChange(isConnected: Bool) {
        if networkMonitor.hasInitialized {
            if isConnected {
                print("[ClientAppointments] Network connected - refreshing appointments")
                loadAppointmentsIfPossible()
                lastOfflineTime = nil
            } else {
                print("[ClientAppointments] Network disconnected - showing cached data")
                lastOfflineTime = Date()
            }
        }
    }
}

// MARK: - Advanced Button Style
struct AdvancedPressEffectStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Ultra-Modern Appointment Card
struct UltraModernAppointmentCard: View {
    let appointment: Appointment
    var isPast: Bool = false
    let viewModel: ClientAppointmentsViewModel
    var isOffline: Bool = false
    
    @State private var showingDetail = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(formatDate(appointment.startTime.dateValue()))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(appointment.timeRangeString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        if isOffline {
                            Image(systemName: "icloud.slash")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.orange)
                        }
                        
                        Text(appointment.status.displayName)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(appointment.status.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(appointment.status.color.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(appointment.status.color.opacity(0.4), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Text(appointment.durationString)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if !isPast && appointment.isUpcoming() {
                        Image(systemName: isOffline ? "exclamationmark.circle.fill" : "info.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isOffline ? .orange : FitConnectColors.accentBlue)
                    }
                }
            }
            
            if let notes = appointment.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(FitConnectColors.accentBlue.opacity(0.7))
                        
                        Text("Notes")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(notes)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(3)
                }
            }
            
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [FitConnectColors.accentBlue.opacity(0.3), FitConnectColors.accentBlue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(FitConnectColors.accentBlue.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "stethoscope")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FitConnectColors.accentBlue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Dietitian")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                    
                    if isOffline && !isPast && appointment.isUpcoming() {
                        Text("Actions unavailable offline")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.orange)
                            .italic()
                    } else {
                        Text("Tap to view details")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if !isPast && appointment.isUpcoming() && !isOffline {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            FitConnectColors.cardBackground.opacity(isPast ? 0.4 : 0.8),
                            FitConnectColors.cardBackground.opacity(isPast ? 0.2 : 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isOffline ?
                                .orange.opacity(0.5) :
                                .white.opacity(isPast ? 0.1 : 0.2),
                            lineWidth: isOffline ? 2 : 1
                        )
                )
        )
        .opacity(isPast ? 0.7 : (isOffline ? 0.85 : 1.0))
        .shadow(
            color: .black.opacity(isPast ? 0.1 : 0.2),
            radius: isPast ? 5 : 12,
            x: 0,
            y: isPast ? 2 : 6
        )
        .onTapGesture {
            if !isPast && appointment.isUpcoming() {
                if networkMonitor.isConnected {
                    showingDetail = true
                } else {
                    print("[ClientAppointments] Cannot show appointment detail - offline")
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            ClientAppointmentDetailModal(
                appointment: appointment,
                onCancel: {
                    if networkMonitor.isConnected {
                        viewModel.cancelAppointment(appointment)
                    }
                }
            )
        }
        .buttonStyle(AdvancedPressEffectStyle())
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

// MARK: - Ultra-Modern WiFi Guide Modal
struct UltraModernWiFiGuideModal: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 16)
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [FitConnectColors.accentBlue.opacity(0.3), .clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "wifi")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(FitConnectColors.accentBlue)
                    }
                    
                    Text("WiFi Connection Guide")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
                
                VStack(spacing: 24) {
                    UltraModernGuideStep(
                        number: 1,
                        title: "Open Settings",
                        description: "Go to your iPhone's Settings app",
                        icon: "gearshape.fill",
                        color: FitConnectColors.accentBlue
                    )
                    
                    UltraModernGuideStep(
                        number: 2,
                        title: "Select Wi-Fi",
                        description: "Tap on 'Wi-Fi' in the settings menu",
                        icon: "wifi",
                        color: FitConnectColors.accentPurple
                    )
                    
                    UltraModernGuideStep(
                        number: 3,
                        title: "Connect to Network",
                        description: "Choose your network and enter password",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("Open Settings")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [FitConnectColors.accentBlue, FitConnectColors.accentBlue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .shadow(color: FitConnectColors.accentBlue.opacity(0.4), radius: 15, x: 0, y: 8)
                    }
                    .buttonStyle(AdvancedPressEffectStyle())
                    
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .buttonStyle(AdvancedPressEffectStyle())
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(20)
        }
    }
}

struct UltraModernGuideStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("\(number)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(2)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color.opacity(0.7))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

class ClientAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var lastSyncTime: Date?
    @Published var isOfflineMode = false
    
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
    
    func loadAppointments(clientId: String, dietitianId: String, isOffline: Bool = false) {
        self.isOfflineMode = isOffline
        
        if isOffline {
            loadCachedAppointments(clientId: clientId)
            return
        }
        
        isLoading = true
        
        print("[ClientAppointments] Loading appointments for client: \(clientId), dietitian: \(dietitianId)")
        
        listener?.remove()
        
        listener = Firestore.firestore()
            .collection("dietitians")
            .document(dietitianId)
            .collection("appointments")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("[ClientAppointments] Error loading appointments: \(error)")
                        
                        if error.localizedDescription.contains("network") || 
                           error.localizedDescription.contains("offline") ||
                           error.localizedDescription.contains("unavailable") {
                            self?.loadCachedAppointments(clientId: clientId)
                            self?.showError("Using cached data - network unavailable")
                        } else {
                            self?.showError(error.localizedDescription)
                        }
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
                    
                    let filteredAppointments = allAppointments
                        .filter { $0.clientId == clientId }
                        .sorted { $0.startTime.dateValue() < $1.startTime.dateValue() }
                    
                    self?.appointments = filteredAppointments
                    self?.lastSyncTime = Date()
                    
                    self?.cacheAppointments(filteredAppointments, clientId: clientId)
                    
                    print("[ClientAppointments] Final filtered appointments count: \(filteredAppointments.count)")
                }
            }
    }
    
    private func loadCachedAppointments(clientId: String) {
        let key = "cached_appointments_\(clientId)"
        if let data = UserDefaults.standard.data(forKey: key),
           let cachedAppointments = try? JSONDecoder().decode([CachedAppointment].self, from: data) {
            
            self.appointments = cachedAppointments.map { cached in
                var appointment = cached.appointment
                appointment.id = cached.id
                return appointment
            }
            
            if let syncTime = UserDefaults.standard.object(forKey: "last_sync_\(clientId)") as? Date {
                self.lastSyncTime = syncTime
            }
            
            print("[ClientAppointments] Loaded \(appointments.count) cached appointments")
        } else {
            print("[ClientAppointments] No cached appointments found")
            self.appointments = []
        }
    }
    
    private func cacheAppointments(_ appointments: [Appointment], clientId: String) {
        let cachedAppointments = appointments.compactMap { appointment -> CachedAppointment? in
            guard let id = appointment.id else { return nil }
            return CachedAppointment(id: id, appointment: appointment)
        }
        
        if let data = try? JSONEncoder().encode(cachedAppointments) {
            UserDefaults.standard.set(data, forKey: "cached_appointments_\(clientId)")
            UserDefaults.standard.set(Date(), forKey: "last_sync_\(clientId)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        showError = false
        errorMessage = ""
    }
    
    deinit {
        listener?.remove()
    }
    
    func cancelAppointment(_ appointment: Appointment) {
        Task { @MainActor in
            if !NetworkMonitor.shared.isConnected {
                self.showError("Cannot cancel appointment while offline. Please connect to internet and try again.")
                return
            }
            
            guard let appointmentId = appointment.id, !self.expertId.isEmpty else { 
                print("[ClientAppointments] Cancel failed - appointmentId: \(appointment.id ?? "nil"), expertId: \(self.expertId)")
                self.showError("Unable to cancel appointment. Missing appointment information.")
                return 
            }
            
            print("[ClientAppointments] Attempting to cancel appointment \(appointmentId) for dietitian \(self.expertId)")
            
            do {
                try await AppointmentService.shared.updateAppointmentStatus(
                    dietitianId: self.expertId,
                    appointmentId: appointmentId,
                    status: .cancelled
                )
                
                print("[ClientAppointments] Successfully cancelled appointment \(appointmentId)")
                
            } catch {
                print("[ClientAppointments] Failed to cancel appointment: \(error)")
                
                var userMessage = "Failed to cancel appointment"
                if error.localizedDescription.contains("network") || 
                   error.localizedDescription.contains("offline") {
                    userMessage = "Cannot cancel appointment - please check your internet connection"
                } else {
                    userMessage = "Failed to cancel appointment: \(error.localizedDescription)"
                }
                
                self.showError(userMessage)
            }
        }
    }
}

// MARK: - Cache Model
private struct CachedAppointment: Codable {
    let id: String
    let appointment: Appointment
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