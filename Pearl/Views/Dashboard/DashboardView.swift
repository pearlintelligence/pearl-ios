import SwiftUI

// MARK: - Dashboard View
// Five-System Cosmic Fingerprint — the unified profile dashboard

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var expandedSection: DashboardSection? = nil
    
    enum DashboardSection: String {
        case astrology, humanDesign, kabbalah, numerology
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Greeting header
                        greetingHeader
                        
                        // Life Purpose card (CORE — most important)
                        if let purpose = viewModel.fingerprint?.lifePurpose {
                            NavigationLink {
                                LifePurposeView(
                                    purpose: purpose,
                                    userName: FingerprintStore.shared.userName ?? "Seeker"
                                )
                            } label: {
                                LifePurposeCard(purpose: purpose, onTap: {})
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Morning Cosmic Brief card (label: "What's Happening Now")
                        morningBriefCard
                        
                        // Five-System Fingerprint (label: "Your Blueprint")
                        fiveSystemSection
                        
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
    
    // MARK: - Greeting Header
    
    private var greetingHeader: some View {
        VStack(spacing: 8) {
            let name = FingerprintStore.shared.userName
            Text(viewModel.greeting + (name.isEmpty ? "" : ", \(name)"))
                .font(PearlFonts.screenTitle)
                .foregroundColor(PearlColors.goldLight)
            
            if let fingerprint = viewModel.fingerprint {
                let sun = fingerprint.astrology.sunSign
                let moon = fingerprint.astrology.moonSign
                Text("\(sun.symbol) \(sun.displayName) Sun · \(moon.symbol) \(moon.displayName) Moon")
                    .font(PearlFonts.body(15))
                    .foregroundColor(PearlColors.textSecondary)
                
                if let rising = fingerprint.astrology.risingSign {
                    Text("\(rising.symbol) \(rising.displayName) Rising")
                        .font(PearlFonts.body(14))
                        .foregroundColor(PearlColors.textMuted)
                }
            } else if let blueprint = viewModel.legacyBlueprint {
                Text("\(blueprint.sunSign.symbol) \(blueprint.sunSign.displayName) Sun · \(blueprint.moonSign.symbol) \(blueprint.moonSign.displayName) Moon")
                    .font(PearlFonts.body(15))
                    .foregroundColor(PearlColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Morning Cosmic Brief
    
    private var morningBriefCard: some View {
        Group {
            if let brief = viewModel.morningBrief {
                NavigationLink {
                    MorningBriefDetailView(brief: brief)
                } label: {
                    PearlCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("☉")
                                    .font(.system(size: 20))
                                Text("What's Happening Now")
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
                                .foregroundColor(PearlColors.goldLight)
                                .lineSpacing(4)
                                .lineLimit(3)
                            
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
                // Generate brief button
                PearlCard {
                    VStack(spacing: 16) {
                        Image(systemName: "sun.and.horizon.fill")
                            .font(.system(size: 28))
                            .foregroundColor(PearlColors.gold.opacity(0.6))
                        
                        Text("What's Happening Now")
                            .font(PearlFonts.cardTitle)
                            .foregroundColor(PearlColors.goldLight)
                        
                        Text("Pearl reads the sky each morning and whispers what it means for you.")
                            .font(PearlFonts.pearlWhisper)
                            .foregroundColor(PearlColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        PearlSecondaryButton("Generate Today's Brief", icon: "sparkles") {
                            Task { await viewModel.generateMorningBrief() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Five-System Section
    
    private var fiveSystemSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Blueprint")
                .font(PearlFonts.sectionTitle)
                .foregroundColor(PearlColors.goldLight)
                .padding(.leading, 4)
            
            Text("Five ancient traditions, one unified portrait")
                .font(PearlFonts.pearlWhisper)
                .foregroundColor(PearlColors.textMuted)
                .padding(.leading, 4)
            
            // 1. Western Astrology
            astrologyCard
            
            // 2. Human Design
            humanDesignCard
            
            // 3. Kabbalah
            kabbalahCard
            
            // 5. Numerology
            numerologyCard
        }
    }
    
    // MARK: - 1. Astrology Card
    
    private var astrologyCard: some View {
        SystemCard(
            title: "Western Astrology",
            symbol: "☉",
            color: PearlColors.stardust,
            isExpanded: expandedSection == .astrology,
            onTap: { toggleSection(.astrology) }
        ) {
            if let fp = viewModel.fingerprint {
                VStack(spacing: 16) {
                    // Zodiac wheel
                    ZodiacWheelView(positions: fp.astrology.planetaryPositions)
                        .frame(height: 220)
                    
                    // Big three
                    HStack(spacing: 0) {
                        bigThreeItem("Sun", fp.astrology.sunSign)
                        bigThreeItem("Moon", fp.astrology.moonSign)
                        if let rising = fp.astrology.risingSign {
                            bigThreeItem("Rising", rising)
                        }
                    }
                    
                    // Planets
                    VStack(spacing: 6) {
                        ForEach(fp.astrology.planetaryPositions) { pos in
                            HStack {
                                Text(pos.planet.symbol)
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                Text(pos.planet.displayName)
                                    .font(PearlFonts.bodyMedium(13))
                                    .foregroundColor(PearlColors.textPrimary)
                                Spacer()
                                Text("\(pos.sign.symbol) \(pos.sign.displayName)")
                                    .font(PearlFonts.body(13))
                                    .foregroundColor(PearlColors.textSecondary)
                                if pos.isRetrograde {
                                    Text("℞")
                                        .font(.system(size: 11))
                                        .foregroundColor(PearlColors.warning)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }
    
    private func bigThreeItem(_ label: String, _ sign: ZodiacSign) -> some View {
        VStack(spacing: 4) {
            Text(sign.symbol)
                .font(.system(size: 28))
            Text(sign.displayName)
                .font(PearlFonts.bodyMedium(13))
                .foregroundColor(PearlColors.goldLight)
            Text(label)
                .font(PearlFonts.caption)
                .foregroundColor(PearlColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 2. Human Design Card
    
    private var humanDesignCard: some View {
        let hd = viewModel.fingerprint?.humanDesign ?? viewModel.legacyBlueprint?.humanDesign
        
        return SystemCard(
            title: "Human Design",
            symbol: "◈",
            color: PearlColors.cosmic,
            isExpanded: expandedSection == .humanDesign,
            onTap: { toggleSection(.humanDesign) }
        ) {
            if let hd = hd {
                VStack(alignment: .leading, spacing: 16) {
                    // Type
                    Text(hd.type.rawValue)
                        .font(PearlFonts.oracleSemiBold(24))
                        .foregroundColor(PearlColors.gold)
                    
                    Text(hd.type.description)
                        .font(PearlFonts.pearlWhisper)
                        .foregroundColor(PearlColors.textSecondary)
                        .lineSpacing(4)
                    
                    Divider().background(PearlColors.surface)
                    
                    // Details
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        HDDetailCell(label: "Strategy", value: hd.strategy)
                        HDDetailCell(label: "Authority", value: hd.authority)
                        HDDetailCell(label: "Profile", value: hd.profile)
                        HDDetailCell(label: "Defined Centers", value: "\(hd.definedCenters.count)/9")
                    }
                    
                    // Centers visualization
                    HStack(spacing: 4) {
                        ForEach(HDCenter.allCases, id: \.self) { center in
                            VStack(spacing: 2) {
                                Circle()
                                    .fill(hd.definedCenters.contains(center) ? PearlColors.gold : PearlColors.surface)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(PearlColors.gold.opacity(0.3), lineWidth: 0.5)
                                    )
                                Text(center.displayName.prefix(3))
                                    .font(PearlFonts.body(8))
                                    .foregroundColor(PearlColors.textMuted)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Kabbalah Card
    
    private var kabbalahCard: some View {
        SystemCard(
            title: "Kabbalah",
            symbol: "✡",
            color: PearlColors.gold,
            isExpanded: expandedSection == .kabbalah,
            onTap: { toggleSection(.kabbalah) }
        ) {
            if let kb = viewModel.fingerprint?.kabbalah {
                VStack(alignment: .leading, spacing: 16) {
                    // Soul Correction
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Soul Correction")
                            .font(PearlFonts.labelText)
                            .foregroundColor(PearlColors.textMuted)
                        Text("#\(kb.soulCorrection.number) — \(kb.soulCorrection.name)")
                            .font(PearlFonts.oracleSemiBold(20))
                            .foregroundColor(PearlColors.gold)
                        Text(kb.soulCorrection.description)
                            .font(PearlFonts.pearlWhisper)
                            .foregroundColor(PearlColors.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    Divider().background(PearlColors.surface)
                    
                    // Birth Sephirah
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Birth Sephirah")
                            .font(PearlFonts.labelText)
                            .foregroundColor(PearlColors.textMuted)
                        HStack(spacing: 8) {
                            Text(kb.birthSephirah.hebrewName)
                                .font(.system(size: 20))
                            Text("\(kb.birthSephirah.name) — \(kb.birthSephirah.meaning)")
                                .font(PearlFonts.bodyMedium(15))
                                .foregroundColor(PearlColors.goldLight)
                        }
                        Text(kb.birthSephirah.quality)
                            .font(PearlFonts.body(14))
                            .foregroundColor(PearlColors.textSecondary)
                            .lineSpacing(3)
                    }
                    
                    Divider().background(PearlColors.surface)
                    
                    // Tikkun Path
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tikkun Path")
                            .font(PearlFonts.labelText)
                            .foregroundColor(PearlColors.textMuted)
                        Text(kb.tikkunPath)
                            .font(PearlFonts.pearlWhisper)
                            .foregroundColor(PearlColors.textSecondary)
                            .lineSpacing(4)
                    }
                }
            } else {
                Text("Complete your cosmic fingerprint to unlock Kabbalah")
                    .font(PearlFonts.body(14))
                    .foregroundColor(PearlColors.textMuted)
            }
        }
    }
    
    // MARK: - 5. Numerology Card
    
    private var numerologyCard: some View {
        SystemCard(
            title: "Numerology",
            symbol: "𝟗",
            color: PearlColors.success,
            isExpanded: expandedSection == .numerology,
            onTap: { toggleSection(.numerology) }
        ) {
            if let num = viewModel.fingerprint?.numerology {
                VStack(alignment: .leading, spacing: 16) {
                    NumerologyRow(number: num.lifePath)
                    Divider().background(PearlColors.surface)
                    NumerologyRow(number: num.expression)
                    Divider().background(PearlColors.surface)
                    NumerologyRow(number: num.soulUrge)
                    Divider().background(PearlColors.surface)
                    NumerologyRow(number: num.personality)
                    
                    Divider().background(PearlColors.surface)
                    
                    // Personal Year
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Personal Year")
                            .font(PearlFonts.labelText)
                            .foregroundColor(PearlColors.textMuted)
                        HStack {
                            Text("\(num.personalYear)")
                                .font(PearlFonts.oracleSemiBold(28))
                                .foregroundColor(PearlColors.gold)
                            Text("— \(num.personalYearTheme)")
                                .font(PearlFonts.body(14))
                                .foregroundColor(PearlColors.textSecondary)
                        }
                    }
                }
            } else {
                Text("Complete your cosmic fingerprint to unlock Numerology")
                    .font(PearlFonts.body(14))
                    .foregroundColor(PearlColors.textMuted)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toggleSection(_ section: DashboardSection) {
        withAnimation(.easeInOut(duration: 0.3)) {
            expandedSection = expandedSection == section ? nil : section
        }
    }
}

// MARK: - System Card (Expandable)

struct SystemCard<Content: View>: View {
    let title: String
    let symbol: String
    let color: Color
    let isExpanded: Bool
    let onTap: () -> Void
    let content: Content
    
    init(
        title: String,
        symbol: String,
        color: Color,
        isExpanded: Bool,
        onTap: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.symbol = symbol
        self.color = color
        self.isExpanded = isExpanded
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button(action: onTap) {
                HStack {
                    Text(symbol)
                        .font(.system(size: 24))
                    
                    Text(title)
                        .font(PearlFonts.oracleMedium(18))
                        .foregroundColor(PearlColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PearlColors.textMuted)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                content
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(PearlColors.surface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isExpanded ? color.opacity(0.3) : PearlColors.gold.opacity(0.1),
                            lineWidth: isExpanded ? 1 : 0.5
                        )
                )
        )
    }
}

// MARK: - Numerology Row

struct NumerologyRow: View {
    let number: NumerologyService.NumerologyNumber
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(number.type)
                    .font(PearlFonts.labelText)
                    .foregroundColor(PearlColors.textMuted)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(number.value)")
                        .font(PearlFonts.oracleSemiBold(22))
                        .foregroundColor(PearlColors.gold)
                    if number.isMasterNumber {
                        Text("Master")
                            .font(PearlFonts.body(10))
                            .foregroundColor(PearlColors.gold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(PearlColors.gold.opacity(0.15))
                            )
                    }
                }
            }
            
            Text(number.meaning)
                .font(PearlFonts.body(14))
                .foregroundColor(PearlColors.textSecondary)
                .lineSpacing(3)
            
            // Keywords
            HStack(spacing: 6) {
                ForEach(number.keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(PearlFonts.body(11))
                        .foregroundColor(PearlColors.gold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(PearlColors.gold.opacity(0.08))
                        )
                }
            }
        }
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

// MARK: - Zodiac Segment

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
