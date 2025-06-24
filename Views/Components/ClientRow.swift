import SwiftUI

struct DietitianClientRow: View {
    let client: DietitianClient
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: URL(string: client.photoURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#6E56E9"), Color(hex: "#8B7FF7")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(String(client.name.first?.uppercased() ?? "C"))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Client Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(client.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Online indicator
                    if client.lastOnline.isOnline {
                        Circle()
                            .fill(Color(hex: "#22C55E"))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(client.lastOnline.timeAgoString())
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(Color(hex: "#B0B3BA"))
            }
            
            Spacer()
            
            // Connection indicator
            VStack(spacing: 4) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#22C55E"))
                
                if let connectedAt = client.connectedAt {
                    Text("Since \(connectedAt, format: .dateTime.month().day())")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(Color(hex: "#8A8F9B"))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#1E1F25"))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#if DEBUG
struct DietitianClientRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            DietitianClientRow(client: DietitianClient(
                id: "1",
                name: "John Doe",
                photoURL: nil,
                email: "john@example.com",
                lastOnline: Date().addingTimeInterval(-300), // 5 minutes ago
                connectedAt: Date().addingTimeInterval(-86400) // 1 day ago
            ))
            
            DietitianClientRow(client: DietitianClient(
                id: "2",
                name: "Jane Smith",
                photoURL: nil,
                email: "jane@example.com",
                lastOnline: Date().addingTimeInterval(-3600), // 1 hour ago
                connectedAt: Date().addingTimeInterval(-604800) // 1 week ago
            ))
        }
        .padding()
        .background(Color(hex: "#0D0F14"))
        .preferredColorScheme(.dark)
    }
}
#endif