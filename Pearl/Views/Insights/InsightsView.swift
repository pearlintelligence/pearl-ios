import SwiftUI

// MARK: - Insights View
// Daily and weekly insights — Pearl's ongoing cosmic guidance

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("✦")
                                .font(.system(size: 24))
                                .foregroundColor(PearlColors.gold)
                            
                            Text("Cosmic Insights")
                                .font(PearlFonts.screenTitle)
                                .foregroundColor(PearlColors.goldLight)
                            
                            Text("Pearl reads the sky and whispers\nwhat it means for you.")
                                .font(PearlFonts.pearlWhisper)
                                .foregroundColor(PearlColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        
                        // Morning Cosmic Brief (today)
                        morningBriefSection
                        
                        // Current week insight
                        weeklyInsightSection
                        
                        // Past insights
                        pastInsightsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("✦")
                            .font(.system(size: 14))
                            .foregroundColor(PearlColors.gold)
                        Text("Insights")
                            .font(PearlFonts.oracleMedium(18))
                            .foregroundColor(PearlColors.goldLight)
                    }
                }
            }
        }
    }
    
    // MARK: - Morning Brief Section
    
    private var morningBriefSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("☉")
                    .font(.system(size: 18))
                Text("Today")
                    .font(PearlFonts.sectionTitle)
                    .foregroundColor(PearlColors.goldLight)
            }
            .padding(.leading, 4)
            
            if let brief = viewModel.todaysBrief {
                NavigationLink {
                    MorningBriefDetailView(brief: brief)
                } label: {
                    PearlCard(style: .wisdom) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Morning Cosmic Brief")
                                    .font(PearlFonts.cardTitle)
                                    .foregroundColor(PearlColors.goldLight)
                                Spacer()
                                Text("NEW")
                                    .font(PearlFonts.caption)
                                    .foregroundColor(PearlColors.gold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(PearlColors.gold.opacity(0.15))
                                    )
                            }
                            
                            Text(brief.greeting)
                                .font(PearlFonts.pearlWhisper)
                                .foregroundColor(PearlColors.textSecondary)
                                .lineSpacing(4)
                                .lineLimit(2)
                            
                            HStack {
                                DiamondSymbol(size: 8)
                                Text("Tap to read your full brief")
                                    .font(PearlFonts.caption)
                                    .foregroundColor(PearlColors.textMuted)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                PearlCard {
                    VStack(spacing: 16) {
                        Image(systemName: "sun.and.horizon.fill")
                            .font(.system(size: 28))
                            .foregroundColor(PearlColors.gold.opacity(0.5))
                        
                        Text("Your morning cosmic brief awaits")
                            .font(PearlFonts.bodyMedium(15))
                            .foregroundColor(PearlColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        PearlSecondaryButton("Generate Today's Brief", icon: "sparkles") {
                            Task { await viewModel.generateTodaysBrief() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Weekly Insight Section
    
    private var weeklyInsightSection: some View {
        Group {
            if let current = viewModel.currentInsight {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🌙")
                            .font(.system(size: 18))
                        Text("This Week")
                            .font(PearlFonts.sectionTitle)
                            .foregroundColor(PearlColors.goldLight)
                    }
                    .padding(.leading, 4)
                    
                    NavigationLink {
                        InsightDetailView(insight: current)
                    } label: {
                        InsightCard(
                            date: "This Week",
                            title: current.title,
                            preview: current.content,
                            isNew: !current.isRead
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Past Insights
    
    private var pastInsightsSection: some View {
        Group {
            if !viewModel.pastInsights.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Past Insights")
                        .font(PearlFonts.sectionTitle)
                        .foregroundColor(PearlColors.goldLight)
                        .padding(.leading, 4)
                    
                    ForEach(viewModel.pastInsights) { insight in
                        NavigationLink {
                            InsightDetailView(insight: insight)
                        } label: {
                            InsightCard(
                                date: viewModel.formatDate(insight.weekStartDate),
                                title: insight.title,
                                preview: insight.content,
                                isNew: false
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Insight Detail View

struct InsightDetailView: View {
    let insight: WeeklyInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            CosmicBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text("✦")
                            .font(.system(size: 28))
                            .foregroundColor(PearlColors.gold)
                            .pearlGlow()
                        
                        Text(insight.title)
                            .font(PearlFonts.screenTitle)
                            .foregroundColor(PearlColors.goldLight)
                            .multilineTextAlignment(.center)
                        
                        Text(formatFullDate(insight.weekStartDate))
                            .font(PearlFonts.caption)
                            .foregroundColor(PearlColors.textMuted)
                    }
                    .padding(.top, 40)
                    
                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(PearlColors.gold.opacity(0.2))
                            .frame(height: 0.5)
                        DiamondSymbol(size: 8, color: PearlColors.gold.opacity(0.4))
                        Rectangle()
                            .fill(PearlColors.gold.opacity(0.2))
                            .frame(height: 0.5)
                    }
                    .padding(.horizontal, 40)
                    
                    // Content
                    Text(insight.content)
                        .font(PearlFonts.pearlMessage)
                        .foregroundColor(PearlColors.goldLight)
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 28)
                    
                    // Transit context
                    if let transit = insight.transitContext {
                        PearlCard(padding: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cosmic Weather")
                                    .font(PearlFonts.labelText)
                                    .foregroundColor(PearlColors.textMuted)
                                
                                Text(transit)
                                    .font(PearlFonts.body(14))
                                    .foregroundColor(PearlColors.textSecondary)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 60)
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                DiamondSymbol(size: 12)
            }
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return "Week of \(formatter.string(from: date))"
    }
}

// MARK: - Insights ViewModel

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var todaysBrief: MorningCosmicBrief?
    @Published var currentInsight: WeeklyInsight?
    @Published var pastInsights: [WeeklyInsight] = []
    @Published var isGenerating: Bool = false
    
    init() {
        loadInsights()
    }
    
    func loadInsights() {
        // In production, load from SwiftData
        // For now, show empty state
    }
    
    func generateTodaysBrief() async {
        isGenerating = true
        
        do {
            let engine = PearlEngine()
            let name = FingerprintStore.shared.userName
            
            var profileContext = ""
            if let fp = FingerprintStore.shared.currentFingerprint {
                profileContext = """
                Name: \(name)
                Sun: \(fp.astrology.sunSign.displayName), Moon: \(fp.astrology.moonSign.displayName)
                HD Type: \(fp.humanDesign.type.rawValue), Strategy: \(fp.humanDesign.strategy)
                Soul Correction: \(fp.kabbalah.soulCorrection.name)
                Life Path: \(fp.numerology.lifePath.value)
                Personal Year: \(fp.numerology.personalYear)
                """
            }
            
            let response = try await engine.generateResponse(
                message: "Generate a morning cosmic brief for \(name) for today. Speak in Pearl's voice. Include: a greeting, cosmic weather, personal insight, and a daily invitation.",
                conversationHistory: [],
                profileContext: profileContext
            )
            
            todaysBrief = MorningCosmicBrief(
                id: UUID(),
                date: Date(),
                greeting: response,
                cosmicWeather: "",
                personalInsight: "",
                dailyInvitation: "",
                transits: []
            )
            
        } catch {
            let name = FingerprintStore.shared.userName
            todaysBrief = MorningCosmicBrief(
                id: UUID(),
                date: Date(),
                greeting: "Good morning, \(name). The cosmos stirred something for you in the night. Today carries a frequency that resonates deeply with who you are becoming.",
                cosmicWeather: "The celestial dance today weaves themes of transformation and clarity.",
                personalInsight: "Trust the impulses that feel like relief rather than pressure.",
                dailyInvitation: "Let one thing go today that you've been carrying out of obligation rather than truth.",
                transits: []
            )
        }
        
        isGenerating = false
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: date))"
    }
}
