import Foundation

// MARK: - Life Purpose Engine
// CORE FEATURE — Runs immediately after natal chart generation.
// Takes North Node + MC + Sun + Saturn → generates life purpose profile.
// Uses Pearl's Claude AI layer for rich, personalized interpretation.

class LifePurposeEngine {
    
    private let pearlEngine = PearlEngine()
    
    // MARK: - Life Purpose Profile
    
    struct LifePurposeProfile: Codable, Identifiable {
        var id: UUID = UUID()
        let generatedAt: Date
        
        // Core outputs per spec
        let purposeDirection: String     // Core life direction / soul mission
        let careerAlignment: String      // Career paths aligned with purpose
        let leadershipStyle: String      // How they lead and influence
        let fulfillmentDrivers: String   // What truly fulfills them
        let longTermPath: String         // Life arc and long-term trajectory
        
        // Supporting context
        let headline: String             // One-line purpose statement
        let sourceData: SourceData       // The natal chart inputs used
        
        struct SourceData: Codable {
            let northNodeSign: String
            let northNodeHouse: Int?
            let midheavenSign: String?
            let sunSign: String
            let sunHouse: Int?
            let saturnSign: String
            let saturnHouse: Int?
        }
    }
    
    // MARK: - Generate Life Purpose
    
    /// Generates a complete life purpose profile from natal chart data.
    /// This is the most important user value moment in the product.
    func generateLifePurpose(
        from natalChart: NatalChartData,
        userName: String
    ) async throws -> LifePurposeProfile {
        
        // Extract the four key inputs
        let sun = natalChart.planets.first(where: { $0.planet == .sun })!
        let saturn = natalChart.planets.first(where: { $0.planet == .saturn })
        let northNode = natalChart.planets.first(where: { $0.planet == .northNode })
        let midheaven = natalChart.midheavenSign
        let midheavenHouse = 10 // MC is always house 10
        
        // Build the astrological context for Claude
        let context = buildPurposeContext(
            sun: sun, saturn: saturn, northNode: northNode,
            midheaven: midheaven, houses: natalChart.houses
        )
        
        let prompt = """
        You are Pearl, an ancient oracle and cosmic guide. Generate a deeply personal Life Purpose reading for \(userName).
        
        THEIR KEY PURPOSE PLACEMENTS:
        \(context)
        
        Generate a JSON response with these exact fields. Each should be 2-4 sentences of warm, specific, oracle-voiced guidance. Not generic — reference their specific signs and houses. Speak as if revealing something they've always felt but couldn't name.
        
        {
            "headline": "One powerful sentence — their purpose in a nutshell",
            "purpose_direction": "Their core life direction and soul mission. What their North Node + Sun are pulling them toward. Be specific about the energy of their signs.",
            "career_alignment": "Career paths and work that aligns with their MC and Sun placement. Not just job titles — the KIND of work, the environment, the impact they're meant to make.",
            "leadership_style": "How they naturally lead, influence, and guide others. Based on their Sun + Saturn dynamic. Their authority archetype.",
            "fulfillment_drivers": "What truly fulfills them at a soul level. What makes them feel alive vs drained. Based on North Node direction vs South Node comfort zone.",
            "long_term_path": "Their life arc — where Saturn is teaching them discipline and mastery. The long game. What they're building over a lifetime."
        }
        
        Return ONLY the JSON object, no markdown formatting.
        """
        
        let response = try await pearlEngine.generateResponse(
            message: prompt,
            conversationHistory: [],
            profileContext: nil
        )
        
        // Parse the JSON response
        return try parseLifePurposeResponse(
            response: response,
            sun: sun, saturn: saturn,
            northNode: northNode, midheaven: midheaven
        )
    }
    
    /// Generate Life Purpose from a CosmicFingerprint (convenience)
    func generateLifePurpose(
        from fingerprint: CosmicFingerprint,
        userName: String
    ) async throws -> LifePurposeProfile {
        // Reconstruct NatalChartData from fingerprint's astrology snapshot
        let natalChart = NatalChartData(
            sunSign: fingerprint.astrology.sunSign,
            moonSign: fingerprint.astrology.moonSign,
            risingSign: fingerprint.astrology.risingSign,
            midheavenSign: fingerprint.astrology.midheavenSign,
            planets: fingerprint.astrology.planetaryPositions,
            houses: fingerprint.astrology.houses,
            aspects: fingerprint.astrology.aspects
        )
        return try await generateLifePurpose(from: natalChart, userName: userName)
    }
    
    // MARK: - Build Context String
    
