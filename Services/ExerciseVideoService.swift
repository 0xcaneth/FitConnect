import Foundation
import FirebaseStorage

/// Production-ready Firebase Storage service for exercise videos with caching and prefetch
class ExerciseVideoService: ObservableObject {
    static let shared = ExerciseVideoService()
    
    private let storage = Storage.storage()
    private var exerciseCache: [String: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.fitconnect.videocache", qos: .background)
    
    // CRITICAL: Ultra-fast timeout for better UX
    private let fastTimeout: TimeInterval = 3.0  // 3 seconds MAX
    private let ultraFastTimeout: TimeInterval = 1.5  // 1.5 seconds for cached lookups
    
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
        
        // CRITICAL: Pre-load most common videos immediately
        Task {
            await preloadCriticalVideos()
        }
    }
    
    /// CRITICAL: Pre-load most commonly used videos for instant access
    private func preloadCriticalVideos() async {
        let criticalVideos = [
            "mountain climbers",
            "jumping jacks", 
            "high knees",
            "burpees",
            "plank",
            "squats"
        ]
        
        print("[VideoService] 🚀 Pre-loading critical videos for instant access")
        
        for exerciseName in criticalVideos {
            // Load in background - don't block UI
            Task.detached(priority: .background) {
                _ = await self.fetchExerciseVideoFast(for: exerciseName)
            }
        }
    }
    
    /// ULTRA-FAST video fetch with aggressive timeout and immediate fallback
    func fetchExerciseVideo(for exerciseName: String) async throws -> URL {
        print("[VideoService] 🎯 FETCH STARTED for: \(exerciseName)")
        let startTime = Date()
        
        do {
            let result = try await fetchExerciseVideoWithTimeout(for: exerciseName, timeout: fastTimeout)
            let duration = Date().timeIntervalSince(startTime)
            print("[VideoService] ✅ SUCCESS in \(String(format: "%.2f", duration))s for: \(exerciseName)")
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            print("[VideoService] ❌ FAILED in \(String(format: "%.2f", duration))s for: \(exerciseName) - Error: \(error)")
            
            // CRITICAL: Try fallback immediately
            return try await getFallbackVideoOrThrow()
        }
    }
    
    /// Get fallback video or throw error
    private func getFallbackVideoOrThrow() async throws -> URL {
        print("[VideoService] 🔄 Attempting fallback video...")
        
        do {
            let defaultFilename = exerciseVideoMappings["default"]!
            let defaultPath = "exercises/\(defaultFilename)"
            let defaultRef = storage.reference().child(defaultPath)
            let defaultURL = try await defaultRef.downloadURL()
            
            print("[VideoService] ✅ Fallback success: \(defaultFilename)")
            return defaultURL
            
        } catch {
            print("[VideoService] ❌ Even fallback failed: \(error)")
            throw VideoServiceError.networkError
        }
    }
    
    /// FASTEST possible video fetch - used for critical path
    private func fetchExerciseVideoFast(for exerciseName: String) async -> URL? {
        do {
            return try await fetchExerciseVideoWithTimeout(for: exerciseName, timeout: ultraFastTimeout)
        } catch {
            print("[VideoService] ⚡ Ultra-fast fetch failed for \(exerciseName): \(error)")
            return nil
        }
    }
    
    /// Core video fetch with configurable timeout
    private func fetchExerciseVideoWithTimeout(for exerciseName: String, timeout: TimeInterval) async throws -> URL {
        let normalizedName = normalizeExerciseName(exerciseName)
        print("[VideoService] 🔍 Normalized '\(exerciseName)' to '\(normalizedName)'")
        
        return try await withThrowingTaskGroup(of: URL.self) { group in
            // Task 1: Try to get video (with timeout)
            group.addTask {
                return try await self.fetchVideoCore(for: normalizedName, exerciseName: exerciseName)
            }
            
            // Task 2: Timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                print("[VideoService] ⏰ TIMEOUT after \(timeout)s for: \(exerciseName)")
                throw VideoServiceError.timeout
            }
            
            // Return first result (either success or timeout)
            guard let result = try await group.next() else {
                throw VideoServiceError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// Core video fetching logic
    private func fetchVideoCore(for normalizedName: String, exerciseName: String) async throws -> URL {
        print("[VideoService] 🔍 Core fetch for: \(normalizedName)")
        
        // Step 1: Check cache (instant)
        if let cachedURL = await getCachedURL(for: normalizedName) {
            print("[VideoService] ⚡ Cache HIT for: \(exerciseName)")
            return URL(string: cachedURL)!
        } else {
            print("[VideoService] 💾 Cache MISS for: \(exerciseName)")
        }
        
        // Step 2: Get Firebase Storage filename
        guard let filename = getVideoFilename(for: normalizedName) else {
            print("[VideoService] ❌ NO MAPPING for: '\(normalizedName)' from '\(exerciseName)'")
            print("[VideoService] 🗺️ Available mappings: \(Array(exerciseVideoMappings.keys).prefix(5))")
            throw VideoServiceError.notFound
        }
        
        print("[VideoService] 📁 Found mapping: '\(normalizedName)' -> '\(filename)'")
        
        // Step 3: Fetch from Firebase Storage
        return try await fetchVideoFromStorageFast(filename: filename, cacheKey: normalizedName)
    }
    
    /// Fast Firebase Storage fetch
    private func fetchVideoFromStorageFast(filename: String, cacheKey: String) async throws -> URL {
        let storagePath = "exercises/\(filename)"
        print("[VideoService] 📡 Fetching from Firebase: \(storagePath)")
        
        let storageRef = storage.reference().child(storagePath)
        
        do {
            let downloadURL = try await storageRef.downloadURL()
            print("[VideoService] ✅ Firebase SUCCESS: \(filename)")
            
            // Cache for next time
            setCachedURL(downloadURL.absoluteString, for: cacheKey)
            
            return downloadURL
        } catch {
            print("[VideoService] ❌ Firebase FAILED for \(filename): \(error)")
            if let storageError = error as NSError? {
                print("[VideoService] 📊 Error code: \(storageError.code), domain: \(storageError.domain)")
            }
            throw error
        }
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
                
                // Prefetch video URL with fast timeout
                _ = await self.fetchExerciseVideoFast(for: exerciseName)
                
                // Small delay to avoid overwhelming Firebase
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
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

// MARK: - Error Types
enum VideoServiceError: Error {
    case timeout
    case notFound
    case networkError
    case invalidURL
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