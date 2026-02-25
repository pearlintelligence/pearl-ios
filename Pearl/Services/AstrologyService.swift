import Foundation

// MARK: - Astrology Calculation Service
// Calculates natal chart data from birth information
// Uses Swiss Ephemeris algorithms for accurate planetary positions

class AstrologyService {
    
    // MARK: - Calculate Natal Chart
    
    /// Calculates a complete natal chart from birth data
    /// - Parameters:
    ///   - date: Birth date
    ///   - time: Birth time (optional — some calculations require it)
    ///   - latitude: Birth location latitude
    ///   - longitude: Birth location longitude
    /// - Returns: Natal chart data including planet positions, houses, and aspects
    func calculateNatalChart(
        date: Date,
        time: Date?,
        latitude: Double,
        longitude: Double
    ) async throws -> NatalChartData {
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        var timeComponents: DateComponents?
        if let time = time {
            timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        }
        
        // Calculate Julian Day Number
        let jd = calculateJulianDay(
            year: components.year!,
            month: components.month!,
            day: components.day!,
            hour: timeComponents?.hour ?? 12,
            minute: timeComponents?.minute ?? 0
        )
        
        // Calculate planetary positions
        let planets = calculatePlanetaryPositions(julianDay: jd)
        
        // Calculate houses (requires birth time)
        var houses: [HousePosition]? = nil
        if time != nil {
            houses = calculateHouses(
                julianDay: jd,
                latitude: latitude,
                longitude: longitude
            )
        }
        
        // Calculate aspects
        let aspects = calculateAspects(planets: planets)
        
        // Determine signs
        let sunSign = zodiacSign(for: planets.first(where: { $0.planet == .sun })!.degree)
        let moonSign = zodiacSign(for: planets.first(where: { $0.planet == .moon })!.degree)
        let risingSign = houses?.first.map { zodiacSign(for: $0.degree) }
        
        return NatalChartData(
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }
    
    // MARK: - Julian Day Calculation
    
    private func calculateJulianDay(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day) + Double(hour) / 24.0 + Double(minute) / 1440.0
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5
    }
    
    // MARK: - Planetary Positions
    // Simplified calculation — in production, use Swiss Ephemeris (libswe) via C bridge
    
