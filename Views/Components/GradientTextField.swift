import SwiftUI

struct GradientTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var autocorrection: Bool = true
    
    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isPasswordVisible {
                    SecureField(placeholder, text: $text)
                        .textContentType(.password)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(!autocorrection)
                        .textContentType(keyboardType == .emailAddress ? .emailAddress : (isSecure ? .password : .none))
                }
            }
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white)
            .focused($isFocused)
            
            if isSecure {
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color(hex: "#1E1E1E") ?? Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#00E0FF") ?? .cyan,
                            Color(hex: "#6A00FF") ?? .purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: isFocused ? 2 : 1
                )
                .opacity(isFocused ? 1.0 : 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

#Preview {
    VStack(spacing: 20) {
        GradientTextField(placeholder: "Email Address", text: .constant(""), keyboardType: .emailAddress, autocapitalization: .never)
        GradientTextField(placeholder: "Password", text: .constant(""), isSecure: true)
    }
    .padding()
    .background(Color.black)
}