import Foundation

// MARK: - Chat ViewModel
// Manages conversation state and Pearl interactions

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var currentConversation: Conversation?
    
    private let pearlEngine = PearlEngine()
    
    init() {
        startNewConversation()
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }
        
        inputText = ""
        
        // Add user message
        let userMessage = ChatMessage(content: trimmed, role: .user)
        messages.append(userMessage)
        
        // Generate Pearl's response
        isGenerating = true
        
        Task {
            do {
                // Build conversation history for context
                let history: [(role: String, content: String)] = messages.map { msg in
                    (role: msg.role == .user ? "user" : "assistant", content: msg.content)
                }
                
                // Add user profile context
                let profileContext = buildProfileContext()
                
                let response = try await pearlEngine.generateResponse(
                    message: trimmed,
                    conversationHistory: history,
                    profileContext: profileContext
                )
                
                let pearlMessage = ChatMessage(content: response, role: .pearl)
                messages.append(pearlMessage)
                isGenerating = false
                
            } catch {
                // Graceful error handling with Pearl's voice
                let errorMessage = ChatMessage(
                    content: "I sense a disturbance in the connection between us. Let me gather myself and try again. The stars are patient — and so am I. ✦",
                    role: .pearl
                )
                messages.append(errorMessage)
                isGenerating = false
            }
        }
    }
    
    // MARK: - New Conversation
    
    func startNewConversation() {
        messages = []
        currentConversation = Conversation(title: nil)
    }
    
    // MARK: - Profile Context
    
    private func buildProfileContext() -> String {
        let name = FingerprintStore.shared.userName
        
        if let fp = FingerprintStore.shared.currentFingerprint {
            return """
            User: \(name)
            Sun Sign: \(fp.astrology.sunSign.displayName)
            Moon Sign: \(fp.astrology.moonSign.displayName)
            Rising Sign: \(fp.astrology.risingSign?.displayName ?? "Unknown")
            Human Design Type: \(fp.humanDesign.type.rawValue)
            HD Strategy: \(fp.humanDesign.strategy)
            HD Authority: \(fp.humanDesign.authority)
            HD Profile: \(fp.humanDesign.profile)
            Soul Correction: #\(fp.kabbalah.soulCorrection.number) \(fp.kabbalah.soulCorrection.name)
            Birth Sephirah: \(fp.kabbalah.birthSephirah.name) (\(fp.kabbalah.birthSephirah.meaning))
            Life Path: \(fp.numerology.lifePath.value)
            Expression: \(fp.numerology.expression.value)
            Soul Urge: \(fp.numerology.soulUrge.value)
            Personal Year: \(fp.numerology.personalYear)
            """
        } else if let bp = BlueprintStore.shared.currentBlueprint {
            return """
            User: \(name)
            Sun Sign: \(bp.sunSign.displayName)
            Moon Sign: \(bp.moonSign.displayName)
            Rising Sign: \(bp.risingSign?.displayName ?? "Unknown")
            Human Design Type: \(bp.humanDesign.type.rawValue)
            Strategy: \(bp.humanDesign.strategy)
            Authority: \(bp.humanDesign.authority)
            Life Path: \(bp.numerology.lifePath)
            """
        }
        
        return ""
    }
}
