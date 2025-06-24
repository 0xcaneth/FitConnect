import SwiftUI

struct CheckboxRow: View {
    let text: String
    @Binding var isChecked: Bool
    var onTermsTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                isChecked.toggle()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#00E0FF") ?? .cyan,
                                    Color(hex: "#6A00FF") ?? .purple
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 2
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isChecked ? Color(hex: "#7C3AED") ?? .purple : Color(hex: "#1E1E1E") ?? .clear)
                        )
                        .frame(width: 20, height: 20)
                    
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            if let onTermsTap = onTermsTap {
                HStack(spacing: 4) {
                    Text("I agree to the ")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                    
                    Button("Terms & Conditions") {
                        onTermsTap()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(hex: "#7C3AED") ?? .purple)
                }
            } else {
                Text(text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CheckboxRow(text: "Regular checkbox", isChecked: .constant(false))
        CheckboxRow(text: "Checked checkbox", isChecked: .constant(true))
        CheckboxRow(text: "", isChecked: .constant(false)) { }
    }
    .padding()
    .background(Color.black)
}