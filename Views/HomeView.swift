// Views/HomeView.swift
import SwiftUI
import FirebaseCore        // FirebaseApp.configure() için
import FirebaseAuth        // Auth işlemleri için
import FirebaseFirestore   // Firestore’a erişim için
import FirebaseFirestoreSwift // Codable & @DocumentID, Timestamp için
import FirebaseAppCheck    // App Check kullanıyorsanızimport FirebaseAuth
import UIKit

struct HomeView: View {
  @Binding var selectedTab: Tab
  let userName: String
  let onLogout: () -> Void

  @State private var showProfileSheet = false
  @State private var showCamera = false

  var body: some View {
    VStack(spacing: 0) {
      header
      profileCard

      featureCards
      quickActions

      Spacer()

      // TabBar şimdi profile tıklayınca sheet açıyor
      TabBar(selectedTab: $selectedTab) { tab in
        if tab == .profile {
          showProfileSheet = true
        }
      }
    }
    .background(
      LinearGradient(
        gradient: Gradient(
          colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]
        ),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    )
    .sheet(isPresented: $showProfileSheet) {
      profileSheet
    }
    .sheet(isPresented: $showCamera) {
      CameraView()
    }
  }

  // MARK: Header
  private var header: some View {
    HStack {
      Text("Welcome, \(userName)! 👋")
        .font(.system(size: 28, weight: .bold))
        .foregroundColor(.white)
      Spacer()
    }
    .padding(.horizontal)
    .padding(.top, 16)
  }

  // MARK: Profile Card
  private var profileCard: some View {
    HStack {
      AvatarView(initials: String(userName.prefix(1)))
      VStack(alignment: .leading, spacing: 4) {
        Text(userName)
          .font(.title2).semibold()
          .foregroundColor(.white)
        Text("Level 3 • Consistent")
          .font(.subheadline)
          .foregroundColor(.white.opacity(0.8))
      }
      Spacer()
    }
    .padding()
    .background(Color.white.opacity(0.15))
    .cornerRadius(16)
    .padding(.horizontal)
    .padding(.top, 12)
  }

  // MARK: Feature Cards
  private var featureCards: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        FeatureCard(icon: "eye.fill", title: "Food Vision AI", subtitle: "Snap your meal")
        FeatureCard(icon: "chart.bar.fill", title: "Nutrition Stats", subtitle: "View your macros")
        FeatureCard(icon: "video.fill", title: "Workout Clips", subtitle: "Share workout video")
      }
      .padding(.horizontal)
    }
    .frame(height: 180)
    .padding(.top)
  }

  // MARK: Quick Actions
  private var quickActions: some View {
    HStack(spacing: 16) {
      QuickActionButton(icon: "fork.knife", title: "Log Meal") {}
      QuickActionButton(icon: "figure.walk", title: "Log Workout") {}
      QuickActionButton(icon: "camera", title: "Open Camera") {
        showCamera = true
      }
    }
    .padding(.horizontal)
    .padding(.top, 20)
  }

  // MARK: Profile Sheet
  private var profileSheet: some View {
    NavigationStack {
      VStack(spacing: 32) {
        Text("Profile").font(.title).bold()

        Button(role: .destructive) {
          do { try Auth.auth().signOut() }
          catch { print("Sign-out error:", error) }
          showProfileSheet = false
          onLogout()
        } label: {
          Text("Log Out")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }

        Spacer()
      }
      .padding()
      .navigationTitle("Profile")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") { showProfileSheet = false }
        }
      }
    }
  }
}

// Camera View
struct CameraView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: CameraView

    init(_ parent: CameraView) {
      self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      picker.dismiss(animated: true)
      // Handle the captured image here
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
    }
  }
}