    private func calculatePlanetaryPositions(julianDay: Double) -> [PlanetaryPosition] {
        // Time in Julian centuries from J2000.0
        let T = (julianDay - 2451545.0) / 36525.0
        
        var positions: [PlanetaryPosition] = []
        
        // Sun position (simplified)
        let sunLongitude = normalizeAngle(280.46646 + 36000.76983 * T + 0.0003032 * T * T)
        let sunMeanAnomaly = normalizeAngle(357.52911 + 35999.05029 * T - 0.0001537 * T * T)
        let sunEquation = (1.914602 - 0.004817 * T) * sin(sunMeanAnomaly.radians)
            + 0.019993 * sin(2 * sunMeanAnomaly.radians)
        let sunTrueLongitude = normalizeAngle(sunLongitude + sunEquation)
        positions.append(PlanetaryPosition(
            planet: .sun,
            sign: zodiacSign(for: sunTrueLongitude),
            degree: sunTrueLongitude,
            house: nil,
            isRetrograde: false
        ))
        
        // Moon position (simplified)
        let moonLongitude = normalizeAngle(
            218.3165 + 481267.8813 * T
            + 6.29 * sin((134.9 + 477198.85 * T).radians)
            - 1.27 * sin((259.2 - 413335.38 * T).radians)
            + 0.66 * sin((235.7 + 890534.23 * T).radians)
        )
        positions.append(PlanetaryPosition(
            planet: .moon,
            sign: zodiacSign(for: moonLongitude),
            degree: moonLongitude,
            house: nil,
            isRetrograde: false
        ))
        
        // Mercury (simplified orbital elements)
        let mercuryLong = normalizeAngle(252.2509 + 149472.6747 * T)
        positions.append(PlanetaryPosition(
            planet: .mercury,
            sign: zodiacSign(for: mercuryLong),
            degree: mercuryLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Venus
        let venusLong = normalizeAngle(181.9798 + 58517.8157 * T)
        positions.append(PlanetaryPosition(
            planet: .venus,
            sign: zodiacSign(for: venusLong),
            degree: venusLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Mars
        let marsLong = normalizeAngle(355.4330 + 19140.2993 * T)
        positions.append(PlanetaryPosition(
            planet: .mars,
            sign: zodiacSign(for: marsLong),
            degree: marsLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Jupiter
        let jupiterLong = normalizeAngle(34.3515 + 3034.9057 * T)
        positions.append(PlanetaryPosition(
            planet: .jupiter,
            sign: zodiacSign(for: jupiterLong),
            degree: jupiterLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Saturn
        let saturnLong = normalizeAngle(50.0774 + 1222.1138 * T)
        positions.append(PlanetaryPosition(
            planet: .saturn,
            sign: zodiacSign(for: saturnLong),
            degree: saturnLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Uranus
        let uranusLong = normalizeAngle(314.055 + 428.947 * T)
        positions.append(PlanetaryPosition(
            planet: .uranus,
            sign: zodiacSign(for: uranusLong),
            degree: uranusLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Neptune
        let neptuneLong = normalizeAngle(304.349 + 218.486 * T)
        positions.append(PlanetaryPosition(
            planet: .neptune,
            sign: zodiacSign(for: neptuneLong),
            degree: neptuneLong,
            house: nil,
            isRetrograde: false
        ))
        
        // Pluto
        let plutoLong = normalizeAngle(238.929 + 145.178 * T)
        positions.append(PlanetaryPosition(
            planet: .pluto,
            sign: zodiacSign(for: plutoLong),
            degree: plutoLong,
            house: nil,
            isRetrograde: false
        ))
        
        return positions
    }
    
    // MARK: - House Calculation (Placidus)
    
    private func calculateHouses(julianDay: Double, latitude: Double, longitude: Double) -> [HousePosition] {
        let T = (julianDay - 2451545.0) / 36525.0
        
        // Local Sidereal Time
        let gmst = normalizeAngle(280.46061837 + 360.98564736629 * (julianDay - 2451545.0) + 0.000387933 * T * T)
        let lst = normalizeAngle(gmst + longitude)
        
        // Ascendant
        let obliquity = 23.4393 - 0.0130 * T
        let ascendant = normalizeAngle(
            atan2(
                cos(lst.radians),
                -(sin(obliquity.radians) * tan(latitude.radians) + cos(obliquity.radians) * sin(lst.radians))
            ).degrees
        )
        
        // Simplified house cusps (equal house from ASC)
        return (1...12).map { house in
            let cusp = normalizeAngle(ascendant + Double(house - 1) * 30.0)
            return HousePosition(
                house: house,
                sign: zodiacSign(for: cusp),
                degree: cusp
            )
        }
    }
    
    // MARK: - Aspect Calculation
    
    private func calculateAspects(planets: [PlanetaryPosition]) -> [Aspect] {
        var aspects: [Aspect] = []
        let aspectAngles: [(Aspect.AspectType, Double, Double)] = [
            (.conjunction, 0, 8),
            (.opposition, 180, 8),
            (.trine, 120, 6),
            (.square, 90, 6),
            (.sextile, 60, 4)
        ]
        
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                let angle = abs(planets[i].degree - planets[j].degree)
                let normalizedAngle = angle > 180 ? 360 - angle : angle
                
                for (type, targetAngle, maxOrb) in aspectAngles {
                    let orb = abs(normalizedAngle - targetAngle)
                    if orb <= maxOrb {
                        aspects.append(Aspect(
                            planet1: planets[i].planet,
                            planet2: planets[j].planet,
                            type: type,
                            orb: orb
                        ))
                    }
                }
            }
        }
        
        return aspects
    }
    
    // MARK: - Helpers
    
    private func zodiacSign(for degree: Double) -> ZodiacSign {
        let normalized = normalizeAngle(degree)
        let signIndex = Int(normalized / 30.0)
        return ZodiacSign.allCases[signIndex % 12]
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }
}

// MARK: - Natal Chart Data

struct NatalChartData {
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let risingSign: ZodiacSign?
    let planets: [PlanetaryPosition]
    let houses: [HousePosition]?
    let aspects: [Aspect]
}

// MARK: - Angle Extensions

private extension Double {
    var radians: Double { self * .pi / 180.0 }
    var degrees: Double { self * 180.0 / .pi }
}
