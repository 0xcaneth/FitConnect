import Foundation
import CoreML
import Vision
import UIKit

@available(iOS 13.0, *)
class CoreMLFoodClassifier: ObservableObject {
    private var visionModel: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.3
    private var isLoading = false
    private var modelLoadingTask: Task<Void, Never>?

    init() {
        loadModel()
    }

    private func loadModel() {
        guard !isLoading else { return }
        isLoading = true

        modelLoadingTask = Task {
            let result = await ErrorBoundary.safely {
                let modelName = "food"

                do {
                    if let modelClass = NSClassFromString(modelName) as? NSObject.Type,
                       let modelInstance = modelClass.init() as? MLModel {
                        print("✅ Using auto-generated Core ML model class: \(modelName)")
                        let visionModel = try VNCoreMLModel(for: modelInstance)
                        return visionModel
                    }
                } catch {
                    print("⚠️ Auto-generated model class not available, falling back to file loading")
                }

                var modelURL: URL?

                let possibleNames = ["food", "food 2", "Food", "FoodClassifier"]
                for name in possibleNames {
                    modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodel")
                    if modelURL != nil {
                        break
                    }
                    modelURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc")
                    if modelURL != nil {
                        break
                    }
                }

                guard let finalModelURL = modelURL else {
                    print("❌ Could not find any food classification model in bundle")
                    throw NSError(domain: "CoreMLFoodClassifier", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not found in bundle"])
                }

                print("✅ Found Core ML model at: \(finalModelURL.lastPathComponent)")

                let mlModel = try MLModel(contentsOf: finalModelURL)
                let visionModel = try VNCoreMLModel(for: mlModel)

                return visionModel
            }

            await MainActor.run {
                if let visionModel = result {
                    self.visionModel = visionModel
                    print("✅ Core ML food classification model loaded successfully")
                } else {
                    print("❌ Failed to load Core ML model - will use mock predictions")
                }
                self.isLoading = false
            }
        }
    }

    func classifyFood(image: UIImage, completion: @escaping (Result<FoodPrediction, ClassificationError>) -> Void) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                completion(.failure(.invalidImage))
            }
            return
        }

        Task {
            await modelLoadingTask?.value

            guard let model = await MainActor.run(body: { self.visionModel }) else {
                print("⚠️ Model not loaded, using mock prediction")
                let mockPrediction = await self.generateMockPrediction()
                DispatchQueue.main.async {
                    completion(.success(mockPrediction))
                }
                return
            }

            await self.runRealModelPrediction(image: image, model: model, completion: completion)
        }
    }

    private func runRealModelPrediction(image: UIImage, model: VNCoreMLModel, completion: @escaping (Result<FoodPrediction, ClassificationError>) -> Void) async {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                completion(.failure(.invalidImage))
            }
            return
        }

        let processedImage = preprocessImage(cgImage)

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Vision request error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.predictionFailed(error.localizedDescription)))
                }
                return
            }

            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("❌ No classification results found")
                DispatchQueue.main.async {
                    completion(.failure(.noResults))
                }
                return
            }

            print("🔍 Model prediction: \(topResult.identifier) with confidence: \(String(format: "%.2f", topResult.confidence))")

            if topResult.confidence < self.confidenceThreshold {
                print("⚠️ Low confidence result: \(topResult.confidence)")
                DispatchQueue.main.async {
                    completion(.failure(.lowConfidence))
                }
                return
            }

            Task {
                let prediction = await self.createFoodPrediction(from: topResult)

                DispatchQueue.main.async {
                    print("✅ Final prediction: \(prediction.label) with \(String(format: "%.0f%%", prediction.confidence * 100)) confidence")
                    completion(.success(prediction))
                }
            }
        }

        request.imageCropAndScaleOption = .centerCrop

        await withCheckedContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: processedImage, orientation: .up, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                    continuation.resume()
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(.predictionFailed(error.localizedDescription)))
                    }
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func generateMockPrediction() async -> FoodPrediction {
        let mockFoods = [
            ("apple", 0.92),
            ("banana", 0.88),
            ("pizza", 0.85),
            ("hamburger", 0.79),
            ("salad", 0.73),
            ("pasta", 0.81),
            ("chicken_breast", 0.87),
            ("white_rice", 0.76),
            ("sandwich", 0.82),
            ("orange", 0.90)
        ]

        let randomFood = mockFoods.randomElement()!
        let cleanLabel = cleanFoodIdentifier(randomFood.0)

        print("🎭 Using mock prediction: \(cleanLabel)")

        let nutritionInfo = await getNutritionFromCSV(for: cleanLabel)

        return FoodPrediction(
            label: formatFoodLabel(cleanLabel),
            confidence: randomFood.1,
            calories: nutritionInfo.calories,
            protein: nutritionInfo.protein,
            fat: nutritionInfo.fats,
            carbs: nutritionInfo.carbohydrates,
            fiber: nutritionInfo.fiber,
            sugars: nutritionInfo.sugars,
            sodium: nutritionInfo.sodium
        )
    }

    private func preprocessImage(_ cgImage: CGImage) -> CGImage {
        let targetSize = CGSize(width: 224, height: 224)

        guard let colorSpace = cgImage.colorSpace else { return cgImage }

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return cgImage }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))

        return context.makeImage() ?? cgImage
    }

    @MainActor
    private func createFoodPrediction(from observation: VNClassificationObservation) async -> FoodPrediction {
        let cleanIdentifier = cleanFoodIdentifier(observation.identifier)

        print("🍕 Creating prediction for: \(cleanIdentifier) (original: \(observation.identifier))")

        let nutritionInfo = await getNutritionFromCSV(for: cleanIdentifier)

        return FoodPrediction(
            label: formatFoodLabel(cleanIdentifier),
            confidence: Double(observation.confidence),
            calories: nutritionInfo.calories,
            protein: nutritionInfo.protein,
            fat: nutritionInfo.fats,
            carbs: nutritionInfo.carbohydrates,
            fiber: nutritionInfo.fiber,
            sugars: nutritionInfo.sugars,
            sodium: nutritionInfo.sodium
        )
    }

    @MainActor
    private func getNutritionFromCSV(for foodLabel: String) async -> NutritionEntry {
        let nutritionManager = NutritionDataManager.shared

        print("🔍 Looking up nutrition for: '\(foodLabel)'")

        for foodItem in nutritionManager.foodItems {
            if foodItem.label.lowercased() == foodLabel.lowercased() ||
               foodItem.displayName.lowercased() == foodLabel.lowercased() {
                let middleIndex = min(2, max(0, foodItem.portions.count / 2))
                print("✅ Found exact match: \(foodItem.displayName)")
                return foodItem.portions[middleIndex]
            }
        }

        for foodItem in nutritionManager.foodItems {
            let itemWords = foodItem.label.lowercased().components(separatedBy: "_")
            let searchWords = foodLabel.lowercased().components(separatedBy: " ")

            for searchWord in searchWords {
                if itemWords.contains(searchWord) {
                    let middleIndex = min(2, max(0, foodItem.portions.count / 2))
                    print("✅ Found partial match: \(foodItem.displayName) for '\(searchWord)'")
                    return foodItem.portions[middleIndex]
                }
            }
        }

        print("⚠️ No nutrition match found for '\(foodLabel)', using default values")

        return createDefaultNutritionEntry(for: foodLabel)
    }

    private func createDefaultNutritionEntry(for foodLabel: String) -> NutritionEntry {
        let csvRow = [
            foodLabel,
            "100",
            "200",
            "8.0",
            "25.0",
            "6.0",
            "2.0",
            "3.0",
            "200.0"
        ]

        return NutritionEntry(csvRow: csvRow) ?? NutritionEntry(
            csvRow: ["Unknown Food", "100", "200", "8.0", "25.0", "6.0", "2.0", "3.0", "200.0"]
        )!
    }

    private func cleanFoodIdentifier(_ identifier: String) -> String {
        let cleaned = identifier
            .replacingOccurrences(of: "n\\d+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return cleaned
    }

    private func formatFoodLabel(_ label: String) -> String {
        return label
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

struct FoodPrediction: Equatable {
    let label: String
    let confidence: Double
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let fiber: Double
    let sugars: Double
    let sodium: Double

    var mealAnalysis: MealAnalysis {
        MealAnalysis(
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            confidence: confidence
        )
    }

    static func == (lhs: FoodPrediction, rhs: FoodPrediction) -> Bool {
        return lhs.label == rhs.label &&
               lhs.confidence == rhs.confidence &&
               lhs.calories == rhs.calories &&
               lhs.protein == rhs.protein &&
               lhs.fat == rhs.fat &&
               lhs.carbs == rhs.carbs
    }
}

enum ClassificationError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case predictionFailed(String)
    case noResults
    case lowConfidence

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Food recognition model is not loaded"
        case .invalidImage:
            return "Invalid image provided"
        case .predictionFailed(let message):
            return "Prediction failed: \(message)"
        case .noResults:
            return "No food items detected in image"
        case .lowConfidence:
            return "Unable to identify food with confidence"
        }
    }
}
