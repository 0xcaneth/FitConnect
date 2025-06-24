import SwiftUI

struct AuthSegmentedControl: View {
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    Text(option.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedOption == option ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedOption == option ? 
                            LinearGradient(
                                colors: [
                                    Color(hex: "#00E0FF") ?? .cyan,
                                    Color(hex: "#6A00FF") ?? .purple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) : 
                            LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color(hex: "#1E1E1E") ?? Color.black.opacity(0.3))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedOption)
    }
}

#Preview {
    AuthSegmentedControl(
        options: ["client", "dietitian"],
        selectedOption: .constant("client")
    )
    .padding()
    .background(Color.black)
}