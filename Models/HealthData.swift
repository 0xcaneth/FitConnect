import Foundation
import FirebaseFirestore

struct HealthData: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var date: Timestamp
    var weight: Double?
    var height: Double?
    var bmi: Double?
    var bodyFatPercentage: Double?
    var bloodPressureSystolic: Int?
    var bloodPressureDiastolic: Int?
    var restingHeartRate: Int?
    var steps: Int?
    var caloriesBurned: Double?
    var sleepHours: Double?
    var notes: String?
    var createdAt: Timestamp
    
    init(id: String? = nil, userId: String, date: Timestamp, weight: Double?, height: Double?, bodyFatPercentage: Double?, bloodPressureSystolic: Int?, bloodPressureDiastolic: Int?, restingHeartRate: Int?, notes: String?) {
        self.id = id
        self.userId = userId
        self.date = date
        self.weight = weight
        self.height = height
        self.bodyFatPercentage = bodyFatPercentage
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.restingHeartRate = restingHeartRate
        self.notes = notes
        self.createdAt = Timestamp(date: Date())
        // Set defaults for other properties
        self.bmi = nil
        self.steps = nil
        self.caloriesBurned = nil
        self.sleepHours = nil
    }

    init(userId: String, date: Date = Date(), weight: Double? = nil, height: Double? = nil, bmi: Double? = nil, bodyFatPercentage: Double? = nil, bloodPressureSystolic: Int? = nil, bloodPressureDiastolic: Int? = nil, restingHeartRate: Int? = nil, steps: Int? = nil, caloriesBurned: Double? = nil, sleepHours: Double? = nil, notes: String? = nil) {
        self.userId = userId
        self.date = Timestamp(date: date)
        self.weight = weight
        self.height = height
        self.bmi = bmi
        self.bodyFatPercentage = bodyFatPercentage
        self.bloodPressureSystolic = bloodPressureSystolic
        self.bloodPressureDiastolic = bloodPressureDiastolic
        self.restingHeartRate = restingHeartRate
        self.steps = steps
        self.caloriesBurned = caloriesBurned
        self.sleepHours = sleepHours
        self.notes = notes
        self.createdAt = Timestamp(date: Date())
    }
    
    // Computed BMI if height and weight are available
    var calculatedBMI: Double? {
        guard let weight = weight, let height = height, height > 0 else { return bmi }
        let heightInMeters = height / 100 // Convert cm to meters
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Helper for displaying weight with unit
    var weightDisplayString: String? {
        guard let weight = weight else { return nil }
        return String(format: "%.1f kg", weight)
    }
    
    // Helper for displaying BMI
    var bmiDisplayString: String? {
        let bmiValue = calculatedBMI ?? bmi
        guard let bmi = bmiValue else { return nil }
        return String(format: "BMI %.1f", bmi)
    }
    
    // Helper for displaying body fat percentage
    var bodyFatDisplayString: String? {
        guard let bodyFat = bodyFatPercentage else { return nil }
        return String(format: "%.1f%% body fat", bodyFat)
    }
}

// Client progress summary for dashboard
struct ClientProgressSummary: Identifiable {
    let id = UUID()
    let clientId: String
    let clientName: String
    let clientAvatarURL: String?
    let latestHealthData: HealthData?
    let lastUpdateDate: Date?
    
    var displayWeight: String {
        latestHealthData?.weightDisplayString ?? "No data"
    }
    
    var displaySecondaryMetric: String {
        if let bmi = latestHealthData?.bmiDisplayString {
            return bmi
        } else if let bodyFat = latestHealthData?.bodyFatDisplayString {
            return bodyFat
        } else {
            return "No data"
        }
    }
    
    var lastUpdateString: String {
        guard let date = lastUpdateDate else { return "No data" }
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedSame {
            return "Today"
        } else if calendar.dateInterval(of: .day, for: Date())?.start.timeIntervalSince(calendar.dateInterval(of: .day, for: date)?.start ?? date) == 86400 {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}
