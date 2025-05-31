import SwiftUI
import UIKit

/// A UIViewRepresentable wrapper for UIActivityIndicatorView,
/// ensuring compatibility with iOS 13.
struct ActivityIndicator: UIViewRepresentable {
    let style: UIActivityIndicatorView.Style
    let color: UIColor

    init(style: UIActivityIndicatorView.Style = .large, color: UIColor = .white) {
        self.style = style
        self.color = color
    }

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.color = color
        indicator.hidesWhenStopped = true // Default behavior
        indicator.startAnimating()
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        // No state changes to propagate from SwiftUI to UIKit in this simple version
    }
}

#if DEBUG
struct ActivityIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActivityIndicator(style: .large, color: .blue)
            ActivityIndicator(style: .medium, color: .red)
        }
        .padding()
        .background(Color.gray.opacity(0.3))
    }
}
#endif