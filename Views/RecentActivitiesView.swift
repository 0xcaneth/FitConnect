import SwiftUI
import FirebaseAuth
import Combine

// MARK: - Recent Activities View
// Displays the 5 most recent meal entries in a card format matching the dark theme
@available(iOS 16.0, *)
struct RecentActivitiesView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = RecentActivitiesViewModel()
    @State private var showingAllActivities = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Content based on loading/error/data states
            contentView
        }
        .onAppear {
            viewModel.fetchRecentMeals()
        }
        .refreshable {
            viewModel.refresh()
        }
        .sheet(isPresented: $showingAllActivities) {
            // Placeholder for full activities screen
            AllActivitiesPlaceholderView()
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.hasRecentMeals {
                mealsListView
            } else {
                emptyStateView
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "8F3FFF")))
                .scaleEffect(1.2)
            
            Text("Loading recent activities...")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.red.opacity(0.8))
            
            Text("Error loading activities")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.red.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(3)
            
            Button("Try Again") {
                viewModel.clearError()
                viewModel.refresh()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "8F3FFF"))
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
        )
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8F3FFF").opacity(0.3),
                                Color(hex: "FF5C9C").opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "8F3FFF"))
            }
            
            VStack(spacing: 8) {
                Text("No recent activity yet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Log or scan your meals to see them here")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8F3FFF").opacity(0.3),
                                    Color(hex: "FF5C9C").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Meals List View
    private var mealsListView: some View {
        VStack(spacing: 8) {
            ForEach(viewModel.recentMeals) { meal in
                RecentMealRowView(meal: meal)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
}

// MARK: - Recent Meal Row View
// Individual row component for displaying a single meal entry
struct RecentMealRowView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Food emoji in a circular background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "8F3FFF").opacity(0.2),
                                Color(hex: "FF5C9C").opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Text(meal.foodEmoji)
                    .font(.system(size: 18))
            }
            
            // Center: Food name and portion information
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.displayText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(meal.nutrition.calories) kcal")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Right: Formatted time
            Text(meal.shortTimeString)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - All Activities Placeholder View
// Placeholder view for the "See All" functionality
struct AllActivitiesPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 64))
                    .foregroundColor(Color(hex: "8F3FFF"))
                
                VStack(spacing: 8) {
                    Text("All Activities")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Complete activity history coming soon!")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Constants.Colors.backgroundDark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "8F3FFF"))
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct RecentActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RecentActivitiesView()
                .padding()
        }
        .background(Color(hex: "0D0F14"))
        .preferredColorScheme(.dark)
    }
}
#endif