import Foundation

// MARK: - App Configuration
// Environment-based configuration for Pearl

enum AppConfig {
    
    // MARK: - Environment
    
    enum Environment: String {
        case development
        case staging
        case production
    }
    
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    // MARK: - API Keys
    // ⚠️ In production, these should come from a secure backend or keychain.
    // NEVER ship API keys in the binary.
    
    static var anthropicAPIKey: String {
        // Read from environment or secure storage
        ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
    }
    
    static var astrologyAPIKey: String {
        // Astrology-API.io — Swiss Ephemeris calculations
        // Get a key at https://dashboard.astrology-api.io
        ProcessInfo.processInfo.environment["ASTROLOGY_API_KEY"] ?? ""
    }
    
    static var astrologyAPIBaseURL: String {
        "https://api.astrology-api.io/api/v3"
    }
    
    static var anthropicModel: String {
        "claude-sonnet-4-20250514" // or claude-3-5-haiku for faster responses
    }
    
    // Alias for convenience
    static var claudeModel: String { anthropicModel }
    
    // MARK: - API Endpoints
    
    static var anthropicBaseURL: String {
        "https://api.anthropic.com/v1"
    }
    
    // MARK: - App Settings
    
    static let maxMessageLength: Int = 2000
    static let maxConversationHistory: Int = 50
    static let maxTokensPerResponse: Int = 1024
    static let weeklyInsightDay: Int = 2 // Monday = 2
    
    // MARK: - Feature Flags
    
    static var enableHumanDesign: Bool { true }
    static var enableNumerology: Bool { true }
    static var enableGeneKeys: Bool { true }  // Enabled for P0
    static var enableKabbalah: Bool { true }   // Enabled for P0
    
    // MARK: - Premium
    
    static let freeMessagesPerDay: Int = 10
    static let premiumMonthlyPrice: String = "$15.99"
    static let premiumYearlyPrice: String = "$99.99"
    
    // MARK: - StoreKit Product IDs
    
    static let premiumMonthlyProductID = "com.innerpearl.pearl.premium.monthly"
    static let premiumYearlyProductID = "com.innerpearl.pearl.premium.yearly"
}
