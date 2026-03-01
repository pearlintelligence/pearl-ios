import SwiftUI
import SwiftData

@main
struct PearlApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService()
    @StateObject private var pearlEngine = PearlEngine()
    
    init() {
        // Initialize crash reporting (Sentry)
        CrashReporting.start()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(authService)
                .environmentObject(pearlEngine)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [
            UserProfile.self,
            Conversation.self,
            ChatMessage.self,
            WeeklyInsight.self
        ])
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var isAuthenticated: Bool = false
    @Published var currentTab: Tab = .dashboard
    
    enum Tab: Hashable {
        case dashboard
        case chat
        case insights
        case profile
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}
