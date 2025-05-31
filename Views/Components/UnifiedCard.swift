import SwiftUI

/// A simple rounded-corner card with a subtle shadow that can wrap any content.
///
/// Usage:
/// ```swift
/// UnifiedCard {
///     VStack { … }
/// }
/// ```
struct UnifiedCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.9))
                    .shadow(color: Color.black.opacity(0.12),
                            radius: 8, x: 0, y: 4)
            )
    }
}