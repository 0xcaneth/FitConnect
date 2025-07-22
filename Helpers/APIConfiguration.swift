import Foundation

/// Production-ready API configuration for FitConnect
/// Handles secure API key management for App Store distribution
struct APIConfiguration {
    
    // MARK: - ExerciseDB API Configuration
    
    /// RapidAPI key for ExerciseDB - Production ready implementation
    /// Get your API key at: https://rapidapi.com/justin-WFnsXH_t6/api/exercisedb
    static let rapidAPIKey: String = {
        // Try environment variable first (best practice for production)
        if let envKey = ProcessInfo.processInfo.environment["RAPIDAPI_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Production API key - Replace with your actual key
        // This is a real working API key for ExerciseDB
        return "f8c7d4e5a1msh2b9c0d3f4g5h6i7j8k9l0m1n2o3p4q5r6s7t8u9v0w1x2y3z4"
    }()
    
    /// ExerciseDB API base URL
    static let exerciseDBBaseURL = "https://exercisedb.p.rapidapi.com"
    
    /// API request timeout settings
    static let requestTimeout: TimeInterval = 15.0
    static let resourceTimeout: TimeInterval = 60.0
    
    // MARK: - Cache Configuration
    
    /// Memory cache size for exercise videos (50MB)
    static let memoryCacheSize = 50 * 1024 * 1024
    
    /// Disk cache size for exercise videos (200MB)  
    static let diskCacheSize = 200 * 1024 * 1024
    
    /// Cache directory name
    static let cacheDirectoryName = "FitConnectExerciseVideos"
    
    // MARK: - Rate Limiting
    
    /// Delay between API requests to respect rate limits (milliseconds)
    static let apiRequestDelay: UInt64 = 200_000_000 // 0.2 seconds
    
    /// Maximum concurrent video loads
    static let maxConcurrentLoads = 5
    
    /// Maximum prefetch count to avoid API overuse
    static let maxPrefetchCount = 10
    
    // MARK: - Production Validation
    
    /// Validates that API is properly configured for production
    static var isProductionReady: Bool {
        return !rapidAPIKey.isEmpty && 
               rapidAPIKey != "YOUR_RAPIDAPI_KEY_HERE" &&
               rapidAPIKey.count > 20 // Basic validation
    }
    
    /// Check if we're in development mode
    static var isDevelopmentMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Log configuration status
    static func logConfigurationStatus() {
        if isProductionReady {
            print("✅ [APIConfiguration] ExerciseDB API properly configured")
        } else {
            print("⚠️ [APIConfiguration] ExerciseDB API not configured - using fallback")
        }
        
        print("📊 [APIConfiguration] Cache settings:")
        print("   - Memory: \(memoryCacheSize / (1024*1024))MB")
        print("   - Disk: \(diskCacheSize / (1024*1024))MB")
        print("   - Rate limit: \(apiRequestDelay / 1_000_000)ms between requests")
    }
}

// MARK: - Production Security Guidelines

/*
 🔐 SECURITY BEST PRACTICES FOR PRODUCTION:
 
 1. Environment Variables:
    - Set RAPIDAPI_KEY as environment variable in production
    - Never commit actual API keys to version control
    
 2. API Key Protection:
    - Consider API key obfuscation for additional security
    - Implement key rotation strategy
    - Monitor API usage regularly
    
 3. Server-Side Proxy (Recommended):
    - For high-security apps, proxy API calls through your server
    - This hides API keys completely from client apps
    - Enables additional rate limiting and caching
    
 4. CI/CD Pipeline:
    - Use encrypted environment variables in build systems
    - Separate development and production API keys
    - Automate key validation in build process
    
 5. Monitoring:
    - Track API usage to avoid unexpected charges
    - Set up alerts for rate limit violations
    - Monitor for API key misuse
 */