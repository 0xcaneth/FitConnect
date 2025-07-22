import Foundation
import FirebaseStorage

/// Production-ready Firebase Storage service for exercise videos with caching and prefetch
class ExerciseVideoService: ObservableObject {
    static let shared = ExerciseVideoService()
    
    private let storage = Storage.storage()
    private var exerciseCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.fitconnect.videocache", qos: .background)
    
    // Exercise name to Firebase Storage file mapping - PRODUCTION READY
    private let exerciseVideoMappings: [String: String] = [
        // STRENGTH TRAINING (4 videos)
        "barbell bench press": "Barbell_Bench_Press.mp4",
        "bench press": "Barbell_Bench_Press.mp4",
        "barbell squat": "Barbell_Squat.mp4", 
        "squat": "Barbell_Squat.mp4",
        "squats": "Barbell_Squat.mp4",
        "barbell deadlift": "Barbell_Deadlift.mp4",
        "deadlift": "Barbell_Deadlift.mp4",
        "deadlifts": "Barbell_Deadlift.mp4", 
        "barbell rows": "Barbell_Rows.mp4",
        "rows": "Barbell_Rows.mp4",
        "barbell row": "Barbell_Rows.mp4",
        
        // HIIT (4 videos)
        "battle ropes": "Battle_Ropes.mp4",
        "burpees": "Burpees.mp4",
        "jump squats": "Jump_Squats.mp4",
        "russian twists": "Russian_Twists.mp4",
        
        // CARDIO (3 videos)
        "high knees": "High_Knees.mp4",
        "jumping jacks": "Jumping_Jacks.mp4",
        "mountain climbers": "Mountain_Climbers.mp4",
        
        // YOGA (4 videos)
        "cat-cow": "Cat_Cow.mp4",
        "cat cow": "Cat_Cow.mp4",
        "cat cow stretch": "Cat_Cow.mp4",
        "child's pose": "Childs_Pose.mp4",
        "childs pose": "Childs_Pose.mp4",
        "single leg stretch": "Single_Leg_Stretch.mp4",
        "sun salutation": "Sun_Salutation.mp4",
        "sun salutation a": "Sun_Salutation.mp4",
        
        // STRETCHING (3 videos)
        "hamstring stretch": "Hamstring_Stretch.mp4",
        "hip flexor": "Hip_Flexor_Stretch.mp4",
        "hip flexor stretch": "Hip_Flexor_Stretch.mp4",
        "seated spinal": "Seated_Spinal.mp4",
        "seated spinal twist": "Seated_Spinal.mp4",
        
        // DANCE (3 videos)
        "salsa": "Salsa.mp4",
        "salsa basic": "Salsa.mp4",
        "hip hop": "Hip_Hop.mp4",
        "hip hop groove": "Hip_Hop.mp4",
        "zumba": "Zumba.mp4",
        "zumba fusion": "Zumba.mp4",
        
        // RUNNING (1 video)
        "interval running": "Interval_Running.mp4",
        
        // PILATES (1 video)
        "plank": "Plank.mp4",
        
        // Fallback
        "default": "Barbell_Bench_Press.mp4"
    ]
    
    private init() {
        loadCachedURLs()
    }
    
    /// Fetch exercise video URL from Firebase Storage with caching
    func fetchExerciseVideo(for exerciseName: String) async -> URL? {
        let normalizedName = normalizeExerciseName(exerciseName)
        
        // 🐛 DEBUG: Hip Flexor için özel debug
        if exerciseName.lowercased().contains("hip flexor") {
            print("🔍 [DEBUG] Hip Flexor Video Debug Started")
            print("🔍 [DEBUG] Original name: '\(exerciseName)'")
            print("🔍 [DEBUG] Normalized name: '\(normalizedName)'")
            
            let filename = getVideoFilename(for: normalizedName)
            print("🔍 [DEBUG] Mapped filename: '\(filename ?? "NIL")'")
            
            if let filename = filename {
                let storagePath = "exercises/\(filename)"
                print("🔍 [DEBUG] Full storage path: '\(storagePath)'")
                
                // Test Firebase Storage erişimi
                let storageRef = storage.reference().child(storagePath)
                print("🔍 [DEBUG] Storage reference created")
                
                do {
                    let downloadURL = try await storageRef.downloadURL()
                    print("🔍 [DEBUG] ✅ SUCCESS! Download URL: \(downloadURL)")
                    setCachedURL(downloadURL.absoluteString, for: normalizedName)
                    return downloadURL
                    
                } catch {
                    print("🔍 [DEBUG] ❌ FIREBASE ERROR: \(error)")
                    print("🔍 [DEBUG] Error type: \(type(of: error))")
                    if let storageError = error as NSError? {
                        print("🔍 [DEBUG] Error code: \(storageError.code)")
                        print("🔍 [DEBUG] Error domain: \(storageError.domain)")
                        print("🔍 [DEBUG] Error description: \(storageError.localizedDescription)")
                    }
                    return await getFallbackVideo()
                }
            } else {
                print("🔍 [DEBUG] ❌ NO FILENAME MAPPING FOUND")
                return await getFallbackVideo()
            }
        }
        
        // Normal flow for other exercises
        // Check cache first for instant response
        if let cachedURL = await getCachedURL(for: normalizedName) {
            return URL(string: cachedURL)
        }
        
        // Get Firebase Storage filename
        guard let filename = getVideoFilename(for: normalizedName) else {
            print("[VideoService] ⚠️ No video mapping for: \(exerciseName)")
            return await getFallbackVideo()
        }
        
        return await fetchVideoFromStorage(filename: filename, cacheKey: normalizedName)
    }
    
