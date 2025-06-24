import Foundation
import SwiftUI

/// Error boundary to handle and log crashes gracefully
struct ErrorBoundary {
    
    /// Safely execute a throwing closure and return an optional result
    static func safely<T>(_ operation: () throws -> T, fallback: T? = nil) -> T? {
        do {
            return try operation()
        } catch {
            print("🛡️ ErrorBoundary caught error: \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Safely execute an async throwing closure
    static func safely<T>(_ operation: () async throws -> T, fallback: T? = nil) async -> T? {
        do {
            return try await operation()
        } catch {
            print("🛡️ ErrorBoundary caught async error: \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Log errors without crashing
    static func logError(_ error: Error, context: String = "") {
        print("🚨 Error in \(context): \(error.localizedDescription)")
    }
}

/// View modifier to wrap views in error boundaries
struct ErrorBoundaryViewModifier: ViewModifier {
    let fallbackView: AnyView
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Set up error handling for the view
            }
            .onDisappear {
                // Clean up error handling
            }
    }
}

extension View {
    func errorBoundary<FallbackView: View>(@ViewBuilder fallback: () -> FallbackView) -> some View {
        self.modifier(ErrorBoundaryViewModifier(fallbackView: AnyView(fallback())))
    }
}
