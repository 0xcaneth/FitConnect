import SwiftUI
import AVFoundation

struct ExpertPanelView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionStore
    @StateObject private var expertService = ExpertConnectionService.shared
    
    @State private var currentExpert: ExpertInfo?
    @State private var manualId: String = ""
    @State private var showingQRScanner = false
    @State private var showingCameraPermissionAlert = false
    @State private var isLoadingExpert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14"), Color(hex: "#1A1B25")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoadingExpert {
                    loadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if let expert = currentExpert {
                                // Connected to Expert State
                                connectedExpertView(expert: expert)
                            } else {
                                // Not Connected State
                                connectToExpertView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("My Expert")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "#6E56E9"))
            )
        }
        .onAppear {
            loadCurrentExpert()
        }
        .alert("Camera Permission Required", isPresented: $showingCameraPermissionAlert) {
            Button("Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to scan QR codes.")
        }
        .alert("Error", isPresented: $expertService.showingError) {
            Button("OK") {
                expertService.clearError()
            }
        } message: {
            if let errorMessage = expertService.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingQRScanner) {
            QRScannerSheetView { result in
                handleQRScanResult(result)
            }
        }
    }
    
    @ViewBuilder
    private func connectedExpertView(expert: ExpertInfo) -> some View {
        VStack(spacing: 24) {
            // Expert Card
            VStack(spacing: 16) {
                // Avatar
                AsyncImage(url: URL(string: expert.photoURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color(hex: "#6E56E9"))
                        .overlay(
                            Text(String(expert.name.first?.uppercased() ?? "E"))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                
                VStack(spacing: 8) {
                    Text(expert.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your Expert")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#6E56E9"))
                    
                    if let bio = expert.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color(hex: "#B0B3BA"))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "#1E1F25"))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            
            // Connection Status
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: "#22C55E"))
                    .frame(width: 12, height: 12)
                
                Text("Connected")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#22C55E"))
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#22C55E").opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#22C55E").opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Leave Service Button
            Button(action: {
                Task {
                    await leaveExpertService()
                }
            }) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Leave this expert's service")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(Color(hex: "#FF3B30"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#FF3B30").opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#FF3B30").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(expertService.isLoading)
            .opacity(expertService.isLoading ? 0.6 : 1.0)
        }
    }
    
    @ViewBuilder
    private func connectToExpertView() -> some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#6E56E9").opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(Color(hex: "#6E56E9"))
                }
                
                Text("Connect to an Expert")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Link with a dietitian to get personalized guidance and meal analysis.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 8)
            
            // QR Code Scanner Option
            Button(action: {
                requestCameraPermissionAndScan()
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#6E56E9").opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "#6E56E9"))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan QR Code")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Scan your expert's QR code to connect")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color(hex: "#B0B3BA"))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#6E56E9"))
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#1E1F25"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "#6E56E9").opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(expertService.isLoading)
            
            // OR Divider
            HStack {
                Rectangle()
                    .fill(Color(hex: "#2A2E3B"))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#8A8F9B"))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color(hex: "#2A2E3B"))
                    .frame(height: 1)
            }
            
            // Manual ID Entry
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Expert ID")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    TextField("Enter Expert ID", text: $manualId)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(hex: "#2A2E3B"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#6E56E9").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
                
                Button(action: {
                    Task {
                        await connectToExpert(expertId: manualId)
                    }
                }) {
                    HStack {
                        if expertService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(expertService.isLoading ? "Connecting..." : "Connect")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#6E56E9"), Color(hex: "#8B7FF7")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .disabled(manualId.isEmpty || expertService.isLoading)
                .opacity(manualId.isEmpty || expertService.isLoading ? 0.6 : 1.0)
            }
        }
    }
    
    @ViewBuilder
    private func loadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#6E56E9")))
                .scaleEffect(1.2)
            
            Text("Loading expert information...")
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadCurrentExpert() {
        guard let expertId = session.currentUser?.expertId, !expertId.isEmpty else {
            return
        }
        
        isLoadingExpert = true
        
        Task {
            do {
                let expert = try await expertService.fetchExpertInfo(expertId: expertId)
                
                DispatchQueue.main.async {
                    self.currentExpert = expert
                    self.isLoadingExpert = false
                }
                
            } catch {
                print("[ExpertPanelView] Error loading expert: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    self.isLoadingExpert = false
                }
            }
        }
    }
    
    private func requestCameraPermissionAndScan() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showingQRScanner = true
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingQRScanner = true
                    } else {
                        self.showingCameraPermissionAlert = true
                    }
                }
            }
            
        case .denied, .restricted:
            showingCameraPermissionAlert = true
            
        @unknown default:
            showingCameraPermissionAlert = true
        }
    }
    
    private func handleQRScanResult(_ result: Result<String, QRScannerError>) {
        showingQRScanner = false
        
        switch result {
        case .success(let scannedString):
            // Parse the scanned string as dietitian ID
            let expertId = scannedString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            Task {
                await connectToExpert(expertId: expertId)
            }
            
        case .failure(let error):
            expertService.errorMessage = error.localizedDescription
            expertService.showingError = true
        }
    }
    
    private func connectToExpert(expertId: String) async {
        guard !expertId.isEmpty else { return }
        
        do {
            try await expertService.linkExpert(dietitianId: expertId)
            
            // Refresh expert info
            let expert = try await expertService.fetchExpertInfo(expertId: expertId)
            
            DispatchQueue.main.async {
                self.currentExpert = expert
                self.manualId = ""
                
                // Update session with new expertId
                if var user = self.session.currentUser {
                    user.expertId = expertId
                    self.session.currentUser = user
                }
            }
            
        } catch {
            print("[ExpertPanelView] Error connecting to expert: \(error.localizedDescription)")
        }
    }
    
    private func leaveExpertService() async {
        do {
            try await expertService.leaveExpert()
            
            DispatchQueue.main.async {
                self.currentExpert = nil
                
                // Update session to remove expertId
                if var user = self.session.currentUser {
                    user.expertId = nil
                    self.session.currentUser = user
                }
            }
            
        } catch {
            print("[ExpertPanelView] Error leaving expert service: \(error.localizedDescription)")
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - QR Scanner Sheet

struct QRScannerSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let completion: (Result<String, QRScannerError>) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                QRScannerView { result in
                    completion(result)
                    dismiss()
                }
                
                // Overlay with scanning frame
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            VStack {
                                Spacer()
                                Text("Position QR code within the frame")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(8)
                            }
                            .padding(.bottom, 280)
                        )
                    
                    Spacer()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
}

#if DEBUG
struct ExpertPanelView_Previews: PreviewProvider {
    static var previews: some View {
        ExpertPanelView()
            .environmentObject(SessionStore.previewStore())
            .preferredColorScheme(.dark)
    }
}
#endif