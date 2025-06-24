import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

@available(iOS 16.0, *)
struct DietitianProfileView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var viewModel = DietitianProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingEditProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#121212")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Avatar & Edit Button Section
                    VStack(spacing: 20) {
                        // Avatar with Camera Icon
                        ZStack {
                            // Main Avatar Circle
                            Button(action: { showingImagePicker = true }) {
                                AsyncImage(url: URL(string: viewModel.avatarURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.indigo],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            Text(viewModel.initials)
                                                .font(.system(size: 64, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.purple, Color.indigo],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 4
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                            }
                            .accessibilityLabel("Change profile photo")
                            
                            // Camera Edit Icon
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.black)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .offset(x: -10, y: -10)
                                }
                            }
                        }
                        .opacity(showContent ? 1.0 : 0.0)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .animation(.easeOut(duration: 0.6), value: showContent)
                        
                        // Edit Profile Button
                        Button(action: { showingEditProfile = true }) {
                            Text("Edit Profile")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.indigo],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(30)
                        }
                        .padding(.horizontal, 20)
                        .opacity(showContent ? 1.0 : 0.0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)
                    }
                    .padding(.top, 40)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        StatCard(
                            title: "Active Clients",
                            value: "\(viewModel.activeClientsCount)",
                            icon: "person.2.fill",
                            color: .purple,
                            index: 0,
                            showContent: showContent
                        )
                        
                        StatCard(
                            title: "Total Appointments",
                            value: "\(viewModel.totalAppointments)",
                            icon: "calendar.badge.clock",
                            color: .green,
                            index: 1,
                            showContent: showContent
                        )
                        
                        StatCard(
                            title: "Messages Today",
                            value: "\(viewModel.messagesToday)",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: .teal,
                            index: 2,
                            showContent: showContent
                        )
                        
                        StatCard(
                            title: "Avg Response",
                            value: viewModel.avgResponseTime,
                            icon: "clock.fill",
                            color: .orange,
                            index: 3,
                            showContent: showContent
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Settings List
                    VStack(spacing: 1) {
                        SettingsRow(
                            title: "Notifications",
                            icon: "bell.fill",
                            action: { /* Handle notifications settings */ }
                        )
                        
                        SettingsRow(
                            title: "Privacy & Security",
                            icon: "shield.fill",
                            action: { /* Handle privacy settings */ }
                        )
                        
                        SettingsRow(
                            title: "Help & Support",
                            icon: "questionmark.circle.fill",
                            action: { /* Handle help */ }
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
                    
                    // Sign Out Button
                    Button(action: signOut) {
                        HStack(spacing: 12) {
                            Image(systemName: "power")
                                .font(.system(size: 20, weight: .semibold))
                            Text("Sign Out")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color(hex: "#FF4C4C"))
                        .cornerRadius(30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showContent)
                }
            }
        }
        .onAppear {
            if let dietitianId = session.currentUserId {
                viewModel.loadProfile(dietitianId: dietitianId)
            }
            
            withAnimation {
                showContent = true
            }
        }
        .photosPicker(
            isPresented: $showingImagePicker,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.uploadAvatar(data)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(
                isPresented: $showingEditProfile,
                currentName: viewModel.name,
                currentBio: viewModel.bio ?? ""
            ) { name, bio in
                viewModel.updateProfile(name: name, bio: bio)
            }
        }
    }
    
    private func signOut() {
        do {
            try session.signOut()
        } catch {
            session.setGlobalError("Failed to sign out: \(error.localizedDescription)")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let index: Int
    let showContent: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(16)
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .opacity(showContent ? 1.0 : 0.0)
        .scaleEffect(showContent ? 1.0 : 0.8)
        .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1 + 0.4), value: showContent)
    }
}

struct SettingsRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(
                Color(hex: "#1E1E1E")
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {}
    }
}

struct EditProfileView: View {
    @Binding var isPresented: Bool
    @State private var name: String
    @State private var bio: String
    @State private var isUpdating = false
    
    let onSave: (String, String) -> Void
    
