import SwiftUI

/// A simple rounded-corner card with a subtle shadow that can wrap any content.
///
/// Usage:
/// ```swift
/// UnifiedCard {
///     VStack { … }
/// }
/// ```
/// This is now effectively an alias for GlassCard with default opacity.
/// Consider directly using GlassCard or making UnifiedCard a specific configuration of GlassCard.
struct UnifiedCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GlassCard { // Uses the GlassCard defined in FitConnectStyles
            content
        }
    }
}

struct UnifiedCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            EnhancedGradientBackground()
            UnifiedCard {
                Text("This is content inside a UnifiedCard, which now uses GlassCard styling.")
                    .foregroundColor(FitConnectColors.textPrimary)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
