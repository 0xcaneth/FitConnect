import SwiftUI

/// Generic background wrapper so all screens share a consistent base.
/// Expand later to use gradients, images, blur, etc.
struct UnifiedBackground<Content: View>: View {
    private let content: Content
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // iOS-13-compatible “fill the whole screen” modifier
            Group {
                if #available(iOS 14.0, *) {
                    AnyView(
                        Color(.systemBackground)
                            .ignoresSafeArea()
                    )
                } else {
                    AnyView(
                        Color(.systemBackground)
                            .edgesIgnoringSafeArea(.all)
                    )
                }
            }
            content
        }
    }
}

// MARK: – Convenience init for “just give me the background”
extension UnifiedBackground where Content == EmptyView {
    /// Allows `UnifiedBackground()` or simply `UnifiedBackground` in body code.
    init() {
        self.content = EmptyView()
    }
}
