import Foundation

// MARK: - Cosmic Fingerprint
// Unified model encompassing four wisdom traditions + Life Purpose Engine
// v1 systems: Astrology (core) + Human Design + Kabbalah + Numerology
// Life Purpose Engine (astrology-based) is the primary interpretation layer.

struct CosmicFingerprint: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let generatedAt: Date
    
    // 1. Western Astrology (core)
    let astrology: AstrologySnapshot
    
    // 2. Human Design
    let humanDesign: HumanDesignProfile
    
    // 3. Kabbalah
    let kabbalah: KabbalahService.KabbalahProfile
    
    // 4. Numerology
    let numerology: NumerologyService.FullNumerologyProfile
    
    // Life Purpose (CORE — generated immediately after natal chart)
    let lifePurpose: LifePurposeEngine.LifePurposeProfile?
    
    // Pearl's synthesis of all systems
    let synthesis: PearlSynthesis
}

// MARK: - Astrology Snapshot

struct AstrologySnapshot: Codable {
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let risingSign: ZodiacSign?
    let midheavenSign: ZodiacSign?   // MC — career direction, public role
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
    private let kabbalahService = KabbalahService()
    private let numerologyService = NumerologyService()
    
    func build(
        name: String,
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double,
        cityName: String? = nil,
        countryCode: String? = nil
    ) async throws -> CosmicFingerprint {
        
        // 1. Astrology (Swiss Ephemeris via API when available)
        let natalChart = try await astrologyService.calculateNatalChart(
            date: birthDate,
            time: birthTime,
            latitude: latitude,
            longitude: longitude,
            cityName: cityName,
            countryCode: countryCode
        )
        
        let astrology = AstrologySnapshot(
            sunSign: natalChart.sunSign,
            moonSign: natalChart.moonSign,
            risingSign: natalChart.risingSign,
            midheavenSign: natalChart.midheavenSign,
            planetaryPositions: natalChart.planets,
            houses: natalChart.houses,
            aspects: natalChart.aspects
        )
        
        // 1b. Life Purpose (CORE — runs immediately after natal chart)
        let lifePurposeEngine = LifePurposeEngine()
        var lifePurpose: LifePurposeEngine.LifePurposeProfile? = nil
        do {
            lifePurpose = try await lifePurposeEngine.generateLifePurpose(
                from: natalChart,
                userName: name
            )
        } catch {
            print("⚠️ Life Purpose generation failed: \(error.localizedDescription)")
        }
        
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
        
        // 3. Kabbalah
        let kabbalah = kabbalahService.calculateProfile(
            birthDate: birthDate,
            name: name
        )
        
        // 4. Numerology
        let numerology = numerologyService.calculateProfile(
            birthDate: birthDate,
            fullName: name
        )
        
        // Pearl's synthesis (astrology-based interpretation layer)
        let synthesis = PearlSynthesis(
            lifePurpose: synthesizeLifePurpose(
                astrology: astrology,
                humanDesign: humanDesign,
                numerology: numerology
            ),
            coreThemes: synthesizeCoreThemes(
                astrology: astrology,
                humanDesign: humanDesign,
                kabbalah: kabbalah,
                numerology: numerology
            ),
            superpower: synthesizeSuperpower(
                astrology: astrology,
                humanDesign: humanDesign
            ),
            shadow: synthesizeShadow(
                astrology: astrology,
                kabbalah: kabbalah
            ),
            invitation: synthesizeInvitation(
                humanDesign: humanDesign,
                numerology: numerology
            ),
            pearlSummary: ""  // Will be enriched by PearlEngine
        )
        
        return CosmicFingerprint(
            id: UUID(),
            userId: UUID(),
            generatedAt: Date(),
            astrology: astrology,
            humanDesign: humanDesign,
            kabbalah: kabbalah,
            numerology: numerology,
            lifePurpose: lifePurpose,
            synthesis: synthesis
        )
    }
    
    // MARK: - Synthesis Helpers
    // Pearl's own interpretation layer — no proprietary systems
    
    private func synthesizeLifePurpose(
        astrology: AstrologySnapshot,
        humanDesign: HumanDesignProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> String {
        let sun = astrology.sunSign.displayName
        let hdType = humanDesign.type.rawValue
        let lifePath = numerology.lifePath.value
        let moon = astrology.moonSign.displayName
        
        return "As a \(sun) Sun with a \(moon) Moon and \(hdType) design, your life purpose flows through a Life Path \(lifePath) calling. You are designed to \(humanDesign.strategy.lowercased()) and let your inner authority guide you home."
    }
    
    private func synthesizeCoreThemes(
        astrology: AstrologySnapshot,
        humanDesign: HumanDesignProfile,
        kabbalah: KabbalahService.KabbalahProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> [String] {
        var themes: [String] = [
            "\(astrology.sunSign.displayName) essence: \(astrology.sunSign.element.rawValue.capitalized) energy",
            "\(humanDesign.type.rawValue): \(humanDesign.strategy)",
            "Soul correction: \(kabbalah.soulCorrection.name)",
            "Life Path \(numerology.lifePath.value): \(numerology.lifePath.keywords.first ?? "")"
        ]
        
        if let rising = astrology.risingSign {
            themes.insert("\(rising.displayName) Rising: how the world sees you", at: 1)
        }
        
        if let mc = astrology.midheavenSign {
            themes.append("MC in \(mc.displayName): your public calling")
        }
        
        return themes
    }
    
    private func synthesizeSuperpower(
        astrology: AstrologySnapshot,
        humanDesign: HumanDesignProfile
    ) -> String {
        let element = astrology.sunSign.element.rawValue.lowercased()
        return "Your superpower lives at the intersection of your \(humanDesign.type.rawValue) energy and your \(astrology.sunSign.displayName) \(element) nature. When you \(humanDesign.strategy.lowercased()), your gifts naturally radiate."
    }
    
    private func synthesizeShadow(
        astrology: AstrologySnapshot,
        kabbalah: KabbalahService.KabbalahProfile
    ) -> String {
        let saturn = astrology.planetaryPositions.first(where: { $0.planet == .saturn })
        let saturnDesc = saturn.map { "Saturn in \($0.sign.displayName) challenges you to master \($0.sign.displayName.lowercased()) lessons" } ?? "Your Saturn placement teaches patience"
        return "\(saturnDesc), connecting to your Kabbalistic challenge of \(kabbalah.soulCorrection.challenge.lowercased()). This is not something to fix — it is the raw material of your transformation."
    }
    
    private func synthesizeInvitation(
        humanDesign: HumanDesignProfile,
        numerology: NumerologyService.FullNumerologyProfile
    ) -> String {
        let keywords = numerology.lifePath.keywords.prefix(2).joined(separator: " and ").lowercased()
        return "The invitation is clear: \(humanDesign.strategy.lowercased()), and let your Life Path \(numerology.lifePath.value) energy of \(keywords) guide your steps."
    }
}
