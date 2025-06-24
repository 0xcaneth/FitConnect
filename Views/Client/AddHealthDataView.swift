import SwiftUI
import UIKit

class MockHealthDataViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var weight = ""
    @Published var height = ""
    @Published var bodyFatPercentage = ""
    @Published var bloodPressureSystolic = ""
    @Published var bloodPressureDiastolic = ""
    @Published var restingHeartRate = ""
    @Published var notes = ""
    @Published var selectedMealImages: [UIImage] = []
    @Published var selectedWorkoutImages: [UIImage] = []
    @Published var selectedProgressImages: [UIImage] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var healthKitAuthorized = false
    @Published var importingFromHealthKit = false
    
    func saveEntry() {}
    func clearError() {}
    func importFromHealthKit() {}
    func addMealImage(_ image: UIImage) { selectedMealImages.append(image) }
    func addWorkoutImage(_ image: UIImage) { selectedWorkoutImages.append(image) }
    func addProgressImage(_ image: UIImage) { selectedProgressImages.append(image) }
    func removeMealImage(_ index: Int) { selectedMealImages.remove(at: index) }
    func removeWorkoutImage(_ index: Int) { selectedWorkoutImages.remove(at: index) }
    func removeProgressImage(_ index: Int) { selectedProgressImages.remove(at: index) }
}

struct AddHealthDataView: View {
    @ObservedObject var viewModel: HealthDataViewModel
    let isEditing: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var imagePickerType: ImagePickerType = .meal
    
    init(viewModel: HealthDataViewModel, isEditing: Bool = false) {
        self.viewModel = viewModel
        self.isEditing = isEditing
    }
    
