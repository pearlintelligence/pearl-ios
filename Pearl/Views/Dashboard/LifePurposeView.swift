import SwiftUI

// MARK: - Life Purpose View
// "Your Life Purpose" — The most important user value moment.
// Shown immediately after onboarding. Drives activation and retention.

struct LifePurposeView: View {
    let purpose: LifePurposeEngine.LifePurposeProfile
    let userName: String
    
    @State private var revealProgress: CGFloat = 0
    @State private var showSections: [Bool] = Array(repeating: false, count: 5)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                headerSection
                
                // Headline — the powerful one-liner
                headlineSection
                    .opacity(showSections[0] ? 1 : 0)
                    .offset(y: showSections[0] ? 0 : 20)
                
                // Purpose Direction
                purposeCard(
                    label: "Your Life Purpose",
                    symbol: "☊",
                    content: purpose.purposeDirection,
                    visible: showSections[1]
                )
                
                // Career Alignment
                purposeCard(
                    label: "Career Alignment",
                    symbol: "✦",
                    content: purpose.careerAlignment,
                    visible: showSections[2]
                )
                
                // Leadership Style
                purposeCard(
                    label: "Your Leadership Style",
                    symbol: "♄",
                    content: purpose.leadershipStyle,
                    visible: showSections[3]
                )
                
                // Fulfillment + Long-term Path
                dualCard(visible: showSections[4])
                
                // Source placements
                sourceSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(PearlColors.void)
        .onAppear { animateReveal() }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Your Life Purpose")
                .font(PearlFonts.oracleSemiBold(14))
                .foregroundColor(PearlColors.gold)
                .tracking(3)
                .textCase(.uppercase)
            
            Text("\(userName), this is why you're here.")
                .font(PearlFonts.oracle(24))
                .foregroundColor(PearlColors.textPrimary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Headline
    
    private var headlineSection: some View {
        VStack(spacing: 16) {
            // Decorative line
            Rectangle()
                .fill(PearlColors.goldGradient)
                .frame(width: 40, height: 1)
            
            Text(purpose.headline)
                .font(PearlFonts.oracleMedium(22))
                .foregroundColor(PearlColors.goldLight)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
            
            Rectangle()
                .fill(PearlColors.goldGradient)
                .frame(width: 40, height: 1)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Purpose Card
    
    private func purposeCard(label: String, symbol: String, content: String, visible: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 18))
                Text(label)
                    .font(PearlFonts.oracleMedium(16))
                    .foregroundColor(PearlColors.gold)
                    .tracking(1)
                    .textCase(.uppercase)
            }
            
            Text(content)
                .font(PearlFonts.pearlWhisper)
                .foregroundColor(PearlColors.textSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PearlColors.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PearlColors.gold.opacity(0.15), lineWidth: 0.5)
                )
        )
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 20)
    }
    
    // MARK: - Fulfillment + Long-term Path (dual card)
    
    private func dualCard(visible: Bool) -> some View {
        VStack(spacing: 24) {
            // Fulfillment Drivers
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("♡")
                        .font(.system(size: 18))
                    Text("What Fulfills You")
                        .font(PearlFonts.oracleMedium(16))
                        .foregroundColor(PearlColors.gold)
                        .tracking(1)
                        .textCase(.uppercase)
                }
                
                Text(purpose.fulfillmentDrivers)
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Divider()
                .background(PearlColors.gold.opacity(0.2))
            
            // Long-term Path
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text("⟐")
                        .font(.system(size: 18))
                    Text("Your Long-Term Path")
                        .font(PearlFonts.oracleMedium(16))
                        .foregroundColor(PearlColors.gold)
                        .tracking(1)
                        .textCase(.uppercase)
                }
                
                Text(purpose.longTermPath)
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(PearlColors.surface.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(PearlColors.gold.opacity(0.15), lineWidth: 0.5)
                )
        )
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 20)
    }
    
    // MARK: - Source Placements
    
    private var sourceSection: some View {
        VStack(spacing: 8) {
            Text("Based on your placements")
                .font(PearlFonts.caption)
                .foregroundColor(PearlColors.textMuted)
            
            HStack(spacing: 16) {
                placementChip("☉ \(purpose.sourceData.sunSign)")
                placementChip("☊ \(purpose.sourceData.northNodeSign)")
                if let mc = purpose.sourceData.midheavenSign {
                    placementChip("MC \(mc)")
                }
                placementChip("♄ \(purpose.sourceData.saturnSign)")
            }
        }
        .padding(.top, 8)
    }
    
    private func placementChip(_ text: String) -> some View {
        Text(text)
            .font(PearlFonts.body(12))
            .foregroundColor(PearlColors.goldLight)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(PearlColors.gold.opacity(0.08))
            )
    }
    
    // MARK: - Animation
    
    private func animateReveal() {
        for i in 0..<showSections.count {
            withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.3 + 0.2)) {
                showSections[i] = true
            }
        }
    }
}

// MARK: - Life Purpose Card (for Dashboard)
// Compact card shown on the main dashboard

struct LifePurposeCard: View {
    let purpose: LifePurposeEngine.LifePurposeProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("☊")
                        .font(.system(size: 20))
                    Text("Your Life Purpose")
                        .font(PearlFonts.oracleMedium(16))
                        .foregroundColor(PearlColors.gold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PearlColors.textMuted)
                }
                
                Text(purpose.headline)
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PearlColors.surface.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [PearlColors.gold.opacity(0.3), PearlColors.gold.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
