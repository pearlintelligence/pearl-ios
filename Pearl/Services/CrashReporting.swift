import Foundation
import Sentry

// MARK: - Crash Reporting & Error Monitoring
//
// Sentry integration for Pearl iOS.
// Provides crash reporting, error tracking, performance monitoring,
// and breadcrumbs for debugging user issues.
//
// Setup:
// 1. Get DSN from https://sentry.io → Project → Settings → Client Keys
// 2. Set SENTRY_DSN in project scheme environment variables
// 3. CrashReporting.start() is called automatically in PearlApp.init()

enum CrashReporting {
    
    // MARK: - Configuration
    
    private static let dsn = AppConfig.sentryDSN
    private static let environment = AppConfig.isDebug ? "development" : "production"
    
    // MARK: - Initialize
    
    /// Call once at app launch (in PearlApp.init)
    static func start() {
        guard !dsn.isEmpty else {
            print("⚠️ Sentry DSN not configured — crash reporting disabled")
            print("   Set SENTRY_DSN in scheme environment variables or AppConfig")
            return
        }
        
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.debug = AppConfig.isDebug
            
            // Performance monitoring — sample 100% in dev, 20% in prod
            options.tracesSampleRate = AppConfig.isDebug ? 1.0 : 0.2
            
            // Session tracking for crash-free rate
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30_000
            
            // Breadcrumbs — auto-capture navigation, touches, network
            options.maxBreadcrumbs = 100
            options.enableAutoBreadcrumbTracking = true
            
            // Crash handling
            options.attachStacktrace = true
            options.enableCaptureFailedRequests = true
            
            // HTTP tracking (API calls to Anthropic, Astrology-API, etc.)
            options.enableNetworkTracking = true
            options.enableNetworkBreadcrumbs = true
            
            // App hangs (ANR detection)
            options.enableAppHangTracking = true
            options.appHangTimeoutInterval = 5
            
            // User privacy — don't send PII by default
            options.sendDefaultPii = false
            
            // Release tagging
            options.releaseName = "\(AppConfig.appVersion) (\(AppConfig.buildNumber))"
            
            // Before-send hook — filter out development noise
            options.beforeSend = { event in
                // Don't send events in simulator during development
                #if targetEnvironment(simulator)
                if AppConfig.isDebug { return nil }
                #endif
                return event
            }
        }
        
        print("✦ Sentry initialized — \(environment)")
    }
    
    // MARK: - User Context
    
    /// Set after user completes onboarding or auth
    static func setUser(id: String, name: String? = nil) {
        let user = User()
        user.userId = id
        user.username = name
        SentrySDK.setUser(user)
    }
    
    static func clearUser() {
        SentrySDK.setUser(nil)
    }
    
    // MARK: - Breadcrumbs
    
    /// Track screen views for debugging
    static func trackScreen(_ name: String) {
        let crumb = Breadcrumb(level: .info, category: "navigation")
        crumb.message = "Viewed \(name)"
        crumb.data = ["screen": name]
        SentrySDK.addBreadcrumb(crumb)
    }
    
    /// Track user actions (taps, interactions)
    static func trackAction(_ action: String, data: [String: Any]? = nil) {
        let crumb = Breadcrumb(level: .info, category: "user")
        crumb.message = action
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }
    
    /// Track API calls (Anthropic, Astrology-API, etc.)
    static func trackAPI(_ endpoint: String, success: Bool, duration: TimeInterval? = nil) {
        let crumb = Breadcrumb(level: success ? .info : .warning, category: "api")
        crumb.message = "\(success ? "✓" : "✗") \(endpoint)"
        var data: [String: Any] = ["success": success, "endpoint": endpoint]
        if let duration = duration { data["duration_ms"] = Int(duration * 1000) }
        crumb.data = data
        SentrySDK.addBreadcrumb(crumb)
    }
    
    // MARK: - Error Capture
    
    /// Capture a non-fatal error with optional context
    static func captureError(_ error: Error, context: [String: Any]? = nil) {
        if let context = context {
            SentrySDK.capture(error: error) { scope in
                for (key, value) in context {
                    scope.setExtra(value: value, key: key)
                }
            }
        } else {
            SentrySDK.capture(error: error)
        }
    }
    
    /// Capture a message (for important events that aren't errors)
    static func captureMessage(_ message: String, level: SentryLevel = .info) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
    }
    
    // MARK: - Performance Transactions
    
    /// Start a performance transaction (returns a Span)
    static func startTransaction(name: String, operation: String) -> Span? {
        return SentrySDK.startTransaction(name: name, operation: operation)
    }
    
    /// Add a child span to a transaction
    static func addSpan(to transaction: Span?, operation: String, description: String) -> Span? {
        return transaction?.startChild(operation: operation, description: description)
    }
    
    // MARK: - Pearl-Specific Tracking
    
    /// Track onboarding completion
    static func trackOnboardingComplete(systems: [String]) {
        trackAction("onboarding_complete", data: [
            "systems_calculated": systems,
            "system_count": systems.count
        ])
    }
    
    /// Track cosmic fingerprint generation with timing
    static func trackFingerprintGenerated(duration: TimeInterval) {
        trackAction("fingerprint_generated", data: [
            "duration_ms": Int(duration * 1000)
        ])
    }
    
    /// Track chat message (voice vs typed)
    static func trackChatMessage(isVoice: Bool) {
        trackAction("chat_message_sent", data: ["voice_input": isVoice])
    }
    
    /// Track Pearl response received
    static func trackPearlResponse(duration: TimeInterval, tokenCount: Int?) {
        var data: [String: Any] = ["duration_ms": Int(duration * 1000)]
        if let tokens = tokenCount { data["tokens"] = tokens }
        trackAction("pearl_response_received", data: data)
    }
    
    /// Track Swiss Ephemeris API usage
    static func trackAstrologyAPI(endpoint: String, success: Bool, usedFallback: Bool, duration: TimeInterval) {
        trackAPI("astrology/\(endpoint)", success: success, duration: duration)
        if usedFallback {
            captureMessage("Astrology API fallback to local calculation: \(endpoint)", level: .warning)
        }
    }
    
    /// Track morning brief generation
    static func trackMorningBrief(generated: Bool, cached: Bool) {
        trackAction("morning_brief", data: [
            "generated": generated,
            "cached": cached
        ])
    }
    
    /// Track reading generation
    static func trackReadingGenerated(type: String, duration: TimeInterval) {
        trackAction("reading_generated", data: [
            "type": type,
            "duration_ms": Int(duration * 1000)
        ])
    }
}
