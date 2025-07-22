import Foundation
import FirebaseFirestore
import FirebaseCore

/// Script to fix existing Firebase workout templates
/// Fixes field naming inconsistencies and missing required fields
class FirebaseDataFixer {
    
    private let db = Firestore.firestore()
    
    /// Run the data fixing process
    func fixFirebaseData() async {
        print("🔧 [DataFixer] Starting Firebase data fixing process...")
        
        do {
            // Get all existing templates
            let snapshot = try await db.collection("workoutTemplates").getDocuments()
            
            print("📊 [DataFixer] Found \(snapshot.documents.count) documents to potentially fix")
            
            for document in snapshot.documents {
                await fixDocument(document)
            }
            
            print("✅ [DataFixer] Data fixing process completed!")
            
        } catch {
            print("❌ [DataFixer] Error during data fixing: \(error)")
        }
    }
    
    private func fixDocument(_ document: QueryDocumentSnapshot) async {
        let docId = document.documentID
        let data = document.data()
        var updatedData: [String: Any] = [:]
        var needsUpdate = false
        
        print("🔍 [DataFixer] Checking document: \(docId)")
        
        // Fix 1: Add missing searchKeywords
        if data["searchKeywords"] == nil {
            if let name = data["name"] as? String,
               let workoutTypeRaw = data["workoutType"] as? String,
               let targetMuscles = data["targetMuscleGroups"] as? [String] {
                
                let searchKeywords = generateSearchKeywords(
                    name: name,
                    workoutType: workoutTypeRaw,
                    muscleGroups: targetMuscles
                )
                updatedData["searchKeywords"] = searchKeywords
                needsUpdate = true
                print("  ✓ Adding searchKeywords: \(searchKeywords)")
            }
        }
        
        // Fix 2: Fix typo estimatedCalroies -> estimatedCalories
        if let caloriesWithTypo = data["estimatedCalroies"] as? Int,
           data["estimatedCalories"] == nil {
            updatedData["estimatedCalories"] = caloriesWithTypo
            updatedData["estimatedCalroies"] = FieldValue.delete() // Remove the typo field
            needsUpdate = true
            print("  ✓ Fixed typo: estimatedCalroies -> estimatedCalories (\(caloriesWithTypo))")
        }
        
        // Fix 3: Fix exercise -> exercises
        if let exerciseSingular = data["exercise"] as? [[String: Any]],
           data["exercises"] == nil {
            updatedData["exercises"] = exerciseSingular
            updatedData["exercise"] = FieldValue.delete() // Remove the incorrect field
            needsUpdate = true
            print("  ✓ Fixed field: exercise -> exercises (\(exerciseSingular.count) exercises)")
        }
        
        // Fix 4: Add missing estimatedDuration
        if data["estimatedDuration"] == nil {
            if let workoutTypeRaw = data["workoutType"] as? String {
                let duration = getDefaultDuration(for: workoutTypeRaw)
                updatedData["estimatedDuration"] = duration
                needsUpdate = true
                print("  ✓ Adding missing estimatedDuration: \(duration) seconds (\(Int(duration/60)) minutes)")
            }
        }
        
        // Fix 5: Add missing estimatedCalories if still not present
        if data["estimatedCalories"] == nil && data["estimatedCalroies"] == nil {
            if let workoutTypeRaw = data["workoutType"] as? String {
                let duration = (data["estimatedDuration"] as? TimeInterval) ?? getDefaultDuration(for: workoutTypeRaw)
                let calories = getDefaultCalories(for: workoutTypeRaw, duration: duration)
                updatedData["estimatedCalories"] = calories
                needsUpdate = true
                print("  ✓ Adding missing estimatedCalories: \(calories)")
            }
        }
        
        // Fix 6: Ensure isActive is boolean (some might be stored as number)
        if let isActiveNum = data["isActive"] as? Int {
            updatedData["isActive"] = isActiveNum == 1
            needsUpdate = true
            print("  ✓ Converting isActive from Int(\(isActiveNum)) to Bool(\(isActiveNum == 1))")
        }
        
        // Apply updates if needed
        if needsUpdate {
            do {
                try await db.collection("workoutTemplates").document(docId).updateData(updatedData)
                print("  ✅ Successfully updated document: \(docId)")
            } catch {
                print("  ❌ Failed to update document \(docId): \(error)")
            }
        } else {
            print("  ℹ️ No fixes needed for: \(docId)")
        }
    }
    
    private func generateSearchKeywords(name: String, workoutType: String, muscleGroups: [String]) -> [String] {
        var keywords = Set<String>()
        
        // Add name words
        name.lowercased().components(separatedBy: .whitespaces).forEach { word in
            if !word.isEmpty {
                keywords.insert(word)
            }
        }
        
        // Add workout type
        keywords.insert(workoutType.lowercased())
        
        // Add muscle groups
        muscleGroups.forEach { muscle in
            keywords.insert(muscle.lowercased())
        }
        
        return Array(keywords)
    }
    
    private func getDefaultDuration(for workoutType: String) -> TimeInterval {
        switch workoutType.lowercased() {
        case "hiit": return 20 * 60 // 20 minutes
        case "yoga": return 45 * 60 // 45 minutes  
        case "strength": return 60 * 60 // 60 minutes
        case "cardio": return 30 * 60 // 30 minutes
        case "pilates": return 40 * 60 // 40 minutes
        case "dance": return 35 * 60 // 35 minutes
        case "stretching": return 25 * 60 // 25 minutes
        case "running": return 45 * 60 // 45 minutes
        default: return 30 * 60 // Default 30 minutes
        }
    }
    
    private func getDefaultCalories(for workoutType: String, duration: TimeInterval) -> Int {
        let durationMinutes = Int(duration / 60)
        
        switch workoutType.lowercased() {
        case "hiit": return durationMinutes * 12
        case "cardio": return durationMinutes * 10
        case "strength": return durationMinutes * 8
        case "yoga": return durationMinutes * 4
        case "pilates": return durationMinutes * 6
        case "dance": return durationMinutes * 9
        case "stretching": return durationMinutes * 3
        case "running": return durationMinutes * 11
        default: return durationMinutes * 6 // Default
        }
    }
}

// MARK: - Usage Instructions
/*
 Bu script'i çalıştırmak için:
 
 1. Xcode'da bir test target'ı oluştur
 2. Aşağıdaki kod ile çağır:
 
 func testFixFirebaseData() async throws {
     let fixer = FirebaseDataFixer()
     await fixer.fixFirebaseData()
 }
 
 VEYA
 
 AppDelegate'de temporary olarak çağır:
 
 Task {
     let fixer = FirebaseDataFixer()
     await fixer.fixFirebaseData()
 }
*/