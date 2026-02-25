import SwiftUI

// MARK: - Insights View
// Weekly insights and insight archive

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
                            
                            Text("Weekly Insights")
                                .font(PearlFonts.screenTitle)
                                .foregroundColor(PearlColors.goldLight)
                            
                            Text("Pearl reads the cosmic weather each week\nand whispers what it means for you.")
                                .font(PearlFonts.pearlWhisper)
                                .foregroundColor(PearlColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.top, 20)
                        
                        // Current week insight
                        if let current = viewModel.currentInsight {
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
                        } else {
                            // No insight yet
                            PearlCard {
                                VStack(spacing: 16) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 32))
                                        .foregroundColor(PearlColors.gold.opacity(0.5))
                                    
                                    Text("Your first weekly insight is coming soon")
                                        .font(PearlFonts.bodyMedium(15))
                                        .foregroundColor(PearlColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Pearl is studying the stars for you.\nCheck back soon.")
                                        .font(PearlFonts.body(14))
                                        .foregroundColor(PearlColors.textMuted)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            }
                        }
                        
                        // Past insights
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
    @Published var currentInsight: WeeklyInsight?
    @Published var pastInsights: [WeeklyInsight] = []
    
    init() {
        loadInsights()
    }
    
    func loadInsights() {
        // In production, load from SwiftData
        // For now, show empty state
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: date))"
    }
}