    init(isPresented: Binding<Bool>, currentName: String, currentBio: String, onSave: @escaping (String, String) -> Void) {
        self._isPresented = isPresented
        self._name = State(initialValue: currentName)
        self._bio = State(initialValue: currentBio)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#121212")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Full Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("Enter your full name", text: $name)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color(hex: "#1E1E1E"))
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bio")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextEditor(text: $bio)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(hex: "#1E1E1E"))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Button(action: save) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(isUpdating ? "Updating..." : "Save Changes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.indigo],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                    }
                    .disabled(name.isEmpty || isUpdating)
                    .opacity((name.isEmpty || isUpdating) ? 0.6 : 1.0)
                }
                .padding(24)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func save() {
        isUpdating = true
        onSave(name, bio)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isUpdating = false
            isPresented = false
        }
    }
}

class DietitianProfileViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var bio: String?
    @Published var avatarURL: String?
    @Published var activeClientsCount: Int = 0
    @Published var totalAppointments: Int = 0
    @Published var messagesToday: Int = 0
    @Published var avgResponseTime: String = "N/A"
    
    private var firestore = Firestore.firestore()
    private var storage = Storage.storage()
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    func loadProfile(dietitianId: String) {
        // Load basic profile info
        firestore.collection("users").document(dietitianId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self?.name = data["fullName"] as? String ?? ""
                    self?.email = data["email"] as? String ?? ""
                    self?.avatarURL = data["avatarURL"] as? String
                }
            }
        }
        
        // Load dietitian-specific info
        firestore.collection("dietitians").document(dietitianId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self?.bio = data["bio"] as? String
                }
            }
        }
        
        // Load statistics
        loadStatistics(dietitianId: dietitianId)
    }
    
    private func loadStatistics(dietitianId: String) {
        // Active clients count
        firestore.collection("clients")
            .whereField("assignedDietitianId", isEqualTo: dietitianId)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.activeClientsCount = snapshot?.documents.count ?? 0
                }
            }
        
        // Total appointments
        firestore.collection("dietitians")
            .document(dietitianId)
            .collection("schedule")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.totalAppointments = snapshot?.documents.count ?? 0
                }
            }
        
        // Messages today (simplified - would need more complex query in real app)
        let today = Calendar.current.startOfDay(for: Date())
        firestore.collection("chats")
            .whereField("participants", arrayContains: dietitianId)
            .whereField("lastMessageTimestamp", isGreaterThanOrEqualTo: Timestamp(date: today))
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.messagesToday = snapshot?.documents.count ?? 0
                }
            }
    }
    
    func updateProfile(name: String, bio: String) {
        guard let dietitianId = Auth.auth().currentUser?.uid else { return }
        
        // Update users collection
        firestore.collection("users").document(dietitianId).updateData([
            "fullName": name
        ])
        
        // Update dietitians collection
        firestore.collection("dietitians").document(dietitianId).updateData([
            "name": name,
            "bio": bio
        ]) { [weak self] error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.name = name
                    self?.bio = bio
                }
            }
        }
    }
    
    func uploadAvatar(_ imageData: Data) {
        guard let dietitianId = Auth.auth().currentUser?.uid else { return }
        
        let storageRef = storage.reference().child("dietitian_avatars/\(dietitianId).jpg")
        
        storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
            guard error == nil else {
                print("Error uploading avatar: \(error?.localizedDescription ?? "")")
                return
            }
            
            storageRef.downloadURL { [weak self] url, error in
                guard let downloadURL = url else { return }
                
                let avatarURL = downloadURL.absoluteString
                
                // Update both collections
                self?.firestore.collection("users").document(dietitianId).updateData([
                    "avatarURL": avatarURL
                ])
                
                self?.firestore.collection("dietitians").document(dietitianId).updateData([
                    "avatarURL": avatarURL
                ]) { error in
                    if error == nil {
                        DispatchQueue.main.async {
                            self?.avatarURL = avatarURL
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 16.0, *)
struct DietitianProfileView_Previews: PreviewProvider {
    static var previews: some View {
        DietitianProfileView()
            .environmentObject(SessionStore.previewStore(isLoggedIn: true, role: "dietitian"))
            .preferredColorScheme(.dark)
    }
}
#endif
