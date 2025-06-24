import SwiftUI
import Firebase
import Combine
import UIKit

struct HealthLogsView: View {
    @StateObject private var viewModel: HealthDataViewModel
    @EnvironmentObject private var sessionStore: SessionStore
    
    init(sessionStore: SessionStore) {
        self._viewModel = StateObject(wrappedValue: HealthDataViewModel(sessionStore: sessionStore))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.healthDataEntries.isEmpty {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content
                }
            }
            .navigationTitle("Health Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.showAddEntry) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddEntry) {
                AddHealthDataView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingEditEntry) {
                AddHealthDataView(viewModel: viewModel, isEditing: true)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.error ?? "")
            }
        }
    }
    
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !viewModel.healthKitAuthorized {
                    healthKitPromptCard
                }
                
                if viewModel.healthDataEntries.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.healthDataEntries) { entry in
                        HealthDataCard(
                            entry: entry,
                            onEdit: { viewModel.showEditEntry(entry) },
                            onDelete: { viewModel.deleteEntry(entry) }
                        )
                    }
                }
            }
            .padding()
        }
        .refreshable {
            // Refresh is handled automatically by real-time listener
        }
    }
    
    private var healthKitPromptCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.title)
                .foregroundColor(.red)
            
            Text("Connect HealthKit")
                .font(.headline)
            
            Text("Import your health data automatically from the Health app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Enable HealthKit") {
                viewModel.requestHealthKitPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Health Data Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start tracking your health metrics by adding your first entry")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add First Entry") {
                viewModel.showAddEntry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

struct HealthDataCard: View {
    let entry: HealthData
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date
            HStack {
                VStack(alignment: .leading) {
                    Text(entry.date.dateValue(), style: .date)
                        .font(.headline)
                    Text(entry.date.dateValue(), style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: { showingDeleteAlert = true })
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                if let weight = entry.weight {
                    MetricView(title: "Weight", value: String(format: "%.1f kg", weight), icon: "scalemass")
                }
                
                if let bmi = entry.calculatedBMI {
                    MetricView(title: "BMI", value: String(format: "%.1f", bmi), icon: "person")
                }
                
                if let bodyFat = entry.bodyFatPercentage {
                    MetricView(title: "Body Fat", value: String(format: "%.1f%%", bodyFat), icon: "percent")
                }
                
                if let systolic = entry.bloodPressureSystolic, let diastolic = entry.bloodPressureDiastolic {
                    MetricView(title: "Blood Pressure", value: "\(systolic)/\(diastolic)", icon: "heart.circle")
                }
                
                if let heartRate = entry.restingHeartRate {
                    MetricView(title: "Resting HR", value: "\(heartRate) bpm", icon: "heart")
                }
                
                if let steps = entry.steps {
                    MetricView(title: "Steps", value: "\(steps)", icon: "figure.walk")
                }
            }
            
            // Notes
            if let notes = entry.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: onDelete)
        } message: {
            Text("Are you sure you want to delete this health data entry? This action cannot be undone.")
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

#Preview {
    HealthLogsView(sessionStore: SessionStore.previewStore())
        .environmentObject(SessionStore.previewStore())
}
