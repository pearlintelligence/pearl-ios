import SwiftUI

// MARK: - What's Happening Now — Transit View
// Real-time planetary transits vs natal chart.
// Frontend label: "What's Happening Now"

struct TransitView: View {
    let transitChart: TransitChart
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("What's Happening Now")
                        .font(PearlFonts.oracleSemiBold(14))
                        .foregroundColor(PearlColors.gold)
                        .tracking(3)
                        .textCase(.uppercase)
                    
                    Text("Real-time cosmic weather")
                        .font(PearlFonts.pearlWhisper)
                        .foregroundColor(PearlColors.textSecondary)
                }
                .padding(.top, 20)
                
                // Major Transits
                if !transitChart.majorTransits.isEmpty {
                    transitSection(
                        title: "Major Transits",
                        subtitle: "Deep shifts in motion",
                        transits: transitChart.majorTransits,
                        accentColor: PearlColors.goldLight
                    )
                }
                
                // Personal Transits
                let personalOnly = transitChart.personalTransits.filter {
                    $0.significance != .major
                }
                if !personalOnly.isEmpty {
                    transitSection(
                        title: "Personal Transits",
                        subtitle: "Touching your planets today",
                        transits: Array(personalOnly.prefix(6)),
                        accentColor: PearlColors.gold
                    )
                }
                
                // Current Sky
                currentSkySection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
        .background(PearlColors.void)
    }
    
    // MARK: - Transit Section
    
    private func transitSection(
        title: String,
        subtitle: String,
        transits: [TransitAspect],
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PearlFonts.oracleMedium(16))
                    .foregroundColor(accentColor)
                    .tracking(1)
                Text(subtitle)
                    .font(PearlFonts.caption)
                    .foregroundColor(PearlColors.textMuted)
            }
            
            ForEach(transits) { transit in
                transitRow(transit)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PearlColors.surface.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Transit Row
    
    private func transitRow(_ transit: TransitAspect) -> some View {
        HStack(spacing: 12) {
            // Aspect symbol
            Text(transit.aspect.symbol)
                .font(.system(size: 18))
                .foregroundColor(aspectColor(transit.aspect))
                .frame(width: 30)
            
            // Description
            VStack(alignment: .leading, spacing: 2) {
                Text(transit.displayDescription)
                    .font(PearlFonts.body(14))
                    .foregroundColor(PearlColors.textPrimary)
                
                HStack(spacing: 8) {
                    Text(transit.aspect.nature)
                        .font(PearlFonts.caption)
                        .foregroundColor(aspectColor(transit.aspect).opacity(0.8))
                    
                    Text("•")
                        .foregroundColor(PearlColors.textMuted)
                    
                    Text(String(format: "%.1f° orb", transit.orb))
                        .font(PearlFonts.caption)
                        .foregroundColor(PearlColors.textMuted)
                    
                    if transit.isApplying {
                        Text("→")
                            .font(PearlFonts.caption)
                            .foregroundColor(PearlColors.gold)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Current Sky
    
    private var currentSkySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Sky")
                .font(PearlFonts.oracleMedium(16))
                .foregroundColor(PearlColors.gold)
                .tracking(1)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 12) {
                ForEach(transitChart.currentPositions) { pos in
                    HStack(spacing: 8) {
                        Text(pos.planet.symbol)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pos.planet.displayName)
                                .font(PearlFonts.body(12))
                                .foregroundColor(PearlColors.textPrimary)
                            HStack(spacing: 4) {
                                Text("\(pos.sign.symbol) \(pos.sign.displayName)")
                                    .font(PearlFonts.caption)
                                    .foregroundColor(PearlColors.textSecondary)
                                if pos.isRetrograde {
                                    Text("℞")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PearlColors.surface.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PearlColors.gold.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Helpers
    
    private func aspectColor(_ aspect: AspectType) -> Color {
        switch aspect {
        case .conjunction: return PearlColors.goldLight
        case .trine, .sextile: return .green.opacity(0.8)
        case .square: return .red.opacity(0.7)
        case .opposition: return .orange.opacity(0.8)
        }
    }
}

// MARK: - Transit Card (compact, for dashboard)

struct TransitCard: View {
    let transitChart: TransitChart
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("⟡")
                        .font(.system(size: 18))
                    Text("What's Happening Now")
                        .font(PearlFonts.oracleMedium(14))
                        .foregroundColor(PearlColors.gold)
                    Spacer()
                    Text("\(transitChart.activeTransits.count) active")
                        .font(PearlFonts.caption)
                        .foregroundColor(PearlColors.textMuted)
                }
                
                if let topTransit = transitChart.majorTransits.first ?? transitChart.activeTransits.first {
                    Text(topTransit.displayDescription)
                        .font(PearlFonts.body(13))
                        .foregroundColor(PearlColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(PearlColors.surface.opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
