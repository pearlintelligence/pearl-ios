import Foundation
import UIKit

// MARK: - Profile ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var blueprint: CosmicBlueprint?
    @Published var fingerprint: CosmicFingerprint?
    @Published var conversationCount: Int = 0
    @Published var insightCount: Int = 0
    @Published var isPremium: Bool = false
    
    var daysSinceJoined: String {
        guard let profile = userProfile else { return "1" }
        let days = Calendar.current.dateComponents([.day], from: profile.createdAt, to: Date()).day ?? 0
        return "\(max(1, days))"
    }
    
    var birthDataSummary: String {
        guard let profile = userProfile else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: profile.birthDate)
    }
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        self.blueprint = BlueprintStore.shared.currentBlueprint
        self.fingerprint = FingerprintStore.shared.currentFingerprint
        
        // Create profile from available data if none exists
        if self.userProfile == nil {
            let name = FingerprintStore.shared.userName
            if !name.isEmpty {
                self.userProfile = UserProfile(
                    name: name,
                    birthDate: Date(),
                    birthTime: nil,
                    birthLatitude: 0,
                    birthLongitude: 0,
                    birthLocationName: "Unknown"
                )
            }
        }
    }
    
    func sharePearl() {
        let text = "I discovered my cosmic fingerprint with Pearl — an AI oracle that reads your astrology, human design, kabbalah, and numerology in one unified portrait. ✦"
        let url = URL(string: "https://innerpearl.ai")!
        
        let activityController = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityController, animated: true)
        }
    }
}
