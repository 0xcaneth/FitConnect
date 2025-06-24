import SwiftUI
import Foundation

@MainActor
class MealToastManager: ObservableObject {
    @Published var toasts: [MealToast] = []
    
    static let shared = MealToastManager()
    
    private init() {}
    
    func showToast(_ toast: MealToast) {
        toasts.append(toast)
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
            self.dismissToast(toast)
        }
    }
    
    func showSuccess(_ message: String, duration: Double = 3.0) {
        showToast(MealToast(message: message, type: .success, duration: duration))
    }
    
    func showError(_ message: String, duration: Double = 4.0) {
        showToast(MealToast(message: message, type: .error, duration: duration))
    }
    
    func showInfo(_ message: String, duration: Double = 3.0) {
        showToast(MealToast(message: message, type: .info, duration: duration))
    }
    
    func dismissToast(_ toast: MealToast) {
        withAnimation(.easeInOut(duration: 0.3)) {
            toasts.removeAll { $0.id == toast.id }
        }
    }
}

struct MealToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: MealToastType
    let duration: Double
    
    enum MealToastType {
        case success
        case error
        case info
        
        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .info:
                return FitConnectColors.accentBlue
            }
        }
        
        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
}

struct MealToastView: View {
    let toast: MealToast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FitConnectColors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FitConnectColors.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FitConnectColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(toast.type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

struct MealToastModifier: ViewModifier {
    @StateObject private var toastManager = MealToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                ForEach(toastManager.toasts) { toast in
                    MealToastView(toast: toast) {
                        toastManager.dismissToast(toast)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: toastManager.toasts)
                
                Spacer()
            }
            .padding(.top, 60) // Account for safe area
        }
    }
}

extension View {
    func withMealToasts() -> some View {
        self.modifier(MealToastModifier())
    }
}