    /// Prefetch videos for better user experience
    func prefetchVideos(for exerciseNames: [String]) {
        Task.detached(priority: .background) {
            print("[VideoService] 🚀 Starting prefetch for \(exerciseNames.count) videos")
            
            for exerciseName in exerciseNames {
                let normalizedName = self.normalizeExerciseName(exerciseName)
                
                // Skip if already cached
                if await self.getCachedURL(for: normalizedName) != nil {
                    continue
                }
                
                // Prefetch video URL
                _ = await self.fetchExerciseVideo(for: exerciseName)
                
                // Small delay to avoid overwhelming Firebase
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            print("[VideoService] ✅ Prefetch completed")
        }
    }
    
    /// Check if exercise has a specific video mapping
    func hasSpecificVideo(for exerciseName: String) -> Bool {
        let normalizedName = normalizeExerciseName(exerciseName)
        return exerciseVideoMappings[normalizedName] != nil
    }
    
    /// Clear video cache
    func clearCache() {
        cacheQueue.async {
            self.exerciseCache.removeAll()
            UserDefaults.standard.removeObject(forKey: "ExerciseVideoCache")
            print("[VideoService] 🧹 Cache cleared")
        }
    }
    
    // MARK: - Private Methods
    
    private func normalizeExerciseName(_ name: String) -> String {
        return name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ")
    }
    
    private func getVideoFilename(for normalizedName: String) -> String? {
        return exerciseVideoMappings[normalizedName]
    }
    
    private func getCachedURL(for cacheKey: String) async -> String? {
        return await withUnsafeContinuation { continuation in
            cacheQueue.async {
                continuation.resume(returning: self.exerciseCache[cacheKey])
            }
        }
    }
    
    private func setCachedURL(_ url: String, for cacheKey: String) {
        cacheQueue.async {
            self.exerciseCache[cacheKey] = url
            self.saveCachedURLs()
        }
    }
    
    private func fetchVideoFromStorage(filename: String, cacheKey: String) async -> URL? {
        let storagePath = "exercises/\(filename)"
        
        do {
            let storageRef = storage.reference().child(storagePath)
            let downloadURL = try await storageRef.downloadURL()
            
            print("[VideoService] ✅ Fetched video: \(filename)")
            
            // Cache the URL for future use
            setCachedURL(downloadURL.absoluteString, for: cacheKey)
            
            return downloadURL
            
        } catch {
            print("[VideoService] ❌ Error fetching \(filename): \(error)")
            return await getFallbackVideo()
        }
    }
    
    private func getFallbackVideo() async -> URL? {
        do {
            let defaultFilename = exerciseVideoMappings["default"]!
            let defaultPath = "exercises/\(defaultFilename)"
            let defaultRef = storage.reference().child(defaultPath)
            let defaultURL = try await defaultRef.downloadURL()
            
            print("[VideoService] 🔄 Using fallback video: \(defaultFilename)")
            return defaultURL
            
        } catch {
            print("[VideoService] ❌ Even fallback failed: \(error)")
            // Return nil - let UI handle the no-video case gracefully
            return nil
        }
    }
    
    private func saveCachedURLs() {
        UserDefaults.standard.set(exerciseCache, forKey: "ExerciseVideoCache")
    }
    
    private func loadCachedURLs() {
        cacheQueue.async {
            if let cached = UserDefaults.standard.dictionary(forKey: "ExerciseVideoCache") as? [String: String] {
                self.exerciseCache = cached
                print("[VideoService] 📱 Loaded \(cached.count) cached videos")
            }
        }
    }
}

// MARK: - Cache Statistics (Debug)
extension ExerciseVideoService {
    var cacheSize: Int {
        return exerciseCache.count
    }
    
    var cachedExercises: [String] {
        return Array(exerciseCache.keys).sorted()
    }
}