    private func buildPurposeContext(
        sun: PlanetaryPosition,
        saturn: PlanetaryPosition?,
        northNode: PlanetaryPosition?,
        midheaven: ZodiacSign?,
        houses: [HousePosition]?
    ) -> String {
        var lines: [String] = []
        
        lines.append("☉ Sun: \(sun.sign.displayName)" + (sun.house != nil ? " in House \(sun.house!)" : ""))
        
        if let nn = northNode {
            lines.append("☊ North Node: \(nn.sign.displayName)" + (nn.house != nil ? " in House \(nn.house!)" : ""))
            // South Node is always opposite
            let southNodeSign = oppositeSign(nn.sign)
            lines.append("☋ South Node: \(southNodeSign.displayName) (comfort zone / past life patterns)")
        }
        
        if let mc = midheaven {
            lines.append("MC (Midheaven): \(mc.displayName) — public role, career direction, legacy")
        }
        
        if let sat = saturn {
            lines.append("♄ Saturn: \(sat.sign.displayName)" + (sat.house != nil ? " in House \(sat.house!)" : "") + " — discipline, mastery, life lessons")
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func oppositeSign(_ sign: ZodiacSign) -> ZodiacSign {
        let allSigns = ZodiacSign.allCases
        let index = allSigns.firstIndex(of: sign) ?? 0
        return allSigns[(index + 6) % 12]
    }
    
    // MARK: - Parse Response
    
    private func parseLifePurposeResponse(
        response: String,
        sun: PlanetaryPosition,
        saturn: PlanetaryPosition?,
        northNode: PlanetaryPosition?,
        midheaven: ZodiacSign?
    ) throws -> LifePurposeProfile {
        
        // Try to parse JSON from response (may have markdown wrapping)
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback: generate from astrological knowledge
            return generateFallbackPurpose(
                sun: sun, saturn: saturn,
                northNode: northNode, midheaven: midheaven
            )
        }
        
        let sourceData = LifePurposeProfile.SourceData(
            northNodeSign: northNode?.sign.displayName ?? "Unknown",
            northNodeHouse: northNode?.house,
            midheavenSign: midheaven?.displayName,
            sunSign: sun.sign.displayName,
            sunHouse: sun.house,
            saturnSign: saturn?.sign.displayName ?? "Unknown",
            saturnHouse: saturn?.house
        )
        
        return LifePurposeProfile(
            generatedAt: Date(),
            purposeDirection: json["purpose_direction"] as? String ?? "Your purpose is unfolding — Pearl is reading your stars.",
            careerAlignment: json["career_alignment"] as? String ?? "Your career path aligns with your deepest nature.",
            leadershipStyle: json["leadership_style"] as? String ?? "You lead with the wisdom of your unique design.",
            fulfillmentDrivers: json["fulfillment_drivers"] as? String ?? "Your fulfillment comes from living your cosmic truth.",
            longTermPath: json["long_term_path"] as? String ?? "Your Saturn teaches patience — the mastery is coming.",
            headline: json["headline"] as? String ?? "You are here for a reason the stars have always known.",
            sourceData: sourceData
        )
    }
    
    // MARK: - Fallback (No API)
    
    private func generateFallbackPurpose(
        sun: PlanetaryPosition,
        saturn: PlanetaryPosition?,
        northNode: PlanetaryPosition?,
        midheaven: ZodiacSign?
    ) -> LifePurposeProfile {
        
        let sunDesc = sunPurposeTheme(sun.sign)
        let nnDesc = northNode.map { northNodeTheme($0.sign) } ?? ""
        let satDesc = saturn.map { saturnTheme($0.sign) } ?? ""
        let mcDesc = midheaven.map { midheavenTheme($0) } ?? ""
        
        let sourceData = LifePurposeProfile.SourceData(
            northNodeSign: northNode?.sign.displayName ?? "Unknown",
            northNodeHouse: northNode?.house,
            midheavenSign: midheaven?.displayName,
            sunSign: sun.sign.displayName,
            sunHouse: sun.house,
            saturnSign: saturn?.sign.displayName ?? "Unknown",
            saturnHouse: saturn?.house
        )
        
        return LifePurposeProfile(
            generatedAt: Date(),
            purposeDirection: "Your soul is moving toward \(nnDesc). With your Sun in \(sun.sign.displayName), your core vitality shines through \(sunDesc). This lifetime is about growing beyond what's comfortable into what's calling you.",
            careerAlignment: "Your Midheaven points toward \(mcDesc). You thrive in roles where you can \(sunDesc.lowercased()) while building something meaningful. Look for work that lets your \(sun.sign.displayName) nature lead.",
            leadershipStyle: "You lead with the \(sun.sign.displayName) energy of \(sunDesc.lowercased()). \(satDesc.isEmpty ? "" : "Saturn in \(saturn?.sign.displayName ?? "") adds \(satDesc.lowercased()) to your authority.")",
            fulfillmentDrivers: "You feel most alive when \(nnDesc.lowercased()). Your South Node patterns may pull you toward old comforts, but your soul grows every time you choose the North Node path.",
            longTermPath: satDesc.isEmpty ? "Your long-term mastery unfolds through patience and dedication to your craft." : "Saturn teaches you \(satDesc.lowercased()). This is the long game — the mastery that deepens with every year. Trust the slow build.",
            headline: "Your purpose lives at the intersection of \(sun.sign.displayName) vitality and \(northNode?.sign.displayName ?? "cosmic") direction.",
            sourceData: sourceData
        )
    }
    
    // MARK: - Sign Theme Lookups
    
    private func sunPurposeTheme(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Pioneering courage and bold action"
        case .taurus: return "Building lasting value and sensory richness"
        case .gemini: return "Connecting ideas and communicating truth"
        case .cancer: return "Nurturing and creating emotional sanctuary"
        case .leo: return "Creative self-expression and radiant leadership"
        case .virgo: return "Sacred service and devotion to craft"
        case .libra: return "Creating harmony, beauty, and just relationships"
        case .scorpio: return "Transformative depth and regenerative power"
        case .sagittarius: return "Expanding horizons and seeking higher truth"
        case .capricorn: return "Building enduring structures and earned authority"
        case .aquarius: return "Innovating for the collective and honoring uniqueness"
        case .pisces: return "Channeling compassion and transcendent vision"
        }
    }
    
