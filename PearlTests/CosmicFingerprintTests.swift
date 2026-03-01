import XCTest
@testable import Pearl

// MARK: - Cosmic Fingerprint Tests
// Unified four-system model: Astrology + Human Design + Kabbalah + Numerology

final class CosmicFingerprintTests: XCTestCase {
    
    // MARK: - Builder
    
    func testBuilder_ProducesValidFingerprint() {
        let fingerprint = CosmicFingerprint.Builder()
            .withAstrology(
                sunSign: .scorpio,
                moonSign: .aquarius,
                risingSign: .leo,
                planets: [],
                houses: []
            )
            .withHumanDesign(
                type: .generator,
                strategy: "Respond",
                authority: "Sacral",
                profile: "3/5",
                definedCenters: ["Sacral", "Root"],
                channels: []
            )
            .withKabbalah(soulCorrectionNumber: 25, soulCorrectionName: "Speak Your Mind")
            .withNumerology(lifePath: 7, expression: 3, soulUrge: 5)
            .build()
        
        // Verify all four systems present
        XCTAssertEqual(fingerprint.astrology.sunSign, .scorpio)
        XCTAssertEqual(fingerprint.humanDesign.type, .generator)
        XCTAssertEqual(fingerprint.kabbalah.soulCorrectionNumber, 25)
        XCTAssertEqual(fingerprint.numerology.lifePath, 7)
    }
    
    // MARK: - Gene Keys REMOVED
    
    func testFingerprint_NoGeneKeysProperty() {
        // Gene Keys was removed from v1 — proprietary content
        // Verify the CosmicFingerprint model does NOT have geneKeys fields
        let fingerprint = CosmicFingerprint.Builder()
            .withAstrology(sunSign: .aries, moonSign: .taurus, risingSign: .gemini, planets: [], houses: [])
            .withHumanDesign(type: .manifestor, strategy: "Inform", authority: "Emotional", profile: "1/3", definedCenters: [], channels: [])
            .withKabbalah(soulCorrectionNumber: 1, soulCorrectionName: "Test")
            .withNumerology(lifePath: 1, expression: 1, soulUrge: 1)
            .build()
        
        // This test passes simply by compiling — if geneKeys existed on the model,
        // it would need to be set in the builder. Its absence IS the test.
        let mirror = Mirror(reflecting: fingerprint)
        let propertyNames = mirror.children.compactMap { $0.label }
        
        XCTAssertFalse(propertyNames.contains("geneKeys"),
                       "CosmicFingerprint should NOT have a geneKeys property — proprietary, removed from v1")
    }
    
    // MARK: - Summary Text
    
    func testFingerprint_GeneratesSummary() {
        let fingerprint = CosmicFingerprint.Builder()
            .withAstrology(sunSign: .scorpio, moonSign: .aquarius, risingSign: .leo, planets: [], houses: [])
            .withHumanDesign(type: .generator, strategy: "Respond", authority: "Sacral", profile: "3/5", definedCenters: [], channels: [])
            .withKabbalah(soulCorrectionNumber: 25, soulCorrectionName: "Speak Your Mind")
            .withNumerology(lifePath: 7, expression: 3, soulUrge: 5)
            .build()
        
        let summary = fingerprint.summary
        
        XCTAssertFalse(summary.isEmpty, "Fingerprint should generate a summary")
        XCTAssertTrue(summary.contains("Scorpio") || summary.lowercased().contains("scorpio"),
                      "Summary should mention sun sign")
    }
    
    // MARK: - System Count
    
    func testFingerprint_FourSystems() {
        // v1 has exactly 4 systems: Astrology, Human Design, Kabbalah, Numerology
        let fingerprint = CosmicFingerprint.Builder()
            .withAstrology(sunSign: .aries, moonSign: .taurus, risingSign: .gemini, planets: [], houses: [])
            .withHumanDesign(type: .manifestor, strategy: "Inform", authority: "Emotional", profile: "1/3", definedCenters: [], channels: [])
            .withKabbalah(soulCorrectionNumber: 1, soulCorrectionName: "Test")
            .withNumerology(lifePath: 1, expression: 1, soulUrge: 1)
            .build()
        
        let mirror = Mirror(reflecting: fingerprint)
        let systemProperties = mirror.children.compactMap { $0.label }
            .filter { ["astrology", "humanDesign", "kabbalah", "numerology"].contains($0) }
        
        XCTAssertEqual(systemProperties.count, 4,
                       "Should have exactly 4 system properties (no Gene Keys)")
    }
    
    // MARK: - Zodiac Sign Enum
    
    func testZodiacSign_AllTwelve() {
        let allSigns: [ZodiacSign] = [
            .aries, .taurus, .gemini, .cancer, .leo, .virgo,
            .libra, .scorpio, .sagittarius, .capricorn, .aquarius, .pisces
        ]
        
        XCTAssertEqual(allSigns.count, 12, "Should have all 12 zodiac signs")
        
        for sign in allSigns {
            XCTAssertFalse(sign.displayName.isEmpty, "\(sign) should have a display name")
            XCTAssertFalse(sign.symbol.isEmpty, "\(sign) should have a symbol")
        }
    }
    
    // MARK: - Human Design Types
    
    func testHumanDesignType_AllFive() {
        let allTypes: [HumanDesignType] = [
            .manifestor, .generator, .manifestingGenerator, .projector, .reflector
        ]
        
        XCTAssertEqual(allTypes.count, 5, "Should have all 5 Human Design types")
    }
    
    // MARK: - FingerprintStore Singleton
    
    func testFingerprintStore_SharedInstance() {
        let store = FingerprintStore.shared
        XCTAssertNotNil(store, "FingerprintStore.shared should exist")
    }
    
    func testFingerprintStore_SetAndGet() {
        let store = FingerprintStore.shared
        let fingerprint = CosmicFingerprint.Builder()
            .withAstrology(sunSign: .pisces, moonSign: .cancer, risingSign: .virgo, planets: [], houses: [])
            .withHumanDesign(type: .projector, strategy: "Wait for invitation", authority: "Splenic", profile: "4/6", definedCenters: [], channels: [])
            .withKabbalah(soulCorrectionNumber: 40, soulCorrectionName: "Long Slow Way")
            .withNumerology(lifePath: 22, expression: 9, soulUrge: 11)
            .build()
        
        store.currentFingerprint = fingerprint
        
        XCTAssertNotNil(store.currentFingerprint)
        XCTAssertEqual(store.currentFingerprint?.astrology.sunSign, .pisces)
        XCTAssertEqual(store.currentFingerprint?.humanDesign.type, .projector)
        XCTAssertEqual(store.currentFingerprint?.numerology.lifePath, 22)
    }
}
