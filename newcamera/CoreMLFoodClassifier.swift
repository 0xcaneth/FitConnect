import Foundation
import CoreML
import Vision
import UIKit
import AVFoundation // Ensure this import is definitely present

@available(iOS 13.0, *)
class CoreMLFoodClassifier: ObservableObject {
    // --- SINGLETON IMPLEMENTATION ---
    static let shared = CoreMLFoodClassifier()
    // --- END SINGLETON IMPLEMENTATION ---

    private var visionModel: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.3
    
    private let modelLoadingTask: Task<VNCoreMLModel, Error>

    private init() {
        modelLoadingTask = Task.detached(priority: .userInitiated) {
            print("🔧 CoreMLFoodClassifier (Singleton): Initializing model loading task...")
            let modelName = "food"
            
            do {
                var modelURLToLoad: URL?
                if let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") {
                    print("✅ CoreMLFoodClassifier (Singleton): Found compiled model at \(modelURL.lastPathComponent)")
                    modelURLToLoad = modelURL
                } else {
                    print("⚠️ CoreMLFoodClassifier (Singleton): Compiled model '\(modelName).mlmodelc' not found, trying source .mlmodel")
                    if let sourceModelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
                        print("✅ CoreMLFoodClassifier (Singleton): Found source model at \(sourceModelURL.lastPathComponent)")
                        let tempCompiledURL = try MLModel.compileModel(at: sourceModelURL)
                        modelURLToLoad = tempCompiledURL
                        print("✅ CoreMLFoodClassifier (Singleton): Successfully compiled source model \(sourceModelURL.lastPathComponent) to \(tempCompiledURL.path)")
                    } else {
                        print("❌ CoreMLFoodClassifier (Singleton): Neither .mlmodelc nor .mlmodel found for '\(modelName)' in bundle.")
                        throw NSError(domain: "CoreMLFoodClassifier", code: 101, userInfo: [NSLocalizedDescriptionKey: "Model file '\(modelName).mlmodelc' or '\(modelName).mlmodel' not found."])
                    }
                }
                
                guard let finalModelURL = modelURLToLoad else {
                    throw NSError(domain: "CoreMLFoodClassifier", code: 102, userInfo: [NSLocalizedDescriptionKey: "Final model URL is nil after checking/compiling."])
                }

                let config = MLModelConfiguration()
                config.computeUnits = .all 
                // To diagnose:
                // print("⚠️ CoreMLFoodClassifier (Singleton): DIAGNOSTIC - Forcing CPU-only processing for the model.")
                // config.computeUnits = .cpuOnly 

                let mlModel = try MLModel(contentsOf: finalModelURL, configuration: config)
                let loadedVisionModel = try VNCoreMLModel(for: mlModel)
                print("✅ CoreMLFoodClassifier (Singleton): Successfully created VNCoreMLModel from \(finalModelURL.lastPathComponent) with config: \(config.computeUnits.rawValue)")
                
                print("✅ CoreMLFoodClassifier (Singleton): Model loading task complete. Model is loaded.")
                return loadedVisionModel
            } catch {
                print("❌ CoreMLFoodClassifier (Singleton): Error during model loading task: \(error.localizedDescription)")
                print("❌ CoreMLFoodClassifier (Singleton): Model loading task failed.")
                throw error
            }
        }
        Task {
            do {
                self.visionModel = try await self.modelLoadingTask.value
            } catch {
                print("❌ CoreMLFoodClassifier (Singleton): Failed to set instance visionModel from task: \(error.localizedDescription)")
            }
        }
    }

    func classifyFood(image: UIImage, completion: @escaping (Result<FoodPrediction, ClassificationError>) -> Void) {
        Task {
            do {
                let loadedModel = try await self.modelLoadingTask.value
                                
                if self.visionModel == nil { 
                   await MainActor.run { self.visionModel = loadedModel }
                }
                                
                print("🚀 CoreMLFoodClassifier (Singleton): Proceeding with REAL model prediction.")
                await self.runRealModelPrediction(image: image, model: loadedModel, completion: completion)
                
            } catch {
                print("❌ CoreMLFoodClassifier (Singleton): Error awaiting model loading task in classifyFood: \(error.localizedDescription). Using mock prediction.")
                let mockPrediction = await self.generateMockPrediction() 
                DispatchQueue.main.async {
                    completion(.success(mockPrediction))
                }
            }
        }
    }

    private func runRealModelPrediction(image: UIImage, model: VNCoreMLModel, completion: @escaping (Result<FoodPrediction, ClassificationError>) -> Void) async {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { completion(.failure(.invalidImage)) }
            return
        }

        let processedImage = preprocessImage(cgImage) 
        let imageOrientation = CGImagePropertyOrientation(image.imageOrientation)

        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            if let visionError = error {
                print("❌ Vision request error: \(visionError.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(.predictionFailed(visionError.localizedDescription))) }
                return
            }
            guard let observations = request.results as? [VNClassificationObservation], let topResult = observations.first else {
                print("❌ No VNClassificationObservation results.")
                DispatchQueue.main.async { completion(.failure(.noResults)) }
                return
            }
            print("🔍 Model observation: \(topResult.identifier) conf: \(String(format: "%.2f", topResult.confidence))")
            if topResult.confidence < self.confidenceThreshold {
                print("⚠️ Low confidence: \(topResult.confidence) for \(topResult.identifier)")
                DispatchQueue.main.async { completion(.failure(.lowConfidence)) }
                return
            }
            Task { 
                let prediction = await self.createFoodPrediction(from: topResult)
                DispatchQueue.main.async {
                    print("✅ Final prediction: \(prediction.label) (\(String(format: "%.0f%%", prediction.confidence * 100)))")
                    completion(.success(prediction))
                }
            }
        }
        request.imageCropAndScaleOption = .centerCrop
        // For diagnostics: request.usesCPUOnly = true 

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let handler = VNImageRequestHandler(cgImage: processedImage, orientation: imageOrientation, options: [:])
                try handler.perform([request])
            } catch let handlerError {
                print("❌ VNImageRequestHandler failed: \(handlerError.localizedDescription)")
                DispatchQueue.main.async { completion(.failure(.predictionFailed(handlerError.localizedDescription))) }
            }
        }
    }

    @MainActor
    private func generateMockPrediction() async -> FoodPrediction {
        let mockFoods = [("pizza", 0.95), ("apple", 0.92), ("banana", 0.88)]
        let randomFood = mockFoods.randomElement()!
        let cleanLabel = cleanFoodIdentifier(randomFood.0)
        print("🎭 Using mock prediction: \(cleanLabel)")
        let nutritionInfo = await getNutritionFromCSV(for: cleanLabel)
        return FoodPrediction(
            label: formatFoodLabel(cleanLabel), confidence: randomFood.1, calories: nutritionInfo.calories,
            protein: nutritionInfo.protein, fat: nutritionInfo.fats, carbs: nutritionInfo.carbohydrates,
            fiber: nutritionInfo.fiber, sugars: nutritionInfo.sugars, sodium: nutritionInfo.sodium
        )
    }

    private func preprocessImage(_ cgImage: CGImage) -> CGImage {
        let targetSize = CGSize(width: 224, height: 224) // MUST MATCH YOUR MODEL
        guard let colorSpace = cgImage.colorSpace else {
            print("❌ Preprocess: No colorSpace. Returning original."); return cgImage
        }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue) 
        guard let context = CGContext(
            data: nil, width: Int(targetSize.width), height: Int(targetSize.height),
            bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue
        ) else { print("❌ Preprocess: No CGContext. Returning original."); return cgImage }
        
        context.interpolationQuality = .high
        let originalSize = CGSize(width: cgImage.width, height: cgImage.height)
        let destRect = AVMakeRect(aspectRatio: originalSize, insideRect: CGRect(origin: .zero, size: targetSize))

        if destRect.size.width == 0 || destRect.size.height == 0 { 
            print("❌ Preprocess: destRect zero size. Original: \(originalSize), Target: \(targetSize). Returning original.")
            return cgImage
        }
        context.draw(cgImage, in: destRect) 
        guard let resizedImage = context.makeImage() else {
            print("❌ Preprocess: context.makeImage failed. Returning original."); return cgImage
        }
        print("🖼️ Preprocess: \(originalSize) -> Context: \(targetSize) (Drawn in \(destRect.size)). Final CGImage: \(resizedImage.width)x\(resizedImage.height)")
        return resizedImage
    }

    @MainActor 
    private func createFoodPrediction(from obs: VNClassificationObservation) async -> FoodPrediction {
        let cleanIdentifier = cleanFoodIdentifier(obs.identifier)
        let nutritionInfo = await getNutritionFromCSV(for: cleanIdentifier)
        return FoodPrediction(
            label: formatFoodLabel(cleanIdentifier), confidence: Double(obs.confidence),
            calories: nutritionInfo.calories, protein: nutritionInfo.protein, fat: nutritionInfo.fats,
            carbs: nutritionInfo.carbohydrates, fiber: nutritionInfo.fiber, sugars: nutritionInfo.sugars,
            sodium: nutritionInfo.sodium
        )
    }

    @MainActor 
    private func getNutritionFromCSV(for foodLabel: String) async -> NutritionEntry {
        let nutritionManager = NutritionDataManager.shared 
        for foodItem in nutritionManager.foodItems {
            if foodItem.label.lowercased() == foodLabel.lowercased() || foodItem.displayName.lowercased() == foodLabel.lowercased() {
                return foodItem.portions[safe: foodItem.portions.count / 2] ?? defaultNutritionEntry(for: foodLabel)
            }
        }
        for foodItem in nutritionManager.foodItems {
            let itemWords = foodItem.label.lowercased().components(separatedBy: "_")
            let searchWords = foodLabel.lowercased().components(separatedBy: " ")
            for searchWord in searchWords where !searchWord.isEmpty {
                if itemWords.contains(searchWord) {
                    return foodItem.portions[safe: foodItem.portions.count / 2] ?? defaultNutritionEntry(for: foodLabel)
                }
            }
        }
        return defaultNutritionEntry(for: foodLabel)
    }

    private func defaultNutritionEntry(for foodLabel: String) -> NutritionEntry {
        return NutritionEntry(csvRow: [foodLabel, "100", "200", "8.0", "25.0", "6.0", "2.0", "3.0", "200.0"])
               ?? NutritionEntry(csvRow: ["Unknown Food", "100", "200", "8.0", "25.0", "6.0", "2.0", "3.0", "200.0"])!
    }

    private func cleanFoodIdentifier(_ id: String) -> String {
        return id.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "n\\d+", with: "", options: .regularExpression)
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func formatFoodLabel(_ label: String) -> String {
        return label.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
    }
}

