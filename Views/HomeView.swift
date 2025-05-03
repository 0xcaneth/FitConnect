// Views/HomeView.swift
import SwiftUI
import FirebaseAuth

struct HomeView: View {
  @Binding var selectedTab: Tab
  let userName: String
  let onLogout:  () -> Void

  @State private var showProfile = false

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Welcome, \(userName)! 👋")
          .font(.title2).bold()
          .foregroundColor(.white)
        Spacer()
      }
      .padding()

      // Profile Card
      HStack {
        Circle()
          .fill(Color.white.opacity(0.3))
          .frame(width: 50, height: 50)
          .overlay(Text(userName.prefix(1)).font(.title).foregroundColor(.white))
        VStack(alignment: .leading) {
          Text(userName).foregroundColor(.white)
          Text("Level 3 • Consistent")
            .font(.caption).foregroundColor(.white.opacity(0.8))
        }
        Spacer()
      }
      .padding()
      .background(Color.white.opacity(0.1))
      .cornerRadius(12)
      .padding(.horizontal)

      // Feature Cards
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          FeatureCard(icon: "eye.fill",    title: "Food Vision AI",   subtitle: "Snap your meal")
          FeatureCard(icon: "chart.bar.fill", title: "Nutrition Stats", subtitle: "View your macros")
          FeatureCard(icon: "video.fill",  title: "Workout Clips",    subtitle: "Share workout video")
        }
        .padding(.horizontal)
      }
      .frame(height: 160)

      // Quick Actions
      HStack(spacing: 16) {
        QuickActionButton(icon: "fork.knife",    title: "Log Meal") {}
        QuickActionButton(icon: "figure.walk",    title: "Log Workout") {}
      }
      .padding()

      Spacer()

      // TabBar
      TabBar(selectedTab: $selectedTab) { tab in
        if tab == .profile { showProfile = true }
      }
    }
    .background(
      LinearGradient(
        colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    )
    .sheet(isPresented: $showProfile) {
      NavigationStack {
        VStack {
          Text("Profile")
            .font(.title).bold()
          Button("Log Out", role: .destructive) {
            onLogout()
          }
          .padding()
          .background(Color.red)
          .foregroundColor(.white)
          .cornerRadius(10)
          Spacer()
        }
        .padding()
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Close") { showProfile = false }
          }
        }
      }
    }
}
