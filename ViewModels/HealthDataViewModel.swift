import Foundation
import SwiftUI
import Combine
import UIKit
import Firebase

@MainActor
class HealthDataViewModel: ObservableObject {
    @Published var healthDataEntries: [HealthData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingAddEntry = false
    @Published var showingEditEntry = false
    @Published var healthKitAuthorized = false
    @Published var importingFromHealthKit = false
    
    // Form fields
    @Published var selectedDate = Date()
    @Published var weight = ""
    @Published var height = ""
    @Published var bodyFatPercentage = ""
    @Published var bloodPressureSystolic = ""
    @Published var bloodPressureDiastolic = ""
    @Published var restingHeartRate = ""
    @Published var notes = ""
    
    // Images
    @Published var selectedMealImages: [UIImage] = []
    @Published var selectedWorkoutImages: [UIImage] = []
    @Published var selectedProgressImages: [UIImage] = []
    
    private let sessionStore: SessionStore
    private let healthDataService = HealthDataService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentEditingEntry: HealthData?
    
    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        loadHealthData()
        checkHealthKitAuthorization()
    }
    
    func loadHealthData() {
        guard let userId = sessionStore.currentUser?.id else {
            error = "No user ID available"
            return
        }
        
        isLoading = true
        error = nil
        
        healthDataService.listenToHealthData(for: userId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.error = error.localizedDescription
                    }
                },
                receiveValue: { healthData in
                    self.healthDataEntries = healthData
                    self.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    func showAddEntry() {
        clearForm()
        showingAddEntry = true
    }
    
    func showEditEntry(_ entry: HealthData) {
        currentEditingEntry = entry
        populateForm(with: entry)
        showingEditEntry = true
    }
    
    func saveEntry() {
        guard let userId = sessionStore.currentUser?.id else {
            error = "No user ID available"
            return
        }
        
        let entry = HealthData(
            id: currentEditingEntry?.id,
            userId: userId,
            date: Timestamp(date: selectedDate),
            weight: weight.isEmpty ? nil : Double(weight),
            height: height.isEmpty ? nil : Double(height),
            bodyFatPercentage: bodyFatPercentage.isEmpty ? nil : Double(bodyFatPercentage),
            bloodPressureSystolic: bloodPressureSystolic.isEmpty ? nil : Int(bloodPressureSystolic),
            bloodPressureDiastolic: bloodPressureDiastolic.isEmpty ? nil : Int(bloodPressureDiastolic),
            restingHeartRate: restingHeartRate.isEmpty ? nil : Int(restingHeartRate),
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                if currentEditingEntry != nil {
                    try await healthDataService.updateHealthDataEntry(entry)
                } else {
                    try await healthDataService.createHealthDataEntry(entry)
                }
                await MainActor.run {
                    self.clearForm()
                    self.showingAddEntry = false
                    self.showingEditEntry = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func deleteEntry(_ entry: HealthData) {
        guard let entryId = entry.id else {
            error = "Invalid entry ID"
            return
        }
        
        Task {
            do {
                try await healthDataService.deleteHealthDataEntry(userId: entry.userId, entryId: entryId)
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    func requestHealthKitPermission() {
        healthKitAuthorized = true
    }
    
    func importFromHealthKit() {
        importingFromHealthKit = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.importingFromHealthKit = false
        }
    }
    
    func addMealImage(_ image: UIImage) {
        selectedMealImages.append(image)
    }
    
    func addWorkoutImage(_ image: UIImage) {
        selectedWorkoutImages.append(image)
    }
    
    func addProgressImage(_ image: UIImage) {
        selectedProgressImages.append(image)
    }
    
    func removeMealImage(_ index: Int) {
        selectedMealImages.remove(at: index)
    }
    
    func removeWorkoutImage(_ index: Int) {
        selectedWorkoutImages.remove(at: index)
    }
    
    func removeProgressImage(_ index: Int) {
        selectedProgressImages.remove(at: index)
    }
    
    func clearError() {
        error = nil
    }
    
    private func clearForm() {
        selectedDate = Date()
        weight = ""
        height = ""
        bodyFatPercentage = ""
        bloodPressureSystolic = ""
        bloodPressureDiastolic = ""
        restingHeartRate = ""
        notes = ""
        selectedMealImages = []
        selectedWorkoutImages = []
        selectedProgressImages = []
        currentEditingEntry = nil
    }
    
    private func populateForm(with entry: HealthData) {
        selectedDate = entry.date.dateValue()
        weight = entry.weight.map { String($0) } ?? ""
        height = entry.height.map { String($0) } ?? ""
        bodyFatPercentage = entry.bodyFatPercentage.map { String($0) } ?? ""
        bloodPressureSystolic = entry.bloodPressureSystolic.map { String($0) } ?? ""
        bloodPressureDiastolic = entry.bloodPressureDiastolic.map { String($0) } ?? ""
        restingHeartRate = entry.restingHeartRate.map { String($0) } ?? ""
        notes = entry.notes ?? ""
    }
    
    private func checkHealthKitAuthorization() {
        healthKitAuthorized = false
    }
}

extension HealthDataViewModel {
    static func preview() -> HealthDataViewModel {
        HealthDataViewModel(sessionStore: SessionStore.previewStore())
    }
}