import SwiftUI

// MARK: - Morning Cosmic Brief Detail View

struct MorningBriefDetailView: View {
    let brief: MorningCosmicBrief
    @Environment(\.dismiss) private var dismiss
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            CosmicBackground()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 16) {
                        Text("☉")
                            .font(.system(size: 36))
                            .pearlGlow(radius: 12)
                        
                        Text("Today's Cosmic Brief")
                            .font(PearlFonts.screenTitle)
                            .foregroundColor(PearlColors.goldLight)
                        
                        Text(formatDate(brief.date))
                            .font(PearlFonts.caption)
                            .foregroundColor(PearlColors.textMuted)
                    }
                    .padding(.top, 40)
                    .opacity(showContent ? 1 : 0)
                    
                    // Decorative divider
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
                    .opacity(showContent ? 1 : 0)
                    
                    // Greeting
                    Text(brief.greeting)
                        .font(PearlFonts.pearlMessage)
                        .foregroundColor(PearlColors.goldLight)
                        .lineSpacing(8)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 24)
                        .opacity(showContent ? 1 : 0)
                    
                    // Cosmic Weather
                    PearlCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("🌌")
                                    .font(.system(size: 18))
                                Text("Cosmic Weather")
                                    .font(PearlFonts.cardTitle)
                                    .foregroundColor(PearlColors.goldLight)
                            }
                            
                            Text(brief.cosmicWeather)
                                .font(PearlFonts.pearlWhisper)
                                .foregroundColor(PearlColors.textSecondary)
                                .lineSpacing(6)
                        }
                    }
                    .padding(.horizontal, 4)
                    .opacity(showContent ? 1 : 0)
                    
                    // Transits
                    if !brief.transits.isEmpty {
                        PearlCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("⚡")
                                        .font(.system(size: 18))
                                    Text("Active Transits")
                                        .font(PearlFonts.cardTitle)
                                        .foregroundColor(PearlColors.goldLight)
                                }
                                
                                ForEach(brief.transits) { transit in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("•")
                                            .foregroundColor(PearlColors.gold)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(transit.planet) \(transit.aspect)")
                                                .font(PearlFonts.bodyMedium(14))
                                                .foregroundColor(PearlColors.goldLight)
                                            Text(transit.description)
                                                .font(PearlFonts.body(13))
                                                .foregroundColor(PearlColors.textSecondary)
                                                .lineSpacing(3)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .opacity(showContent ? 1 : 0)
                    }
                    
                    // Personal Insight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Personal Insight")
                            .font(PearlFonts.sectionTitle)
                            .foregroundColor(PearlColors.goldLight)
                            .padding(.leading, 4)
                        
                        Text(brief.personalInsight)
                            .font(PearlFonts.pearlMessage)
                            .foregroundColor(PearlColors.goldLight)
                            .lineSpacing(8)
                            .padding(.horizontal, 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    
                    // Daily Invitation
                    PearlCard(style: .wisdom) {
                        VStack(spacing: 12) {
                            Text("✦")
                                .font(.system(size: 20))
                                .foregroundColor(PearlColors.gold)
                            
                            Text("Today's Invitation")
                                .font(PearlFonts.labelText)
                                .foregroundColor(PearlColors.textMuted)
                            
                            Text(brief.dailyInvitation)
                                .font(PearlFonts.pearlWhisper)
                                .foregroundColor(PearlColors.goldLight)
                                .multilineTextAlignment(.center)
                                .lineSpacing(6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 4)
                    .opacity(showContent ? 1 : 0)
                    
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                showContent = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
