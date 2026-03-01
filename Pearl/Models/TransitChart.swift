import Foundation

// MARK: - Transit Chart (P1)
// Real-time planetary positions compared to natal chart.
// Used for timing, daily insights, career timing alerts, and opportunity alerts.
// Calculated dynamically — no storage required.

struct TransitChart: Identifiable {
    var id: UUID = UUID()
    let generatedAt: Date
    
    // Current sky positions
    let currentPositions: [TransitPosition]
    
    // Aspects to natal planets (the active transits)
    let activeTransits: [TransitAspect]
    
    // Filtered highlights
    var majorTransits: [TransitAspect] {
        activeTransits.filter { $0.significance == .major }
    }
    
    var personalTransits: [TransitAspect] {
        activeTransits.filter { $0.isPersonalPlanet }
    }
}

// MARK: - Transit Position

struct TransitPosition: Identifiable, Codable {
    var id: String { planet.rawValue }
    let planet: Planet
    let sign: ZodiacSign
    let degree: Double
    let isRetrograde: Bool
}

// MARK: - Transit Aspect

struct TransitAspect: Identifiable, Codable {
    var id: String { "\(transitPlanet.rawValue)-\(aspect.rawValue)-\(natalPlanet.rawValue)" }
    
    let transitPlanet: Planet       // The transiting planet
    let aspect: AspectType          // Type of aspect
    let natalPlanet: Planet         // The natal planet being aspected
    let orb: Double                 // How exact (0° = perfect)
    let isApplying: Bool            // Getting closer (stronger) vs separating
    
    var significance: TransitSignificance {
        // Saturn, Pluto, Neptune, Uranus transits are major
        if [.saturn, .uranus, .neptune, .pluto].contains(transitPlanet) {
            return .major
        }
        // Jupiter = moderate, inner planets = minor
        if transitPlanet == .jupiter { return .moderate }
        return .minor
    }
    
    var isPersonalPlanet: Bool {
        [.sun, .moon, .mercury, .venus, .mars].contains(natalPlanet)
    }
    
    // Human-readable description
    var displayDescription: String {
        let transitName = transitPlanet.displayName
        let aspectName = aspect.displayName
        let natalName = natalPlanet.displayName
        let applying = isApplying ? "(applying)" : "(separating)"
        return "\(transitName) \(aspectName) your \(natalName) \(applying)"
    }
}

// MARK: - Aspect Types (per spec: 5 major aspects)

enum AspectType: String, Codable, CaseIterable {
    case conjunction  // 0°  — merging, intensifying
    case sextile      // 60° — opportunity, flow
    case square        // 90° — tension, growth catalyst
    case trine        // 120° — harmony, ease
    case opposition   // 180° — awareness, balance needed
    
    var targetDegree: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }
    
    var orb: Double {
        // Standard orbs for transit aspects
        switch self {
        case .conjunction: return 8
        case .opposition: return 8
        case .square: return 7
        case .trine: return 7
        case .sextile: return 5
        }
    }
    
    var displayName: String {
        switch self {
        case .conjunction: return "conjunct"
        case .sextile: return "sextile"
        case .square: return "square"
        case .trine: return "trine"
        case .opposition: return "opposite"
        }
    }
    
    var symbol: String {
        switch self {
        case .conjunction: return "☌"
        case .sextile: return "⚹"
        case .square: return "□"
        case .trine: return "△"
        case .opposition: return "☍"
        }
    }
    
    var nature: String {
        switch self {
        case .conjunction: return "intense focus"
        case .sextile: return "opportunity"
        case .square: return "creative tension"
        case .trine: return "natural flow"
        case .opposition: return "awareness"
        }
    }
}

enum TransitSignificance: String, Codable {
    case major     // Outer planet transits (Saturn, Uranus, Neptune, Pluto)
    case moderate  // Jupiter transits
    case minor     // Inner planet transits (Sun, Moon, Mercury, Venus, Mars)
}

// MARK: - Transit Chart Calculator

class TransitChartCalculator {
    
    private let astrologyService = AstrologyService()
    
    /// Calculate current transits against a natal chart
    func calculateTransits(natalChart: NatalChartData) async throws -> TransitChart {
        
        // Get current planetary positions
        let now = Date()
        let currentPositions = try await getCurrentPositions()
        
        // Calculate aspects between current positions and natal positions
        var activeTransits: [TransitAspect] = []
        
        for transitPos in currentPositions {
            for natalPos in natalChart.planets {
                let aspects = findAspects(
                    transitPlanet: transitPos.planet,
                    transitDegree: transitPos.degree,
                    natalPlanet: natalPos.planet,
                    natalDegree: natalPos.degree
                )
                activeTransits.append(contentsOf: aspects)
            }
        }
        
        // Sort by significance and orb
        activeTransits.sort { a, b in
            if a.significance != b.significance {
                return a.significance.rawValue < b.significance.rawValue
            }
            return a.orb < b.orb
        }
        
        return TransitChart(
            generatedAt: now,
            currentPositions: currentPositions,
            activeTransits: activeTransits
        )
    }
    
    /// Get current planetary positions via local calculation
    /// (Ecliptic positions don't depend on observer location)
    private func getCurrentPositions() async throws -> [TransitPosition] {
        let now = Date()
        let natalData = try await astrologyService.calculateNatalChart(
            date: now,
            time: now,
            latitude: 0, // Ecliptic coordinates don't depend on location
            longitude: 0
        )
        
        return natalData.planets.map { pos in
            TransitPosition(
                planet: pos.planet,
                sign: pos.sign,
                degree: pos.degree,
                isRetrograde: pos.isRetrograde
            )
        }
    }
    
    /// Find all aspects between a transit planet and natal planet
    private func findAspects(
        transitPlanet: Planet,
        transitDegree: Double,
        natalPlanet: Planet,
        natalDegree: Double
    ) -> [TransitAspect] {
        
        var results: [TransitAspect] = []
        
        let angularDifference = abs(transitDegree - natalDegree)
        let normalized = min(angularDifference, 360 - angularDifference)
        
        for aspectType in AspectType.allCases {
            let diff = abs(normalized - aspectType.targetDegree)
            if diff <= aspectType.orb {
                // Determine if applying or separating
                let isApplying = transitDegree < natalDegree + aspectType.targetDegree
                
                results.append(TransitAspect(
                    transitPlanet: transitPlanet,
                    aspect: aspectType,
                    natalPlanet: natalPlanet,
                    orb: diff,
                    isApplying: isApplying
                ))
            }
        }
        
        return results
    }
}
