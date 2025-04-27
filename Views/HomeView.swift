// HomeView.swift
// FitConnect
// Created by ChatGPT on 4/26/25.

import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Tab = .home
    var userName: String = "Can"   // oturum açan kullanıcının adı buraya gelsin

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header + Profile Card
            header
            profileCard

            // MARK: Feature Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    FeatureCard(icon: "eye.fill",
                                title: "Food Vision AI",
                                subtitle: "Snap your meal")
                    FeatureCard(icon: "chart.bar.fill",
                                title: "Nutrition Stats",
                                subtitle: "View your macros")
                    FeatureCard(icon: "video.fill",
                                title: "Workout Clips",
                                subtitle: "Upload video")
                }
                .padding(.horizontal)
            }
            .frame(height: 180)
            .padding(.top)

            // MARK: Quick Actions
            HStack(spacing: 16) {
                QuickActionButton(icon: "fork.knife",
                                  title: "Log Meal",
                                  action: { /* log meal action */ })
                QuickActionButton(icon: "figure.walk",
                                  title: "Log Workout",
                                  action: { /* log workout action */ })
            }
            .padding(.horizontal)
            .padding(.top, 20)

            Spacer()

            // MARK: Tab Bar
            TabBar(selectedTab: $selectedTab)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color("PrimaryGradientStart"), Color("PrimaryGradientEnd")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    // header view
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

    // profile card view
    private var profileCard: some View {
        HStack {
            AvatarView(initials: String(userName.prefix(1)))
            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.semibold)
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
}

// ——— Subviews ——— //

struct AvatarView: View {
    let initials: String
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.2)]),
                    startPoint: .top,
                    endPoint: .bottom))
                .frame(width: 60, height: 60)
            Text(initials)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
        }
        .padding()
        .frame(width: 140, height: 160)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
    }
}

enum Tab { case home, stats, messages, profile }

struct TabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            tabButton(.home,    icon: "house.fill")
            Spacer()
            tabButton(.stats,   icon: "chart.pie.fill")
            Spacer()
            tabButton(.messages,icon: "bubble.left.and.bubble.right.fill")
            Spacer()
            tabButton(.profile, icon: "person.fill")
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.15))
        .cornerRadius(30)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func tabButton(_ tab: Tab, icon: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.7))
        }
    }
}

// ——— Preview ——— //

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