    var body: some View {
        NavigationView {
            Form {
                dateSection
                basicMetricsSection
                vitalsSection
                notesSection
                
                if viewModel.healthKitAuthorized {
                    healthKitSection
                }
                
                imagesSection
            }
            .navigationTitle(isEditing ? "Edit Entry" : "Add Health Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveEntry()
                        dismiss()
                    }
                    .disabled(viewModel.isLoading || !isFormValid)
                }
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
    
    private var isFormValid: Bool {
        return !viewModel.weight.isEmpty ||
               !viewModel.height.isEmpty ||
               !viewModel.bodyFatPercentage.isEmpty ||
               !viewModel.bloodPressureSystolic.isEmpty ||
               !viewModel.bloodPressureDiastolic.isEmpty ||
               !viewModel.restingHeartRate.isEmpty ||
               !viewModel.notes.isEmpty
    }
    
    private var dateSection: some View {
        Section("Date") {
            DatePicker("Entry Date", selection: $viewModel.selectedDate, displayedComponents: .date)
        }
    }
    
    private var basicMetricsSection: some View {
        Section("Basic Metrics") {
            HStack {
                Image(systemName: "scalemass")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                TextField("Weight (kg)", text: $viewModel.weight)
                    .keyboardType(.decimalPad)
            }
            
            HStack {
                Image(systemName: "ruler")
                    .foregroundColor(.green)
                    .frame(width: 20)
                TextField("Height (cm)", text: $viewModel.height)
                    .keyboardType(.decimalPad)
            }
            
            HStack {
                Image(systemName: "percent")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                TextField("Body Fat (%)", text: $viewModel.bodyFatPercentage)
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var vitalsSection: some View {
        Section("Vitals") {
            HStack {
                Image(systemName: "heart.circle")
                    .foregroundColor(.red)
                    .frame(width: 20)
                TextField("Systolic", text: $viewModel.bloodPressureSystolic)
                    .keyboardType(.numberPad)
                Text("/")
                TextField("Diastolic", text: $viewModel.bloodPressureDiastolic)
                    .keyboardType(.numberPad)
                Text("mmHg")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "heart")
                    .foregroundColor(.pink)
                    .frame(width: 20)
                TextField("Resting Heart Rate", text: $viewModel.restingHeartRate)
                    .keyboardType(.numberPad)
                Text("bpm")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField("Additional notes...", text: $viewModel.notes)
        }
    }
    
    private var healthKitSection: some View {
        Section("HealthKit") {
            Button(action: viewModel.importFromHealthKit) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Import from HealthKit")
                    Spacer()
                    if viewModel.importingFromHealthKit {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(viewModel.importingFromHealthKit)
        }
    }
    
    private var imagesSection: some View {
        Section("Photos") {
            imageSection(
                title: "Meal Photos",
                images: viewModel.selectedMealImages,
                addAction: { imagePickerType = ImagePickerType.meal; showingImagePicker = true },
                removeAction: viewModel.removeMealImage
            )
            
            imageSection(
                title: "Workout Photos",
                images: viewModel.selectedWorkoutImages,
                addAction: { imagePickerType = ImagePickerType.workout; showingImagePicker = true },
                removeAction: viewModel.removeWorkoutImage
            )
            
            imageSection(
                title: "Progress Photos",
                images: viewModel.selectedProgressImages,
                addAction: { imagePickerType = ImagePickerType.progress; showingImagePicker = true },
                removeAction: viewModel.removeProgressImage
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            HealthDataImagePicker(imagePickerType: imagePickerType) { image in
                switch imagePickerType {
                case .meal:
                    viewModel.addMealImage(image)
                case .workout:
                    viewModel.addWorkoutImage(image)
                case .progress:
                    viewModel.addProgressImage(image)
                }
            }
        }
    }
    
    private func imageSection(title: String, images: [UIImage], addAction: @escaping () -> Void, removeAction: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Button("Add Photo", action: addAction)
                    .font(.caption)
            }
            
            if !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button(action: { removeAction(index) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(.black.opacity(0.7)))
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
}

struct HealthDataImagePicker: UIViewControllerRepresentable {
    let imagePickerType: ImagePickerType
    let onImageSelected: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: HealthDataImagePicker
        
        init(_ parent: HealthDataImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

enum ImagePickerType {
    case meal, workout, progress
}

class HealthDataViewModel: ObservableObject {
    @Published var healthDataEntries: [HealthData] = []
    @Published var selectedDate = Date()
    @Published var weight = ""
    @Published var height = ""
    @Published var bodyFatPercentage = ""
    @Published var bloodPressureSystolic = ""
    @Published var bloodPressureDiastolic = ""
    @Published var restingHeartRate = ""
    @Published var notes = ""
    @Published var selectedMealImages: [UIImage] = []
    @Published var selectedWorkoutImages: [UIImage] = []
    @Published var selectedProgressImages: [UIImage] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var healthKitAuthorized = false
    @Published var importingFromHealthKit = false
    @Published var showingAddEntry = false
    @Published var showingEditEntry = false
    
    init(sessionStore: SessionStore) {}
    
    func saveEntry() {}
    func clearError() {}
    func importFromHealthKit() {}
    func addMealImage(_ image: UIImage) { selectedMealImages.append(image) }
    func addWorkoutImage(_ image: UIImage) { selectedWorkoutImages.append(image) }
    func addProgressImage(_ image: UIImage) { selectedProgressImages.append(image) }
    func removeMealImage(_ index: Int) { selectedMealImages.remove(at: index) }
    func removeWorkoutImage(_ index: Int) { selectedWorkoutImages.remove(at: index) }
    func removeProgressImage(_ index: Int) { selectedProgressImages.remove(at: index) }
    func showAddEntry() { showingAddEntry = true }
    func showEditEntry(_ entry: HealthData) { showingEditEntry = true }
    func deleteEntry(_ entry: HealthData) {}
    func requestHealthKitPermission() { healthKitAuthorized = true }
}

#Preview {
    AddHealthDataView(viewModel: HealthDataViewModel(sessionStore: SessionStore.previewStore()))
}
