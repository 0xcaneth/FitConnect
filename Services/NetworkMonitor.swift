import Network
import SwiftUI

/// Production-ready network connectivity monitor
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true // Start optimistically
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    @Published var hasInitialized = false // Track if we've received first update
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType: String, CaseIterable {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet" 
        case unknown = "Unknown"
        
        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }
    }
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        // deinit cannot be async, so we call cancel directly on the monitor
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let wasConnected = self.isConnected
                let newIsConnected = path.status == .satisfied
                
                self.isConnected = newIsConnected
                self.isExpensive = path.isExpensive
                self.connectionType = self.getConnectionType(from: path)
                
                // Only log meaningful changes after initialization
                if self.hasInitialized {
                    if wasConnected != newIsConnected {
                        print("[NetworkMonitor] 📡 Connection changed: \(wasConnected ? "Connected" : "Disconnected") -> \(newIsConnected ? "Connected" : "Disconnected") via \(self.connectionType.rawValue)")
                    }
                } else {
                    print("[NetworkMonitor] 📡 Initial status: \(newIsConnected ? "Connected" : "Disconnected") via \(self.connectionType.rawValue)")
                    self.hasInitialized = true
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    /// Check if network is available for video streaming
    var canStreamVideos: Bool {
        guard isConnected else { return false }
        
        // Allow streaming on WiFi and non-expensive cellular
        switch connectionType {
        case .wifi, .ethernet:
            return true
        case .cellular:
            return !isExpensive
        case .unknown:
            return !isExpensive
        }
    }
    
    /// Get user-friendly connection status
    var connectionStatus: String {
        if !isConnected {
            return "No Internet Connection"
        }
        
        var status = "Connected via \(connectionType.rawValue)"
        if isExpensive {
            status += " (Limited)"
        }
        return status
    }
}

// MARK: - Network Alert Helper
extension NetworkMonitor {
    /// Show network-specific user guidance
    func getNetworkGuidance() -> NetworkGuidance {
        if !isConnected {
            return NetworkGuidance(
                title: "No Internet Connection",
                message: "Please check your internet connection and try again. Some features may not be available offline.",
                action: "Retry",
                severity: .error
            )
        }
        
        if !canStreamVideos {
            return NetworkGuidance(
                title: "Limited Connection",
                message: "You're on a limited data connection. Video streaming is disabled to save data.",
                action: "Continue",
                severity: .warning
            )
        }
        
        return NetworkGuidance(
            title: "Connected",
            message: "You're online via \(connectionType.rawValue)",
            action: nil,
            severity: .success
        )
    }
}

struct NetworkGuidance {
    let title: String
    let message: String
    let action: String?
    let severity: Severity
    
    enum Severity {
        case success, warning, error
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}