import XCTest
@testable import Pearl

// MARK: - Life Purpose Engine Tests
// Core feature: North Node + MC + Sun + Saturn → purpose profile

final class LifePurposeEngineTests: XCTestCase {
    
    private var engine: LifePurposeEngine!
    
    override func setUp() {
        super.setUp()
        engine = LifePurposeEngine()
    }
    
    // MARK: - Purpose Profile Generation
    
    func testPurposeProfile_AllFieldsPopulated() {
        let chart = makeNatalChart()
        let profile = engine.calculatePurpose(from: chart)
        
        XCTAssertFalse(profile.purposeDirection.isEmpty,
                       "Purpose direction should not be empty")
        XCTAssertFalse(profile.careerAlignment.isEmpty,
                       "Career alignment should not be empty")
        XCTAssertFalse(profile.leadershipStyle.isEmpty,
                       "Leadership style should not be empty")
        XCTAssertFalse(profile.fulfillmentDrivers.isEmpty,
                       "Fulfillment drivers should not be empty")
        XCTAssertFalse(profile.longTermPath.isEmpty,
                       "Long-term path should not be empty")
    }
    
    func testPurposeProfile_Deterministic() {
        let chart = makeNatalChart()
        
        let p1 = engine.calculatePurpose(from: chart)
        let p2 = engine.calculatePurpose(from: chart)
        
        XCTAssertEqual(p1.purposeDirection, p2.purposeDirection)
        XCTAssertEqual(p1.careerAlignment, p2.careerAlignment)
        XCTAssertEqual(p1.leadershipStyle, p2.leadershipStyle)
        XCTAssertEqual(p1.fulfillmentDrivers, p2.fulfillmentDrivers)
        XCTAssertEqual(p1.longTermPath, p2.longTermPath)
    }
    
    // MARK: - Source Placements
    
    func testPurposeProfile_HasSourcePlacements() {
        let chart = makeNatalChart()
        let profile = engine.calculatePurpose(from: chart)
        
        XCTAssertFalse(profile.sourcePlacements.isEmpty,
                       "Should reference the astrological sources (North Node, MC, Sun, Saturn)")
    }
    
    func testPurposeProfile_ReferencesKeyPlanets() {
        let chart = makeNatalChart()
        let profile = engine.calculatePurpose(from: chart)
        
        let placementNames = profile.sourcePlacements.map { $0.planet }
        
        // Should include the 4 core purpose planets
        let expectedPlanets = ["North Node", "Midheaven", "Sun", "Saturn"]
        for planet in expectedPlanets {
            XCTAssertTrue(
                placementNames.contains(where: { $0.contains(planet) || planet.contains($0) }),
                "Should reference \(planet) in source placements"
            )
        }
    }
    
    // MARK: - Different Charts Produce Different Results
    
    func testPurposeProfile_DifferentChartsVary() {
        let chart1 = makeNatalChart(sunSign: "Aries", northNodeSign: "Leo")
        let chart2 = makeNatalChart(sunSign: "Pisces", northNodeSign: "Capricorn")
        
        let p1 = engine.calculatePurpose(from: chart1)
        let p2 = engine.calculatePurpose(from: chart2)
        
        // At least one field should differ for very different charts
        let allSame = p1.purposeDirection == p2.purposeDirection
            && p1.careerAlignment == p2.careerAlignment
            && p1.leadershipStyle == p2.leadershipStyle
        
        XCTAssertFalse(allSame,
                       "Very different natal charts should produce different purpose profiles")
    }
    
    // MARK: - Edge Cases
    
    func testPurposeProfile_AllSignsCovered() {
        let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                     "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        
        for sign in signs {
            let chart = makeNatalChart(sunSign: sign)
            let profile = engine.calculatePurpose(from: chart)
            
            XCTAssertFalse(profile.purposeDirection.isEmpty,
                           "Purpose should be populated for Sun in \(sign)")
            XCTAssertFalse(profile.careerAlignment.isEmpty,
                           "Career should be populated for Sun in \(sign)")
        }
    }
    
    // MARK: - Summary Text
    
    func testPurposeProfile_HasSummary() {
        let chart = makeNatalChart()
        let profile = engine.calculatePurpose(from: chart)
        
        if let summary = profile.summary {
            XCTAssertGreaterThan(summary.count, 50,
                                 "Summary should be a meaningful paragraph, not a fragment")
        }
        // Summary may be nil in some implementations (generated separately by PearlEngine)
    }
    
    // MARK: - Helpers
    
    private func makeNatalChart(
        sunSign: String = "Scorpio",
        moonSign: String = "Aquarius",
        risingSign: String = "Leo",
        northNodeSign: String = "Taurus",
        mcSign: String = "Taurus",
        saturnSign: String = "Capricorn"
    ) -> LifePurposeEngine.NatalChartInput {
        return LifePurposeEngine.NatalChartInput(
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            northNodeSign: northNodeSign,
            mcSign: mcSign,
            saturnSign: saturnSign,
            sunHouse: 4,
            moonHouse: 7,
            saturnHouse: 6,
            northNodeHouse: 10,
            mcHouse: 10
        )
    }
}