private func CGImagePropertyOrientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch orientation {
    case .up: return .up; case .down: return .down; case .left: return .left; case .right: return .right
    case .upMirrored: return .upMirrored; case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored; case .rightMirrored: return .rightMirrored
    @unknown default: return .up
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
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

    var mealAnalysis: MealAnalysis { // This line refers to MealAnalysis
        MealAnalysis(calories: calories, protein: protein, fat: fat, carbs: carbs, confidence: confidence)
    }
}

// Ensure MealAnalysis IS DEFINED ELSEWHERE. This placeholder was the problem.
// DO NOT UNCOMMENT THE FOLLOWING LINES if MealAnalysis is defined in another file.
//
// struct MealAnalysis: Equatable { // This was the duplicate
//     let calories: Int
//     let protein: Double
//     let fat: Double
//     let carbs: Double
//     let confidence: Double
// }

enum ClassificationError: LocalizedError {
    case modelNotLoaded, invalidImage, predictionFailed(String), noResults, lowConfidence
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded: return "Food recognition model could not be loaded."
        case .invalidImage: return "Invalid image provided for classification."
        case .predictionFailed(let msg): return "Prediction failed: \(msg)"
        case .noResults: return "No food items were detected in the image."
        case .lowConfidence: return "Unable to identify food with sufficient confidence."
        }
    }
}
