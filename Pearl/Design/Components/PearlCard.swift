import SwiftUI

// MARK: - Pearl Card

struct PearlCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 20
    var showBorder: Bool = true
    
    init(padding: CGFloat = 20, showBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(PearlColors.surface.opacity(0.6))
                    .overlay(
                        Group {
                            if showBorder {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
                            }
                        }
                    )
            )
    }
}

// MARK: - Wisdom Card

struct WisdomCard: View {
    let title: String
    let symbol: String
    let description: String
    let color: Color
    var isExpanded: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(symbol)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(PearlFonts.oracleMedium(18))
                            .foregroundColor(PearlColors.textPrimary)
                        
                        if !isExpanded {
                            Text(description)
                                .font(PearlFonts.bodyRegular)
                                .foregroundColor(PearlColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PearlColors.textMuted)
                }
                
                if isExpanded {
                    Text(description)
                        .font(PearlFonts.body(15))
                        .foregroundColor(PearlColors.textSecondary)
                        .lineSpacing(4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(PearlColors.surface.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let date: String
    let title: String
    let preview: String
    let isNew: Bool
    
    var body: some View {
        PearlCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(date)
                        .font(PearlFonts.caption)
                        .foregroundColor(PearlColors.textMuted)
                    
                    Spacer()
                    
                    if isNew {
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
                    
                    DiamondSymbol(size: 10)
                }
                
                Text(title)
                    .font(PearlFonts.oracleMedium(18))
                    .foregroundColor(PearlColors.goldLight)
                
                Text(preview)
                    .font(PearlFonts.oracle(16))
                    .foregroundColor(PearlColors.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(3)
            }
        }
    }
}
