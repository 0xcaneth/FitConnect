import Foundation
import FirebaseFirestore

/// Service to generate random HealthKit data for testing purposes
@MainActor
class TestHealthDataGenerator {
    
    /// Generate random health data for the current day and previous 2 days (3 days total)
    static func generateRandomHealthData(for userId: String) async {
        let db = Firestore.firestore()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let calendar = Calendar.current
        
        // Generate data for 3 days: today, yesterday, day before yesterday
        for dayOffset in 0...2 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            print("[TestHealthDataGenerator] Generating data for: \(dateString)")
            
            // Generate random health data for this day
            let healthDataPoints = generateRandomHealthDataPoints(for: date)
            
            // Save each data point to Firestore
            for dataPoint in healthDataPoints {
                let docRef = db.collection("users")
                    .document(userId)
                    .collection("healthData")
                    .document(dateString)
                    .collection("healthkit")
                    .document(UUID().uuidString)
                
                do {
                    try await docRef.setData(dataPoint)
                    print("[TestHealthDataGenerator] Saved \(dataPoint["type"] ?? "unknown") data")
                } catch {
                    print("[TestHealthDataGenerator] Error saving data point: \(error)")
                }
            }
            
            // Generate random meal data for this day
            let mealDataPoints = generateRandomMealData(for: date)
            
            for mealData in mealDataPoints {
                let docRef = db.collection("users")
                    .document(userId)
                    .collection("healthData")
                    .document(dateString)
                    .collection("meals")
                    .document(UUID().uuidString)
                
                do {
                    try await docRef.setData(mealData)
                    print("[TestHealthDataGenerator] Saved meal data")
                } catch {
                    print("[TestHealthDataGenerator] Error saving meal data: \(error)")
                }
            }
        }
        
        print("[TestHealthDataGenerator] Completed generating 3 days of test data")
    }
    
    /// Generate random HealthKit data points for a specific day
    private static func generateRandomHealthDataPoints(for date: Date) -> [[String: Any]] {
        var dataPoints: [[String: Any]] = []
        let timestamp = Timestamp(date: date)
        
        // Steps (5000-15000 range)
        dataPoints.append([
            "type": "steps",
            "value": Double.random(in: 5000...15000),
            "unit": "count",
            "timestamp": timestamp,
            "date": date
        ])
        
        // Active Energy Burned (200-800 kcal range)
        dataPoints.append([
            "type": "activeEnergyBurned",
            "value": Double.random(in: 200...800),
            "unit": "kcal",
            "timestamp": timestamp,
            "date": date
        ])
        
        // Water Intake (1000-3000ml range)
        dataPoints.append([
            "type": "waterIntake",
            "value": Double.random(in: 1000...3000),
            "unit": "ml",
            "timestamp": timestamp,
            "date": date
        ])
        
        // Weight (50-100kg range) - not every day
        if Bool.random() {
            dataPoints.append([
                "type": "weight",
                "value": Double.random(in: 50...100),
                "unit": "kg",
                "timestamp": timestamp,
                "date": date
            ])
        }
        
        // Height (150-200cm range) - rarely changes
        if Bool.random() && Double.random(in: 0...1) < 0.1 {
            dataPoints.append([
                "type": "height",
                "value": Double.random(in: 150...200),
                "unit": "cm",
                "timestamp": timestamp,
                "date": date
            ])
        }
        
        // Body Fat Percentage (10-35% range) - not every day
        if Bool.random() {
            dataPoints.append([
                "type": "bodyFatPercentage",
                "value": Double.random(in: 10...35),
                "unit": "%",
                "timestamp": timestamp,
                "date": date
            ])
        }
        
        // Resting Heart Rate (50-90 bpm range)
        dataPoints.append([
            "type": "restingHeartRate",
            "value": Double.random(in: 50...90),
            "unit": "bpm",
            "timestamp": timestamp,
            "date": date
        ])
        
        // Blood Pressure - not every day
        if Bool.random() {
            dataPoints.append([
                "type": "bloodPressureSystolic",
                "value": Double.random(in: 110...140),
                "unit": "mmHg",
                "timestamp": timestamp,
                "date": date
            ])
            
            dataPoints.append([
                "type": "bloodPressureDiastolic",
                "value": Double.random(in: 70...90),
                "unit": "mmHg",
                "timestamp": timestamp,
                "date": date
            ])
        }
        
        // Sleep Hours (6-10 hours range)
        dataPoints.append([
            "type": "sleepHours",
            "value": Double.random(in: 6...10),
            "unit": "hr",
            "timestamp": timestamp,
            "date": date
        ])
        
        return dataPoints
    }
    
    /// Generate random meal data for a specific day
    private static func generateRandomMealData(for date: Date) -> [[String: Any]] {
        var mealData: [[String: Any]] = []
        let timestamp = Timestamp(date: date)
        
        // Generate 2-4 meals for the day
        let mealCount = Int.random(in: 2...4)
        
        for mealIndex in 0..<mealCount {
            let mealType = ["breakfast", "lunch", "dinner", "snack"][min(mealIndex, 3)]
            
            // Generate random nutrition values
            let calories = Int.random(in: 200...800)
            let protein = Double.random(in: 15...50)
            let fat = Double.random(in: 10...40)
            let carbs = Double.random(in: 20...80)
            let fiber = Double.random(in: 2...15)
            let sugars = Double.random(in: 5...30)
            let sodium = Double.random(in: 200...1500)
            
            let meal = [
                "name": "Test \(mealType.capitalized)",
                "mealType": mealType,
                "timestamp": timestamp,
                "date": date,
                "nutrition": [
                    "calories": calories,
                    "protein": protein,
                    "fat": fat,
                    "carbs": carbs,
                    "fiber": fiber,
                    "sugars": sugars,
                    "sodium": sodium
                ] as [String: Any]
            ] as [String: Any]
            
            mealData.append(meal)
        }
        
        return mealData
    }
}