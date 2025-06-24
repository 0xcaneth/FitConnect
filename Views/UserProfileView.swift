import SwiftUI
import FirebaseFirestore

@available(iOS 16.0, *)
struct UserProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var userService: UserService
    
    let userId: String
    
    @State private var user: FitConnectUser?
    @State private var isLoading = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading profile...")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 100)
                } else if let user = user {
                    profileContent(user: user)
                } else {
                    Text("User not found")
                        .foregroundColor(.gray)
                        .padding(.top, 100)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#101218"), Color(hex: "#0B0D12")]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationTitle(user?.fullName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await loadProfile() }
        }
    }
    
    @ViewBuilder
    private func profileContent(user: FitConnectUser) -> some View {
        VStack(spacing: 24) {
            // Avatar and basic info
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: user.photoURL ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    default:
                        Circle()
                            .fill(Color(hex: "#6E56E9").opacity(0.3))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(String(user.fullName.prefix(1)).uppercased())
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Text(user.fullName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Member since \(user.createdAt, formatter: dateFormatter)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
            
            // Stats
            HStack(spacing: 0) {
                StatView(title: "XP", value: "\(user.xp ?? 0)")
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 40)
                
                StatView(title: "Level", value: "\(user.level ?? 1)") 
                
                Divider()
                    .background(Color.white.opacity(0.2))
                    .frame(height: 40)
                
                StatView(title: "Plan", value: user.subscription?.rawValue.capitalized ?? "Free")
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal)
            
            // User info
            VStack(alignment: .leading, spacing: 16) {
                Text("Profile Information")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    InfoRow(title: "Email", value: user.email)
                    
                    if let fitnessGoal = user.fitnessGoal, !fitnessGoal.isEmpty {
                        InfoRow(title: "Fitness Goal", value: fitnessGoal)
                    }
                    
                    if let activityLevel = user.activityLevel, !activityLevel.isEmpty {
                        InfoRow(title: "Activity Level", value: activityLevel)
                    }
                    
                    if let age = user.age {
                        InfoRow(title: "Age", value: "\(age) years old")
                    }
                    
                    if let weight = user.weight {
                        InfoRow(title: "Weight", value: String(format: "%.1f kg", weight))
                    }
                    
                    if let height = user.height {
                        InfoRow(title: "Height", value: String(format: "%.0f cm", height))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            
            Spacer(minLength: 50)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    @MainActor
    private func loadProfile() async {
        isLoading = true
        
        do {
            let loadedUser = try await userService.getUserProfile(userId: userId)
            user = loadedUser
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserProfileView(userId: "preview-user-id")
                .environmentObject(SessionStore.previewStore())
                .environmentObject(UserService.shared)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
