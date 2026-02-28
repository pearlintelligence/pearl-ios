import Foundation

// MARK: - Five-System Cosmic Fingerprint
// Unified model encompassing all five wisdom traditions

struct CosmicFingerprint: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let generatedAt: Date
    
    // 1. Western Astrology
    let astrology: AstrologySnapshot
    
    // 2. Human Design
    let humanDesign: HumanDesignProfile
    
    // 3. Gene Keys
    let geneKeys: GeneKeysService.GeneKeyProfile
    
    // 4. Kabbalah
    let kabbalah: KabbalahService.KabbalahProfile
    
    // 5. Numerology
    let numerology: NumerologyService.FullNumerologyProfile
    
    // Pearl's synthesis of all five systems
    let synthesis: PearlSynthesis
}

// MARK: - Astrology Snapshot

struct AstrologySnapshot: Codable {
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let risingSign: ZodiacSign?
    let planetaryPositions: [PlanetaryPosition]
    let houses: [HousePosition]?
    let aspects: [Aspect]
}

// MARK: - Pearl's Synthesis

struct PearlSynthesis: Codable {
    let lifePurpose: String
    let coreThemes: [String]
    let superpower: String
    let shadow: String
    let invitation: String
    let pearlSummary: String
}

// MARK: - Morning Cosmic Brief

struct MorningCosmicBrief: Codable, Identifiable {
    let id: UUID
    let date: Date
    let greeting: String
    let cosmicWeather: String
    let personalInsight: String
    let dailyInvitation: String
    let transits: [TransitEvent]
    
    struct TransitEvent: Codable, Identifiable {
        var id: String { "\(planet)-\(aspect)" }
        let planet: String
        let aspect: String
        let description: String
    }
}

// MARK: - Fingerprint Builder

class CosmicFingerprintBuilder {
    private let astrologyService = AstrologyService()
    private let humanDesignService = HumanDesignService()
    private let geneKeysService = GeneKeysService()
    private let kabbalahService = KabbalahService()
    private let numerologyService = NumerologyService()
    
    func build(
        name: String,
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double
    ) async throws -> CosmicFingerprint {
        
        // 1. Astrology
        let natalChart = try await astrologyService.calculateNatalChart(
            date: birthDate,
            time: birthTime,
            latitude: latitude,
            longitude: longitude
        )
        
        let astrology = AstrologySnapshot(
            sunSign: natalChart.sunSign,
            moonSign: natalChart.moonSign,
            risingSign: natalChart.risingSign,
            planetaryPositions: natalChart.planets,
            houses: natalChart.houses,
            aspects: natalChart.aspects
        )
        
        // 2. Human Design
        let hdCalc = await humanDesignService.calculate(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude
        )
        let humanDesign = HumanDesignProfile(
            type: hdCalc.type,
            strategy: hdCalc.strategy,
            authority: hdCalc.authority,
            profile: hdCalc.profile,
            definedCenters: hdCalc.definedCenters,
            undefinedCenters: hdCalc.undefinedCenters
        )
        
        // 3. Gene Keys
        let geneKeys = geneKeysService.calculateProfile(
            birthDate: birthDate,
            birthTime: birthTime
        )
        
        // 4. Kabbalah
        let kabbalah = kabbalahService.calculateProfile(
            birthDate: birthDate,
            name: name
        )
        
        // 5. Numerology
        let numerology = numerologyService.calculateProfile(
            birthDate: birthDate,
            fullName: name
        )
        
        // Pearl's synthesis
        let synthesis = PearlSynthesis(
            lifePurpose: synthesizeLifePurpose(
                astrology: astrology,
                humanDesign: humanDesign,
                geneKeys: geneKeys,
                numerology: numerology
            ),
            coreThemes: synthesizeCoreThemes(
                astrology: astrology,
                humanDesign: humanDesign,
                geneKeys: geneKeys,
                kabbalah: kabbalah,
                numerology: numerology
            ),
            superpower: synthesizeSuperpower(humanDesign: humanDesign, geneKeys: geneKeys),
            shadow: synthesizeShadow(geneKeys: geneKeys, kabbalah: kabbalah),
            invitation: synthesizeInvitation(humanDesign: humanDesign, numerology: numerology),
            pearlSummary: ""  // Will be enriched by PearlEngine
        )
        
        return CosmicFingerprint(
            id: UUID(),
            userId: UUID(),
            generatedAt: Date(),
            astrology: astrology,
            humanDesign: humanDesign,
            geneKeys: geneKeys,
            kabbalah: kabbalah,
            numerology: numerology,
            synthesis: synthesis
        )
    }
    
    // MARK: - Synthesis Helpers
    
    private func synthesizeLifePurpose(
        astrology: AstrologySnapshot,
        humanDesign: HumanDesignProfile,
        geneKeys: GeneKeysService.GeneKeyProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> String {
        let sun = astrology.sunSign.displayName
        let hdType = humanDesign.type.rawValue
        let lifeWorkGift = geneKeys.lifeWork.gift
        let lifePath = numerology.lifePath.value
        
        return "As a \(sun) Sun and \(hdType), your life purpose weaves together the gift of \(lifeWorkGift) with a Life Path \(lifePath) calling. You are designed to \(humanDesign.strategy.lowercased()) and let your authority guide you home."
    }
    
    private func synthesizeCoreThemes(
        astrology: AstrologySnapshot,
        humanDesign: HumanDesignProfile,
        geneKeys: GeneKeysService.GeneKeyProfile,
        kabbalah: KabbalahService.KabbalahProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> [String] {
        [
            "\(astrology.sunSign.displayName) essence: \(astrology.sunSign.element.rawValue.capitalized) energy",
            "\(humanDesign.type.rawValue): \(humanDesign.strategy)",
            "Life Work gift: \(geneKeys.lifeWork.gift)",
            "Soul correction: \(kabbalah.soulCorrection.name)",
            "Life Path \(numerology.lifePath.value): \(numerology.lifePath.keywords.first ?? "")"
        ]
    }
    
    private func synthesizeSuperpower(
        humanDesign: HumanDesignProfile,
        geneKeys: GeneKeysService.GeneKeyProfile
    ) -> String {
        "Your superpower lives at the intersection of your \(humanDesign.type.rawValue) energy and your Gene Key gift of \(geneKeys.lifeWork.gift). When you \(humanDesign.strategy.lowercased()), this gift naturally radiates."
    }
    
    private func synthesizeShadow(
        geneKeys: GeneKeysService.GeneKeyProfile,
        kabbalah: KabbalahService.KabbalahProfile
    ) -> String {
        "Your shadow pattern of \(geneKeys.lifeWork.shadow) connects to your Kabbalistic challenge of \(kabbalah.soulCorrection.challenge.lowercased()). This is not something to fix — it is the raw material of your transformation."
    }
    
    private func synthesizeInvitation(
        humanDesign: HumanDesignProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> String {
        let keywords = numerology.lifePath.keywords.prefix(2).joined(separator: " and ").lowercased()
        return "The invitation is clear: \(humanDesign.strategy.lowercased()), and let your Life Path \(numerology.lifePath.value) energy of \(keywords) guide your steps."
    }
}
