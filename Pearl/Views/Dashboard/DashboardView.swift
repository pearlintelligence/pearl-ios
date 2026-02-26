import SwiftUI

// MARK: - Dashboard View
// The user's cosmic blueprint — their personal home screen

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var expandedWisdom: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Weekly Insight (if available)
                        if let insight = viewModel.currentInsight {
                            weeklyInsightCard(insight)
                        }
                        
                        // Cosmic Blueprint
                        blueprintSection
                        
                        // Human Design
                        humanDesignSection
                        
                        // Wisdom Traditions
                        wisdomSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("✦")
                            .font(.system(size: 14))
                            .foregroundColor(PearlColors.gold)
                        Text("Pearl")
                            .font(PearlFonts.oracleMedium(18))
                            .foregroundColor(PearlColors.goldLight)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Your Cosmic Blueprint")
                .font(PearlFonts.screenTitle)
                .foregroundColor(PearlColors.goldLight)
            
            if let blueprint = viewModel.blueprint {
                Text("\(blueprint.sunSign.symbol) \(blueprint.sunSign.displayName) Sun · \(blueprint.moonSign.symbol) \(blueprint.moonSign.displayName) Moon")
                    .font(PearlFonts.body(15))
                    .foregroundColor(PearlColors.textSecondary)
                
                if let rising = blueprint.risingSign {
                    Text("\(rising.symbol) \(rising.displayName) Rising")
                        .font(PearlFonts.body(14))
                        .foregroundColor(PearlColors.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Weekly Insight Card
    
    private func weeklyInsightCard(_ insight: WeeklyInsight) -> some View {
        NavigationLink {
            InsightDetailView(insight: insight)
        } label: {
            InsightCard(
                date: "This Week",
                title: insight.title,
                preview: insight.content,
                isNew: !insight.isRead
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Blueprint Section
    
    private var blueprintSection: some View {
        PearlCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Planetary Positions")
                        .font(PearlFonts.cardTitle)
                        .foregroundColor(PearlColors.goldLight)
                    Spacer()
                    DiamondSymbol(size: 10)
                }
                
                if let blueprint = viewModel.blueprint {
                    // Zodiac wheel placeholder
                    ZodiacWheelView(positions: blueprint.planetaryPositions)
                        .frame(height: 220)
                    
                    // Planet list
                    VStack(spacing: 8) {
                        ForEach(blueprint.planetaryPositions) { position in
                            HStack {
                                Text(position.planet.symbol)
                                    .font(.system(size: 18))
                                    .frame(width: 28)
                                
                                Text(position.planet.displayName)
                                    .font(PearlFonts.bodyMedium(14))
                                    .foregroundColor(PearlColors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(position.sign.symbol) \(position.sign.displayName)")
                                    .font(PearlFonts.body(14))
                                    .foregroundColor(PearlColors.textSecondary)
                                
                                Text(String(format: "%.1f°", position.degree.truncatingRemainder(dividingBy: 30)))
                                    .font(PearlFonts.body(12))
                                    .foregroundColor(PearlColors.textMuted)
                                    .frame(width: 40, alignment: .trailing)
                                
                                if position.isRetrograde {
                                    Text("℞")
                                        .font(.system(size: 12))
                                        .foregroundColor(PearlColors.warning)
                                }
                            }
                            .padding(.vertical, 4)
                            
                            if position.planet != .pluto {
                                Divider()
                                    .background(PearlColors.surface)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Human Design Section
    
    private var humanDesignSection: some View {
        PearlCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Human Design")
                        .font(PearlFonts.cardTitle)
                        .foregroundColor(PearlColors.goldLight)
                    Spacer()
                    Text("◈")
                        .foregroundColor(PearlColors.gold)
                }
                
                if let hd = viewModel.blueprint?.humanDesign {
                    // Type badge
                    HStack {
                        Text(hd.type.rawValue)
                            .font(PearlFonts.oracleSemiBold(22))
                            .foregroundColor(PearlColors.gold)
                    }
                    
                    Text(hd.type.description)
                        .font(PearlFonts.pearlWhisper)
                        .foregroundColor(PearlColors.textSecondary)
                        .lineSpacing(4)
                    
                    Divider().background(PearlColors.surface)
                    
                    // Details grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        HDDetailCell(label: "Strategy", value: hd.strategy)
                        HDDetailCell(label: "Authority", value: hd.authority)
                        HDDetailCell(label: "Profile", value: hd.profile)
                        HDDetailCell(label: "Defined Centers", value: "\(hd.definedCenters.count)/9")
                    }
                }
            }
        }
    }
    
    // MARK: - Wisdom Section
    
    private var wisdomSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wisdom Traditions")
                .font(PearlFonts.sectionTitle)
                .foregroundColor(PearlColors.goldLight)
                .padding(.leading, 4)
            
            ForEach(wisdomTraditions, id: \.title) { tradition in
                WisdomCard(
                    title: tradition.title,
                    symbol: tradition.symbol,
                    description: tradition.description,
                    color: tradition.color,
                    isExpanded: expandedWisdom == tradition.title,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            expandedWisdom = expandedWisdom == tradition.title ? nil : tradition.title
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Wisdom Data
    
    private var wisdomTraditions: [(title: String, symbol: String, description: String, color: Color)] {
        [
            ("Western Astrology", "☉", "Your natal chart maps the sky at the moment of your birth — revealing personality patterns, life themes, and the cosmic blueprint you were born with.", PearlColors.stardust),
            ("Human Design", "◈", "A synthesis of astrology, the I Ching, Kabbalah, and the chakra system. Your Human Design reveals your energetic type, strategy for making decisions, and unique life purpose.", PearlColors.cosmic),
            ("Gene Keys", "🧬", "The Gene Keys illuminate your shadow patterns and the gifts they contain. Each key is a journey from shadow through gift to the highest expression of your potential.", PearlColors.nebula),
            ("Kabbalah", "✡", "The Tree of Life maps the architecture of consciousness. Your soul correction reveals the spiritual work you came here to do.", PearlColors.gold),
            ("Numerology", "𝟗", "The numbers in your birth date encode your life path, soul urge, and expression. They reveal the rhythm and purpose woven into your existence.", PearlColors.success),
        ]
    }
}

// MARK: - HD Detail Cell

struct HDDetailCell: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(PearlFonts.caption)
                .foregroundColor(PearlColors.textMuted)
            Text(value)
                .font(PearlFonts.bodyMedium(15))
                .foregroundColor(PearlColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Zodiac Wheel View

struct ZodiacWheelView: View {
    let positions: [PlanetaryPosition]
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 20
            
            ZStack {
                zodiacRings(radius: radius)
                zodiacSegments(center: center, radius: radius)
                planetMarkers(center: center, radius: radius)
                centerDiamond(center: center)
            }
        }
    }
    
    // MARK: - Sub-views
    
    private func zodiacRings(radius: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(PearlColors.gold.opacity(0.2), lineWidth: 1)
                .frame(width: radius * 2, height: radius * 2)
            Circle()
                .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
                .frame(width: radius * 1.4, height: radius * 1.4)
        }
    }
    
    private func zodiacSegments(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(0..<12, id: \.self) { i in
            ZodiacSegmentView(index: i, center: center, radius: radius)
        }
    }
    
    private func planetMarkers(center: CGPoint, radius: CGFloat) -> some View {
        ForEach(positions.prefix(10)) { position in
            let angle: Double = (position.degree - 90) * .pi / 180
            let planetRadius: CGFloat = radius * 0.55
            
            Text(position.planet.symbol)
                .font(.system(size: 16))
                .foregroundColor(PearlColors.goldLight)
                .pearlGlow(color: PearlColors.gold, radius: 4)
                .position(
                    x: center.x + planetRadius * cos(angle),
                    y: center.y + planetRadius * sin(angle)
                )
        }
    }
    
    private func centerDiamond(center: CGPoint) -> some View {
        Text("✦")
            .font(.system(size: 16))
            .foregroundColor(PearlColors.gold.opacity(0.6))
            .position(center)
    }
}

// MARK: - Zodiac Segment (broken out for compiler performance)

struct ZodiacSegmentView: View {
    let index: Int
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let angle: Double = Double(index) * 30.0 - 90
        let radian: Double = angle * .pi / 180
        
        ZStack {
            Path { path in
                let inner = CGPoint(
                    x: center.x + (radius * 0.7) * cos(radian),
                    y: center.y + (radius * 0.7) * sin(radian)
                )
                let outer = CGPoint(
                    x: center.x + radius * cos(radian),
                    y: center.y + radius * sin(radian)
                )
                path.move(to: inner)
                path.addLine(to: outer)
            }
            .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
            
            signSymbol
        }
    }
    
    private var signSymbol: some View {
        let symbolAngle: Double = (Double(index) * 30.0 + 15.0 - 90) * .pi / 180
        let symbolRadius: CGFloat = radius * 0.85
        return Text(ZodiacSign.allCases[index].symbol)
            .font(.system(size: 14))
            .foregroundColor(PearlColors.gold.opacity(0.5))
            .position(
                x: center.x + symbolRadius * cos(symbolAngle),
                y: center.y + symbolRadius * sin(symbolAngle)
            )
    }
}
