import Foundation
import SwiftData

// MARK: - Chat ViewModel

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var currentConversation: Conversation?
    
    private let pearlEngine = PearlEngine()
    
    init() {
        // Load or create conversation
        startNewConversation()
    }
    
    // MARK: - Send Message
    
    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Clear input immediately
        inputText = ""
        
        // Add user message
        let userMessage = ChatMessage(content: trimmed, role: .user)
        messages.append(userMessage)
        
        // Generate Pearl's response
        Task {
            await generateResponse(to: trimmed)
        }
    }
    
    // MARK: - Generate Response
    
    private func generateResponse(to message: String) async {
        isGenerating = true
        
        do {
            let blueprint = BlueprintStore.shared.currentBlueprint
            
            let stream = try await pearlEngine.generateResponse(
                message: message,
                conversationHistory: messages,
                blueprint: blueprint
            )
            
            // Create Pearl's message (will be updated as stream arrives)
            let pearlMessage = ChatMessage(content: "", role: .pearl, isStreaming: true)
            messages.append(pearlMessage)
            
            var fullText = ""
            for await chunk in stream {
                fullText += chunk
                // Update the last message with streamed content
                if let lastIndex = messages.indices.last {
                    messages[lastIndex] = ChatMessage(content: fullText, role: .pearl, isStreaming: true)
                }
            }
            
            // Mark as done streaming
            if let lastIndex = messages.indices.last {
                messages[lastIndex] = ChatMessage(content: fullText, role: .pearl, isStreaming: false)
            }
            
        } catch {
            // Add error message in Pearl's voice
            let errorMessage = ChatMessage(
                content: "✦ I feel a disturbance in my connection to the cosmos. Give me a moment, and ask again.",
                role: .pearl
            )
            messages.append(errorMessage)
        }
        
        isGenerating = false
    }
    
    // MARK: - New Conversation
    
    func startNewConversation() {
        messages = []
        currentConversation = Conversation()
    }
}
