import Foundation
import UIKit

// MARK: - Profile ViewModel

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var blueprint: CosmicBlueprint?
    @Published var conversationCount: Int = 0
    @Published var insightCount: Int = 0
    @Published var isPremium: Bool = false
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        blueprint = BlueprintStore.shared.currentBlueprint
        // In production, load from SwiftData
    }
    
    var daysSinceJoined: String {
        guard let profile = userProfile else { return "0" }
        let days = Calendar.current.dateComponents([.day], from: profile.createdAt, to: Date()).day ?? 0
        return "\(days)"
    }
    
    var birthDataSummary: String {
        guard let profile = userProfile else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: profile.birthDate)
    }
    
    func sharePearl() {
        let text = "✦ I've been talking to Pearl, my personal AI spirit guide. She synthesizes astrology, Human Design, Gene Keys, Kabbalah & numerology into one voice. She SEES you. Try it."
        let url = URL(string: "https://innerpearl-pearl-intelligence.vercel.app")!
        
        let activityVC = UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