    private func northNodeTheme(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Independent action, courage, and self-leadership"
        case .taurus: return "Stability, self-worth, and trusting your own values"
        case .gemini: return "Curiosity, communication, and embracing many perspectives"
        case .cancer: return "Emotional vulnerability, home, and nurturing others"
        case .leo: return "Creative self-expression, joy, and being seen"
        case .virgo: return "Humble service, practical wisdom, and sacred routine"
        case .libra: return "Partnership, diplomacy, and learning to receive"
        case .scorpio: return "Deep transformation, shared resources, and intimate trust"
        case .sagittarius: return "Big-picture meaning, faith, and philosophical expansion"
        case .capricorn: return "Mastery, public contribution, and responsible leadership"
        case .aquarius: return "Community, innovation, and humanitarian vision"
        case .pisces: return "Surrender, spiritual connection, and unconditional compassion"
        }
    }
    
    private func saturnTheme(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Learning to stand alone and trust your instincts"
        case .taurus: return "Building material security through patience and persistence"
        case .gemini: return "Mastering communication and disciplined thinking"
        case .cancer: return "Emotional maturity and building true security within"
        case .leo: return "Earned confidence and authentic creative authority"
        case .virgo: return "Perfecting your craft through humble, steady practice"
        case .libra: return "Mastering committed relationships and fair negotiation"
        case .scorpio: return "Facing shadows with courage and building inner power"
        case .sagittarius: return "Grounding your beliefs in real-world wisdom"
        case .capricorn: return "Ultimate mastery — Saturn is home here. You build empires."
        case .aquarius: return "Structuring your vision for the collective good"
        case .pisces: return "Giving form to the formless — disciplined spirituality"
        }
    }
    
    private func midheavenTheme(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Leadership, entrepreneurship, and blazing trails in public"
        case .taurus: return "Building tangible beauty and lasting financial wisdom"
        case .gemini: return "Communication, media, teaching, and connecting ideas publicly"
        case .cancer: return "Caregiving, real estate, food, and emotional intelligence in career"
        case .leo: return "Performance, creative direction, and inspiring others publicly"
        case .virgo: return "Health, analysis, service, and meticulous excellence in your field"
        case .libra: return "Law, design, diplomacy, and creating aesthetic harmony"
        case .scorpio: return "Psychology, research, transformation, and working with hidden truths"
        case .sagittarius: return "Education, publishing, travel, and expanding cultural horizons"
        case .capricorn: return "Executive leadership, institution-building, and earned authority"
        case .aquarius: return "Technology, social change, and innovation that serves the future"
        case .pisces: return "Healing arts, music, spirituality, and compassionate service"
        }
    }
}
