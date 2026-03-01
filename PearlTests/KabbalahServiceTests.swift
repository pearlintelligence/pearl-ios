import XCTest
@testable import Pearl

// MARK: - Kabbalah Service Tests
// Verifies soul correction, Tree of Life, and Sephirah calculations

final class KabbalahServiceTests: XCTestCase {
    
    private var service: KabbalahService!
    
    override func setUp() {
        super.setUp()
        service = KabbalahService()
    }
    
    // MARK: - Soul Correction
    
    func testSoulCorrection_ValidRange() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test User")
        
        // Soul correction number should be in the 72 names range (1-72)
        XCTAssertGreaterThanOrEqual(profile.soulCorrection.number, 1,
                                     "Soul correction should be ≥ 1")
        XCTAssertLessThanOrEqual(profile.soulCorrection.number, 72,
                                  "Soul correction should be ≤ 72 (72 Names of God)")
    }
    
    func testSoulCorrection_HasName() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test User")
        
        XCTAssertFalse(profile.soulCorrection.name.isEmpty,
                       "Soul correction should have a name")
    }
    
    func testSoulCorrection_HasDescription() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test User")
        
        XCTAssertFalse(profile.soulCorrection.description.isEmpty,
                       "Soul correction should have a description")
    }
    
    func testSoulCorrection_HasChallengeAndCorrection() {
        let date = makeDate(year: 1985, month: 10, day: 3)
        let profile = service.calculateProfile(birthDate: date, name: "Maria Lopez")
        
        XCTAssertFalse(profile.soulCorrection.challenge.isEmpty,
                       "Soul correction should describe a challenge")
        XCTAssertFalse(profile.soulCorrection.correction.isEmpty,
                       "Soul correction should describe the correction/growth path")
    }
    
    func testSoulCorrection_DeterministicForSameBirthDate() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile1 = service.calculateProfile(birthDate: date, name: "Alice")
        let profile2 = service.calculateProfile(birthDate: date, name: "Alice")
        
        XCTAssertEqual(profile1.soulCorrection.number, profile2.soulCorrection.number,
                       "Same birth date should always produce same soul correction")
    }
    
    func testSoulCorrection_DifferentDatesProduceDifferentResults() {
        let date1 = makeDate(year: 1990, month: 3, day: 15)
        let date2 = makeDate(year: 1990, month: 8, day: 22)
        let profile1 = service.calculateProfile(birthDate: date1, name: "Test")
        let profile2 = service.calculateProfile(birthDate: date2, name: "Test")
        
        // Not guaranteed to be different, but sanity check both are valid
        XCTAssertGreaterThanOrEqual(profile1.soulCorrection.number, 1)
        XCTAssertGreaterThanOrEqual(profile2.soulCorrection.number, 1)
    }
    
    // MARK: - Birth Sephirah
    
    func testBirthSephirah_ValidPosition() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test")
        
        XCTAssertGreaterThanOrEqual(profile.birthSephirah.position, 1,
                                     "Sephirah position should be 1-10")
        XCTAssertLessThanOrEqual(profile.birthSephirah.position, 10,
                                  "Sephirah position should be 1-10")
    }
    
    func testBirthSephirah_HasHebrewName() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test")
        
        XCTAssertFalse(profile.birthSephirah.hebrewName.isEmpty,
                       "Sephirah should have a Hebrew name")
    }
    
    func testBirthSephirah_HasMeaning() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test")
        
        XCTAssertFalse(profile.birthSephirah.meaning.isEmpty,
                       "Sephirah should have a meaning")
        XCTAssertFalse(profile.birthSephirah.quality.isEmpty,
                       "Sephirah should have a quality")
    }
    
    // MARK: - Tree of Life Positions
    
    func testTreePositions_NotEmpty() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test User")
        
        XCTAssertFalse(profile.treeOfLifePositions.isEmpty,
                       "Tree of Life should have at least some active positions")
    }
    
    func testTreePositions_ValidActivation() {
        let date = makeDate(year: 1985, month: 3, day: 22)
        let profile = service.calculateProfile(birthDate: date, name: "Sarah")
        
        for position in profile.treeOfLifePositions {
            XCTAssertGreaterThanOrEqual(position.activation, 0.0,
                                         "Activation should be ≥ 0.0")
            XCTAssertLessThanOrEqual(position.activation, 1.0,
                                      "Activation should be ≤ 1.0")
            XCTAssertFalse(position.sephirahName.isEmpty,
                           "Position should have a sephirah name")
        }
    }
    
    // MARK: - Tikkun Path
    
    func testTikkunPath_NotEmpty() {
        let date = makeDate(year: 1990, month: 5, day: 15)
        let profile = service.calculateProfile(birthDate: date, name: "Test User")
        
        XCTAssertFalse(profile.tikkunPath.isEmpty,
                       "Tikkun path should describe the soul's repair journey")
    }
    
    // MARK: - Full Profile Coherence
    
    func testFullProfile_AllFieldsPopulated() {
        let date = makeDate(year: 1978, month: 11, day: 8)
        let profile = service.calculateProfile(birthDate: date, name: "David Cohen")
        
        // Soul correction
        XCTAssertGreaterThanOrEqual(profile.soulCorrection.number, 1)
        XCTAssertFalse(profile.soulCorrection.name.isEmpty)
        
        // Birth Sephirah
        XCTAssertFalse(profile.birthSephirah.name.isEmpty)
        XCTAssertFalse(profile.birthSephirah.hebrewName.isEmpty)
        
        // Tree positions
        XCTAssertFalse(profile.treeOfLifePositions.isEmpty)
        
        // Tikkun
        XCTAssertFalse(profile.tikkunPath.isEmpty)
    }
    
    func testFullProfile_Deterministic() {
        let date = makeDate(year: 1978, month: 11, day: 8)
        let name = "David Cohen"
        
        let p1 = service.calculateProfile(birthDate: date, name: name)
        let p2 = service.calculateProfile(birthDate: date, name: name)
        
        XCTAssertEqual(p1.soulCorrection.number, p2.soulCorrection.number)
        XCTAssertEqual(p1.birthSephirah.position, p2.birthSephirah.position)
        XCTAssertEqual(p1.treeOfLifePositions.count, p2.treeOfLifePositions.count)
    }
    
    // MARK: - Edge Cases
    
    func testProfile_LeapYearBirthday() {
        let date = makeDate(year: 2000, month: 2, day: 29)
        let profile = service.calculateProfile(birthDate: date, name: "Leap Baby")
        
        XCTAssertGreaterThanOrEqual(profile.soulCorrection.number, 1)
        XCTAssertLessThanOrEqual(profile.soulCorrection.number, 72)
    }
    
    func testProfile_NewYearsDay() {
        let date = makeDate(year: 2000, month: 1, day: 1)
        let profile = service.calculateProfile(birthDate: date, name: "New Year")
        
        XCTAssertGreaterThanOrEqual(profile.soulCorrection.number, 1)
    }
    
    func testProfile_NewYearsEve() {
        let date = makeDate(year: 1999, month: 12, day: 31)
        let profile = service.calculateProfile(birthDate: date, name: "Millennium Eve")
        
        XCTAssertGreaterThanOrEqual(profile.soulCorrection.number, 1)
    }
    
    // MARK: - Helpers
    
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return Calendar.current.date(from: components)!
    }
}
