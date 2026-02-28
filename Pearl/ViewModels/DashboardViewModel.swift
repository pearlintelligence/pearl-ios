import Foundation

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var fingerprint: CosmicFingerprint?
    @Published var legacyBlueprint: CosmicBlueprint?
    @Published var morningBrief: MorningCosmicBrief?
    @Published var currentInsight: WeeklyInsight?
    @Published var isGeneratingBrief: Bool = false
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Welcome"
        }
    }
    
    var blueprint: CosmicBlueprint? {
        legacyBlueprint
    }
    
    init() {
        loadData()
    }
    
    func loadData() {
        self.fingerprint = FingerprintStore.shared.currentFingerprint
        self.legacyBlueprint = BlueprintStore.shared.currentBlueprint
    }
    
    func refresh() async {
        loadData()
        
        // Check if we need a new morning brief
        if let brief = morningBrief,
           !Calendar.current.isDateInToday(brief.date) {
            morningBrief = nil
        }
    }
    
    // MARK: - Morning Cosmic Brief Generation
    
    func generateMorningBrief() async {
        isGeneratingBrief = true
        
        do {
            let engine = PearlEngine()
            let userName = FingerprintStore.shared.userName
            
            // Build prompt for morning brief
            var context = ""
            if let fp = fingerprint {
                context = """
                User: \(userName)
                Sun: \(fp.astrology.sunSign.displayName)
                Moon: \(fp.astrology.moonSign.displayName)
                Rising: \(fp.astrology.risingSign?.displayName ?? "Unknown")
                HD Type: \(fp.humanDesign.type.rawValue)
                Strategy: \(fp.humanDesign.strategy)
                Authority: \(fp.humanDesign.authority)
                Gene Key Life Work: \(fp.geneKeys.lifeWork.number) - Gift: \(fp.geneKeys.lifeWork.gift)
                Soul Correction: \(fp.kabbalah.soulCorrection.name)
                Life Path: \(fp.numerology.lifePath.value)
                Personal Year: \(fp.numerology.personalYear)
                """
            } else if let bp = legacyBlueprint {
                context = """
                User: \(userName)
                Sun: \(bp.sunSign.displayName)
                Moon: \(bp.moonSign.displayName)
                HD Type: \(bp.humanDesign.type.rawValue)
                Life Path: \(bp.numerology.lifePath)
                """
            }
            
            let prompt = """
            Generate a morning cosmic brief for today (\(todayFormatted())). The user's profile:
            \(context)
            
            Respond in JSON format with these fields:
            - greeting: A warm, personalized morning greeting (2-3 sentences)
            - cosmicWeather: What's happening in the sky today and what it means (3-4 sentences)
            - personalInsight: A personalized insight based on their chart and today's transits (3-4 sentences)
            - dailyInvitation: A single, powerful invitation for the day (1-2 sentences)
            - transits: Array of {planet, aspect, description} for notable transits today
            """
            
            let response = try await engine.generateResponse(
                message: prompt,
                conversationHistory: []
            )
            
            // Parse the response into a brief
            let brief = MorningCosmicBrief(
                id: UUID(),
                date: Date(),
                greeting: extractField(from: response, field: "greeting") ?? "The stars have been watching over you while you slept, \(userName). Today holds something rare — a window where your deepest knowing and the cosmic currents align. Listen closely.",
                cosmicWeather: extractField(from: response, field: "cosmicWeather") ?? "The current planetary alignment invites introspection paired with bold action. There is a tension in the sky between the familiar and the unknown — and you, dear one, are being called to the unknown.",
                personalInsight: extractField(from: response, field: "personalInsight") ?? "As a \(fingerprint?.humanDesign.type.rawValue ?? "soul") with your cosmic signature, today amplifies your natural gifts. Trust what comes to you without effort — those are the threads of your design activating.",
                dailyInvitation: extractField(from: response, field: "dailyInvitation") ?? "Today's invitation: pause three times and ask, 'What do I know that I'm pretending not to know?' The answer is your compass.",
                transits: []
            )
            
            morningBrief = brief
            isGeneratingBrief = false
            
        } catch {
            // Create a beautiful fallback brief
            let name = FingerprintStore.shared.userName
            morningBrief = MorningCosmicBrief(
                id: UUID(),
                date: Date(),
                greeting: "Good morning, \(name). The cosmos stirred something for you in the night. Today carries a frequency that resonates deeply with who you are becoming.",
                cosmicWeather: "The celestial dance today weaves themes of transformation and clarity. There is a quality of revelation in the air — things hidden may surface, not to disturb you, but to set you free.",
                personalInsight: "Your cosmic blueprint suggests this is a day for aligned action. The energy supports both deep reflection and decisive movement. Trust the impulses that feel like relief rather than pressure.",
                dailyInvitation: "Let one thing go today that you've been carrying out of obligation rather than truth. The space it creates will be filled with something far more alive.",
                transits: [
                    MorningCosmicBrief.TransitEvent(planet: "Moon", aspect: "harmonizing", description: "Emotional clarity and intuitive guidance are amplified today."),
                    MorningCosmicBrief.TransitEvent(planet: "Mercury", aspect: "activating", description: "Communication flows — speak your truth clearly and with love.")
                ]
            )
            isGeneratingBrief = false
        }
    }
    
    // MARK: - Helpers
    
    private func todayFormatted() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func extractField(from text: String, field: String) -> String? {
        // Simple JSON field extraction
        if let range = text.range(of: "\"\(field)\"\\s*:\\s*\"", options: .regularExpression),
           let endRange = text[range.upperBound...].range(of: "\"") {
            let value = String(text[range.upperBound..<endRange.lowerBound])
            return value.isEmpty ? nil : value.replacingOccurrences(of: "\\n", with: "\n")
        }
        return nil
    }
}
