import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var isPresenting: Bool
    let message: String
    let onDismiss: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                toast,
                alignment: .top
            )
    }
    
    private var toast: some View {
        VStack {
            if isPresenting {
                HStack {
                    Text(message)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresenting = false
                        }
                        onDismiss?()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if isPresenting {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresenting = false
                            }
                            onDismiss?()
                        }
                    }
                }
            }
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isPresenting)
    }
}

extension View {
    func toast(isPresenting: Binding<Bool>, message: String, onDismiss: (() -> Void)? = nil) -> some View {
        self.modifier(ToastModifier(isPresenting: isPresenting, message: message, onDismiss: onDismiss))
    }
}