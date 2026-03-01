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
    
    // MARK: - Convex AI Proxy
    // All AI calls route through Convex backend — API key stays server-side.
    
    static var convexSiteURL: String {
        ProcessInfo.processInfo.environment["CONVEX_SITE_URL"]
            ?? "https://innerpearl.convex.site"  // TODO: Set actual deployment URL
    }
    
    static var iosApiSecret: String {
        ProcessInfo.processInfo.environment["IOS_API_SECRET"] ?? ""
    }
    
    // MARK: - API Keys
    // Only non-AI keys remain on the client.
    
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
    
    // MARK: - Sentry (Crash Reporting)
    
    static var sentryDSN: String {
        // DSN is safe to embed — it only allows sending events, not reading them.
        // Falls back to environment variable for local development overrides.
        ProcessInfo.processInfo.environment["SENTRY_DSN"]
            ?? "https://898637e3f757a5919fd2c8d07df22dd6@o4510967681646592.ingest.us.sentry.io/4510967689969664"
    }
    
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - API Endpoints
    
    /// AI proxy endpoint on Convex (replaces direct Anthropic calls)
    static var aiProxyURL: String {
        "\(convexSiteURL)/api/ai/chat"
    }
    
    // MARK: - App Settings
    
    static let maxMessageLength: Int = 2000
    static let maxConversationHistory: Int = 50
    static let maxTokensPerResponse: Int = 1024
    static let weeklyInsightDay: Int = 2 // Monday = 2
    
    // MARK: - Feature Flags
    
    static var enableHumanDesign: Bool { true }
    static var enableNumerology: Bool { true }
    static var enableGeneKeys: Bool { false }  // Removed from v1 — proprietary
    static var enableKabbalah: Bool { true }   // Enabled for P0
    
    // MARK: - Premium
    
    static let freeMessagesPerDay: Int = 10
    static let premiumMonthlyPrice: String = "$15.99"
    static let premiumYearlyPrice: String = "$99.99"
    
    // MARK: - StoreKit Product IDs
    
    static let premiumMonthlyProductID = "com.innerpearl.pearl.premium.monthly"
    static let premiumYearlyProductID = "com.innerpearl.pearl.premium.yearly"
}
