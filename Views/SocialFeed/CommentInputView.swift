import SwiftUI

@available(iOS 16.0, *)
struct CommentInputView: View {
    @Binding var text: String
    var isPosting: Bool = false
    var onSend: () -> Void
    var onTextChanged: ((String) -> Void)? = nil
    
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("", text: $text, axis: .vertical)
                    .placeholder(when: text.isEmpty) {
                        Text("Type a message…")
                            .foregroundColor(Color.gray.opacity(0.7))
                    }
                    .font(.custom("SFProText-Regular", size: 16))
                    .lineLimit(1...4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.clear)
                    .foregroundColor(isTextFieldFocused || !text.isEmpty ? .white : Color.gray.opacity(0.7))
                    .tint(Color.white.opacity(0.7)) 
                    .disabled(isPosting)
                    .focused($isTextFieldFocused)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onChange(of: text) { newValue in
                        onTextChanged?(newValue)
                    }
                    .onChange(of: isTextFieldFocused) { focused in
                        if !focused {
                           onTextChanged?("") // Send empty text to signify stopped typing
                        } else if focused && !text.isEmpty {
                            onTextChanged?(text) // Resend current text if refocused with content
                        }
                    }


                Button {
                    onSend()
                } label: {
                    if isPosting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "paperplane.fill") 
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                }
                .background(
                    Circle()
                        .fill(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting ?
                            AnyShapeStyle(Color.gray.opacity(0.4)) :
                            AnyShapeStyle(LinearGradient(
                                gradient: Gradient(colors: [Color(hex:"#6E56E9"), Color(hex:"#8A2BE2").opacity(0.8)]),
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                        )
                )
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
                .padding(.bottom, text.split(whereSeparator: \.isNewline).count > 1 ? 0 : 2) 
            }
            .padding(.horizontal, 12) 
            .padding(.vertical, 8)    
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#0D0F14").opacity(0.95), Color(hex: "#1A1D29").opacity(0.95)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22) 
                    .stroke(Color.white.opacity(0.15), lineWidth: 1) 
            )
            .clipShape(RoundedRectangle(cornerRadius: 22)) 
            .padding(.horizontal, 8) 
            .padding(.bottom, 8)     
            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: -3) 
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
