import Foundation

// MARK: - Nutrition Models
struct NutritionEntry: Codable, Hashable {
    let label: String
    let weight: Int
    let calories: Int
    let protein: Double
    let carbohydrates: Double
    let fats: Double
    let fiber: Double
    let sugars: Double
    let sodium: Double
    
    // Convert CSV row to NutritionEntry
    init?(csvRow: [String]) {
        guard csvRow.count >= 8,
              let weight = Int(csvRow[1]),
              let calories = Int(csvRow[2]),
              let protein = Double(csvRow[3]),
              let carbohydrates = Double(csvRow[4]),
              let fats = Double(csvRow[5]),
              let fiber = Double(csvRow[6]),
              let sugars = Double(csvRow[7]),
              let sodium = Double(csvRow[8]) else {
            return nil
        }
        
        self.label = csvRow[0].replacingOccurrences(of: "\"", with: "")
        self.weight = weight
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fats = fats
        self.fiber = fiber
        self.sugars = sugars
        self.sodium = sodium
    }
}

struct FoodItem: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let displayName: String
    let portions: [NutritionEntry]
    
    init(label: String, portions: [NutritionEntry]) {
        self.label = label
        self.displayName = label.replacingOccurrences(of: "_", with: " ").capitalized
        self.portions = portions.sorted { $0.weight < $1.weight }
    }
}

// MARK: - Nutrition Data Manager
@MainActor
class NutritionDataManager: ObservableObject {
    static let shared = NutritionDataManager()
    
    @Published var foodItems: [FoodItem] = []
    @Published var isLoading = true
    
    private var nutritionMap: [String: [NutritionEntry]] = [:]
    
    private init() {
        loadNutritionData()
    }
    
    private func loadNutritionData() {
        guard let path = Bundle.main.path(forResource: "nutrition", ofType: "csv"),
              let content = try? String(contentsOfFile: path) else {
            print("[NutritionDataManager] ❌ Could not load nutrition.csv")
            isLoading = false
            return
        }
        
        let lines = content.components(separatedBy: .newlines)
        var nutritionEntries: [NutritionEntry] = []
        
        // Skip header row
        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            
            let csvRow = parseCSVLine(line)
            if let entry = NutritionEntry(csvRow: csvRow) {
                nutritionEntries.append(entry)
            }
        }
        
        // Group by food label
        let grouped = Dictionary(grouping: nutritionEntries) { $0.label }
        nutritionMap = grouped
        
        // Create FoodItem objects
        foodItems = grouped.map { label, entries in
            FoodItem(label: label, portions: entries)
        }.sorted { $0.displayName < $1.displayName }
        
        isLoading = false
        print("[NutritionDataManager] ✅ Loaded \(foodItems.count) food items with \(nutritionEntries.count) total entries")
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        result.append(currentField) // Add the last field
        return result
    }
    
    func searchFoods(_ query: String) -> [FoodItem] {
        guard !query.isEmpty else { return foodItems }
        
        return foodItems.filter { food in
            food.displayName.localizedCaseInsensitiveContains(query) ||
            food.label.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getNutrition(for foodLabel: String, portionIndex: Int) -> NutritionEntry? {
        guard let portions = nutritionMap[foodLabel],
              portionIndex >= 0,
              portionIndex < portions.count else {
            return nil
        }
        
        return portions.sorted { $0.weight < $1.weight }[portionIndex]
    }
}