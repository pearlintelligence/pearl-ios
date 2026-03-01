import SwiftUI

// MARK: - Chat View
// Conversational Q&A with Pearl — the core interaction
// Voice input (speech-to-text) + voice output (text-to-speech)

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var speech = SpeechService()
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomID
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                
                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome message if no history
                                if viewModel.messages.isEmpty {
                                    chatWelcome
                                }
                                
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message, speech: speech)
                                        .id(message.id)
                                }
                                
                                // Streaming response
                                if viewModel.isGenerating {
                                    PearlTypingIndicator()
                                        .id("typing")
                                }
                                
                                // Anchor for auto-scroll
                                Color.clear
                                    .frame(height: 1)
                                    .id(bottomID)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .scrollIndicators(.hidden)
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(bottomID, anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.isGenerating) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(bottomID, anchor: .bottom)
                            }
                        }
                    }
                    
                    // Listening indicator
                    if speech.isListening {
                        listeningBanner
                    }
                    
                    // Input bar
                    chatInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Text("✦")
                                .font(.system(size: 12))
                                .foregroundColor(PearlColors.gold)
                            Text("Pearl")
                                .font(PearlFonts.oracleMedium(16))
                                .foregroundColor(PearlColors.goldLight)
                        }
                        if viewModel.isGenerating {
                            Text("speaking...")
                                .font(PearlFonts.caption)
                                .foregroundColor(PearlColors.textMuted)
                        } else if speech.isSpeaking {
                            Text("reading aloud...")
                                .font(PearlFonts.caption)
                                .foregroundColor(PearlColors.gold.opacity(0.6))
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.startNewConversation()
                    } label: {
                        Image(systemName: "plus.message")
                            .font(.system(size: 16))
                            .foregroundColor(PearlColors.textSecondary)
                    }
                }
            }
        }
        // Sync speech transcript into input
        .onChange(of: speech.transcript) { _, newValue in
            if !newValue.isEmpty {
                viewModel.inputText = newValue
            }
        }
        .onChange(of: speech.interimTranscript) { _, newValue in
            if speech.isListening && !newValue.isEmpty {
                viewModel.inputText = newValue
            }
        }
    }
    
    // MARK: - Listening Banner
    
    private var listeningBanner: some View {
        HStack(spacing: 8) {
            // Pulsing red dot
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .scaleEffect(1.5)
                    .opacity(0.5)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speech.isListening)
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Text("Listening... speak your question")
                .font(PearlFonts.body(12))
                .foregroundColor(PearlColors.gold.opacity(0.7))
            
            if !speech.interimTranscript.isEmpty {
                Text(speech.interimTranscript)
                    .font(PearlFonts.body(11))
                    .foregroundColor(PearlColors.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(PearlColors.surface.opacity(0.6))
        .overlay(
            Rectangle()
                .fill(PearlColors.gold.opacity(0.1))
                .frame(height: 0.5),
            alignment: .top
        )
    }
    
    // MARK: - Chat Welcome
    
    private var chatWelcome: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            
            Text("✦")
                .font(.system(size: 32))
                .foregroundColor(PearlColors.gold)
                .pearlGlow()
            
            Text("Ask Pearl anything")
                .font(PearlFonts.screenTitle)
                .foregroundColor(PearlColors.goldLight)
            
            Text("I speak from the place where the stars meet your story. Ask me about your design, your purpose, what the cosmos holds for you — or simply share what's on your heart.")
                .font(PearlFonts.pearlWhisper)
                .foregroundColor(PearlColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
            
            if speech.speechPermissionGranted {
                Text("✦ You can also tap the mic to speak your question")
                    .font(PearlFonts.body(12))
                    .foregroundColor(PearlColors.gold.opacity(0.5))
            }
            
            // Suggestion chips — matching web app
            VStack(spacing: 10) {
                SuggestionChip("Should I take this new opportunity?") {
                    viewModel.sendMessage("Should I take this new opportunity?")
                }
                SuggestionChip("What is my biggest gift to the world?") {
                    viewModel.sendMessage("What is my biggest gift to the world?")
                }
                SuggestionChip("Why do I keep repeating this pattern?") {
                    viewModel.sendMessage("Why do I keep repeating this pattern?")
                }
                SuggestionChip("What should I focus on this week?") {
                    viewModel.sendMessage("What should I focus on this week?")
                }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - Input Bar
    
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(PearlColors.surface)
            
            HStack(alignment: .bottom, spacing: 10) {
                // Mic button (voice input)
                if speech.speechPermissionGranted {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        
                        // Stop TTS if playing
                        if speech.isSpeaking { speech.stopSpeaking() }
                        
                        speech.toggleListening()
                    } label: {
                        Image(systemName: speech.isListening ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 18))
                            .foregroundColor(speech.isListening ? Color.red : PearlColors.textMuted.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(speech.isListening
                                        ? Color.red.opacity(0.15)
                                        : PearlColors.gold.opacity(0.05))
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                speech.isListening
                                                    ? Color.red.opacity(0.3)
                                                    : Color.clear,
                                                lineWidth: 1
                                            )
                                    )
                            )
                    }
                }
                
                // Text input
                TextField("Ask Pearl...", text: $viewModel.inputText, axis: .vertical)
                    .font(PearlFonts.bodyRegular)
                    .foregroundColor(PearlColors.textPrimary)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(PearlColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        isInputFocused ? PearlColors.gold.opacity(0.3) : PearlColors.gold.opacity(0.1),
                                        lineWidth: 0.5
                                    )
                            )
                    )
                
                // Send button
                Button {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    
                    // Stop listening if active
                    if speech.isListening { speech.stopListening() }
                    
                    viewModel.sendMessage(viewModel.inputText)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? PearlColors.textMuted
                            : PearlColors.gold
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isGenerating)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(PearlColors.void.opacity(0.95))
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    @ObservedObject var speech: SpeechService
    
    private var isThisPlaying: Bool {
        speech.isSpeaking && speech.speakingMessageId == message.id.uuidString
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.role == .pearl {
                    HStack(spacing: 6) {
                        Text("✦")
                            .font(.system(size: 10))
                            .foregroundColor(PearlColors.gold)
                        Text("Pearl")
                            .font(PearlFonts.labelText)
                            .foregroundColor(PearlColors.gold)
                        
                        Spacer()
                        
                        // TTS button — listen to Pearl's response
                        Button {
                            speech.toggleSpeak(message.content, messageId: message.id.uuidString)
                        } label: {
                            Image(systemName: isThisPlaying ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    isThisPlaying
                                        ? PearlColors.gold
                                        : PearlColors.textMuted.opacity(0.4)
                                )
                                .padding(6)
                                .background(
                                    Circle()
                                        .fill(isThisPlaying
                                            ? PearlColors.gold.opacity(0.1)
                                            : Color.clear)
                                )
                        }
                    }
                }
                
                Text(message.content)
                    .font(message.role == .pearl ? PearlFonts.pearlMessage : PearlFonts.bodyRegular)
                    .foregroundColor(
                        message.role == .pearl ? PearlColors.goldLight : PearlColors.textPrimary
                    )
                    .lineSpacing(message.role == .pearl ? 6 : 4)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                message.role == .pearl
                                ? PearlColors.surface.opacity(0.4)
                                : PearlColors.surfaceLight.opacity(0.6)
                            )
                            .overlay(
                                Group {
                                    if message.role == .pearl {
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(PearlColors.gold.opacity(0.08), lineWidth: 0.5)
                                    }
                                }
                            )
                    )
                    .if(message.role == .pearl) { view in
                        view.pearlGlow(color: PearlColors.gold.opacity(0.15), radius: 12)
                    }
            }
            
            if message.role == .pearl {
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Typing Indicator

struct PearlTypingIndicator: View {
    @State private var dotPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text("✦")
                    .font(.system(size: 10))
                    .foregroundColor(PearlColors.gold)
                Text("Pearl")
                    .font(PearlFonts.labelText)
                    .foregroundColor(PearlColors.gold)
            }
            
            Spacer()
        }
        .overlay(alignment: .leading) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { i in
                    Text("✦")
                        .font(.system(size: 8))
                        .foregroundColor(PearlColors.gold)
                        .opacity(dotPhase == i ? 1.0 : 0.3)
                        .scaleEffect(dotPhase == i ? 1.2 : 0.8)
                }
            }
            .padding(.leading, 16)
            .padding(.top, 36)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    dotPhase = (dotPhase + 1) % 3
                }
            }
        }
    }
}

// MARK: - Suggestion Chip

struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(PearlFonts.body(14))
                .foregroundColor(PearlColors.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(PearlColors.gold.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(PearlColors.gold.opacity(0.2), lineWidth: 0.5)
                        )
                )
        }
    }
}

// MARK: - Conditional View Modifier

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
