import Foundation

// MARK: - Astrology Calculation Service
// Primary: Swiss Ephemeris via Astrology-API.io (NASA JPL DE431 precision)
// Fallback: Local simplified formulas (for offline / no API key)

class AstrologyService {
    
    private let apiBaseURL = "https://api.astrology-api.io/api/v3"
    
    // MARK: - Calculate Natal Chart (API-First)
    
    /// Calculates a natal chart using the Astrology-API.io Swiss Ephemeris backend.
    /// Falls back to local simplified calculations if the API is unavailable.
    ///
    /// - Parameters:
    ///   - date: Birth date
    ///   - time: Birth time (optional)
    ///   - latitude: Birth latitude
    ///   - longitude: Birth longitude
    ///   - cityName: Birth city name (for API timezone resolution)
    ///   - countryCode: ISO country code (for API timezone resolution)
    func calculateNatalChart(
        date: Date,
        time: Date?,
        latitude: Double,
        longitude: Double,
        cityName: String? = nil,
        countryCode: String? = nil
    ) async throws -> NatalChartData {
        
        // Try API first for Swiss Ephemeris accuracy
        let apiKey = AppConfig.astrologyAPIKey
        if !apiKey.isEmpty, let city = cityName, let country = countryCode {
            do {
                return try await calculateViaAPI(
                    date: date, time: time,
                    cityName: city, countryCode: country,
                    apiKey: apiKey
                )
            } catch {
                print("⚠️ Astrology API failed, falling back to local: \(error.localizedDescription)")
            }
        }
        
        // Fallback: local simplified calculations
        return try calculateLocal(date: date, time: time, latitude: latitude, longitude: longitude)
    }
    
    // MARK: - API-Based Calculation (Swiss Ephemeris)
    
    private func calculateViaAPI(
        date: Date,
        time: Date?,
        cityName: String,
        countryCode: String,
        apiKey: String
    ) async throws -> NatalChartData {
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        var hour = 12 // Default noon if no birth time
        var minute = 0
        if let time = time {
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            hour = timeComponents.hour ?? 12
            minute = timeComponents.minute ?? 0
        }
        
        // Build request payload
        let payload: [String: Any] = [
            "subject": [
                "name": "Pearl User",
                "birth_data": [
                    "year": dateComponents.year!,
                    "month": dateComponents.month!,
                    "day": dateComponents.day!,
                    "hour": hour,
                    "minute": minute,
                    "city": cityName,
                    "country_code": countryCode
                ]
            ],
            "options": [
                "house_system": "P",              // Placidus
                "include_interpretations": false   // We use Pearl's Claude layer
            ]
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/charts/natal") else {
            throw AstrologyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AstrologyError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw AstrologyError.apiError(status: httpResponse.statusCode, message: body)
        }
        
        return try parseAPIResponse(data: data, hasBirthTime: time != nil)
    }
    
    // MARK: - Parse API Response
    
    private func parseAPIResponse(data: Data, hasBirthTime: Bool) throws -> NatalChartData {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chartData = json["data"] as? [String: Any] else {
            throw AstrologyError.parseError("Missing 'data' field in response")
        }
        
        // Parse planetary positions
        var planets: [PlanetaryPosition] = []
        
        if let planetsDict = chartData["planets"] as? [String: [String: Any]] {
            let planetMapping: [String: Planet] = [
                "Sun": .sun, "Moon": .moon, "Mercury": .mercury,
                "Venus": .venus, "Mars": .mars, "Jupiter": .jupiter,
                "Saturn": .saturn, "Uranus": .uranus, "Neptune": .neptune,
                "Pluto": .pluto, "North Node": .northNode,
                "True Node": .northNode, "Chiron": .chiron
            ]
            
            for (name, planetData) in planetsDict {
                guard let planet = planetMapping[name],
                      let degree = planetData["longitude"] as? Double ?? planetData["degree"] as? Double,
                      let signName = planetData["sign"] as? String else { continue }
                
                let sign = zodiacSignFromName(signName)
                let house = planetData["house"] as? Int
                let retrograde = planetData["is_retrograde"] as? Bool ?? false
                
                planets.append(PlanetaryPosition(
                    planet: planet,
                    sign: sign,
                    degree: degree,
                    house: house,
                    isRetrograde: retrograde
                ))
            }
        }
        
        // Ensure we have Sun and Moon at minimum
        guard planets.contains(where: { $0.planet == .sun }),
              planets.contains(where: { $0.planet == .moon }) else {
            throw AstrologyError.parseError("API response missing Sun or Moon data")
        }
        
        // Sort planets in standard order
        let planetOrder: [Planet] = [.sun, .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto, .northNode, .chiron]
        planets.sort { a, b in
            let ai = planetOrder.firstIndex(of: a.planet) ?? 99
            let bi = planetOrder.firstIndex(of: b.planet) ?? 99
            return ai < bi
        }
        
        // Parse houses
        var houses: [HousePosition]? = nil
        if hasBirthTime {
            if let housesData = chartData["houses"] as? [[String: Any]] {
                houses = housesData.compactMap { houseData in
                    guard let houseNum = houseData["house"] as? Int,
                          let degree = houseData["longitude"] as? Double ?? houseData["degree"] as? Double,
                          let signName = houseData["sign"] as? String else { return nil }
                    return HousePosition(house: houseNum, sign: zodiacSignFromName(signName), degree: degree)
                }
            } else if let housesDict = chartData["houses"] as? [String: [String: Any]] {
                // Alternative format: {"1": {...}, "2": {...}, ...}
                houses = (1...12).compactMap { i in
                    guard let houseData = housesDict["\(i)"],
                          let degree = houseData["longitude"] as? Double ?? houseData["degree"] as? Double,
                          let signName = houseData["sign"] as? String else { return nil }
                    return HousePosition(house: i, sign: zodiacSignFromName(signName), degree: degree)
                }
            }
            
            // Parse Ascendant from angles if houses are missing it
            if let angles = chartData["angles"] as? [String: [String: Any]],
               let asc = angles["Ascendant"],
               let ascDegree = asc["longitude"] as? Double ?? asc["degree"] as? Double,
               let ascSign = asc["sign"] as? String {
                // Replace or add house 1 cusp with proper Ascendant
                if houses != nil {
                    houses?.removeAll { $0.house == 1 }
                    houses?.insert(HousePosition(house: 1, sign: zodiacSignFromName(ascSign), degree: ascDegree), at: 0)
                } else {
                    // Build equal houses from Ascendant
                    houses = (1...12).map { i in
                        let cusp = normalizeAngle(ascDegree + Double(i - 1) * 30.0)
                        return HousePosition(house: i, sign: zodiacSign(for: cusp), degree: cusp)
                    }
                }
            }
        }
        
        // Parse aspects
        var aspects: [Aspect] = []
        if let aspectsData = chartData["aspects"] as? [[String: Any]] {
            let planetMapping: [String: Planet] = [
                "Sun": .sun, "Moon": .moon, "Mercury": .mercury,
                "Venus": .venus, "Mars": .mars, "Jupiter": .jupiter,
                "Saturn": .saturn, "Uranus": .uranus, "Neptune": .neptune,
                "Pluto": .pluto, "North Node": .northNode, "Chiron": .chiron
            ]
            let aspectMapping: [String: Aspect.AspectType] = [
                "conjunction": .conjunction, "Conjunction": .conjunction,
                "opposition": .opposition, "Opposition": .opposition,
                "trine": .trine, "Trine": .trine,
                "square": .square, "Square": .square,
                "sextile": .sextile, "Sextile": .sextile
            ]
            
            for aspectData in aspectsData {
                guard let p1Name = aspectData["planet1"] as? String ?? aspectData["from"] as? String,
                      let p2Name = aspectData["planet2"] as? String ?? aspectData["to"] as? String,
                      let typeName = aspectData["type"] as? String ?? aspectData["aspect"] as? String,
                      let p1 = planetMapping[p1Name],
                      let p2 = planetMapping[p2Name],
                      let type = aspectMapping[typeName] else { continue }
                
                let orb = aspectData["orb"] as? Double ?? 0.0
                aspects.append(Aspect(planet1: p1, planet2: p2, type: type, orb: orb))
            }
        }
        
        // If API didn't return aspects, calculate them locally
        if aspects.isEmpty {
            aspects = calculateAspects(planets: planets)
        }
        
        // Extract Big Three + MC
        let sunSign = planets.first(where: { $0.planet == .sun })!.sign
        let moonSign = planets.first(where: { $0.planet == .moon })!.sign
        let risingSign = houses?.first.map { $0.sign }
        
        // Midheaven from angles or house 10
        var mcSign: ZodiacSign? = nil
        if let angles = chartData["angles"] as? [String: [String: Any]],
           let mc = angles["Midheaven"] ?? angles["MC"],
           let mcSignName = mc["sign"] as? String {
            mcSign = zodiacSignFromName(mcSignName)
        } else if let h10 = houses?.first(where: { $0.house == 10 }) {
            mcSign = h10.sign
        }
        
        return NatalChartData(
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            midheavenSign: mcSign,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }
    
    // MARK: - Transit Report (for Morning Brief)
    
    func fetchCurrentTransits(
        date: Date,
        time: Date?,
        cityName: String,
        countryCode: String
    ) async throws -> [[String: Any]]? {
        let apiKey = AppConfig.astrologyAPIKey
        guard !apiKey.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var hour = 12
        var minute = 0
        if let time = time {
            let tc = calendar.dateComponents([.hour, .minute], from: time)
            hour = tc.hour ?? 12
            minute = tc.minute ?? 0
        }
        
        let payload: [String: Any] = [
            "subject": [
                "name": "Pearl User",
                "birth_data": [
                    "year": components.year!,
                    "month": components.month!,
                    "day": components.day!,
                    "hour": hour,
                    "minute": minute,
                    "city": cityName,
                    "country_code": countryCode
                ]
            ],
            "options": ["language": "en", "include_interpretations": true]
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/analysis/transit-report") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["data"] as? [[String: Any]] ?? json?["transits"] as? [[String: Any]]
    }
    
    // MARK: - Daily Horoscope (API)
    
    func fetchDailyHoroscope(
        date: Date,
        time: Date?,
        cityName: String,
        countryCode: String
    ) async throws -> [String: Any]? {
        let apiKey = AppConfig.astrologyAPIKey
        guard !apiKey.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var hour = 12
        var minute = 0
        if let time = time {
            let tc = calendar.dateComponents([.hour, .minute], from: time)
            hour = tc.hour ?? 12
            minute = tc.minute ?? 0
        }
        
        let payload: [String: Any] = [
            "subject": [
                "name": "Pearl User",
                "birth_data": [
                    "year": components.year!,
                    "month": components.month!,
                    "day": components.day!,
                    "hour": hour,
                    "minute": minute,
                    "city": cityName,
                    "country_code": countryCode
                ]
            ],
            "options": ["language": "en", "include_interpretations": true]
        ]
        
        guard let url = URL(string: "\(apiBaseURL)/horoscope/personal/daily") else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 15
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
    
    // MARK: - Local Fallback (Simplified Formulas)
    // ⚠️ Only used when API is unavailable. Accuracy is limited — especially Moon/Rising.
    
    private func calculateLocal(
        date: Date,
        time: Date?,
        latitude: Double,
        longitude: Double
    ) throws -> NatalChartData {
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        var hour = 12
        var minute = 0
        if let time = time {
            let tc = calendar.dateComponents([.hour, .minute], from: time)
            hour = tc.hour ?? 12
            minute = tc.minute ?? 0
        }
        
        let jd = calculateJulianDay(
            year: components.year!, month: components.month!,
            day: components.day!, hour: hour, minute: minute
        )
        
        let planets = calculatePlanetaryPositions(julianDay: jd)
        
        var houses: [HousePosition]? = nil
        if time != nil {
            houses = calculateHouses(julianDay: jd, latitude: latitude, longitude: longitude)
        }
        
        let aspects = calculateAspects(planets: planets)
        
        let sunSign = zodiacSign(for: planets.first(where: { $0.planet == .sun })!.degree)
        let moonSign = zodiacSign(for: planets.first(where: { $0.planet == .moon })!.degree)
        let risingSign = houses?.first.map { zodiacSign(for: $0.degree) }
        let mcSign = houses?.first(where: { $0.house == 10 }).map { zodiacSign(for: $0.degree) }
        
        return NatalChartData(
            sunSign: sunSign,
            moonSign: moonSign,
            risingSign: risingSign,
            midheavenSign: mcSign,
            planets: planets,
            houses: houses,
            aspects: aspects
        )
    }
    
    // MARK: - Julian Day
    
    private func calculateJulianDay(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Double {
        var y = Double(year)
        var m = Double(month)
        let d = Double(day) + Double(hour) / 24.0 + Double(minute) / 1440.0
        
        if m <= 2 { y -= 1; m += 12 }
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        
        return floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5
    }
    
    // MARK: - Planetary Positions (Simplified — Fallback Only)
    
    private func calculatePlanetaryPositions(julianDay: Double) -> [PlanetaryPosition] {
        let T = (julianDay - 2451545.0) / 36525.0
        var positions: [PlanetaryPosition] = []
        
        // Sun (VSOP87 simplified — accurate to ~0.01°)
        let L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T * T
        let M = 357.52911 + 35999.05029 * T - 0.0001537 * T * T
        let Mr = M.radians
        let C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mr)
            + (0.019993 - 0.000101 * T) * sin(2 * Mr)
            + 0.000289 * sin(3 * Mr)
        let sunLong = normalizeAngle(L0 + C)
        positions.append(PlanetaryPosition(planet: .sun, sign: zodiacSign(for: sunLong), degree: sunLong, house: nil, isRetrograde: false))
        
        // Moon (Brown / ELP2000 simplified — ~30 correction terms, ~0.3° accuracy)
        let Lm = normalizeAngle(218.3164477 + 481267.88123421 * T - 0.0015786 * T * T)
        let D = normalizeAngle(297.8501921 + 445267.1114034 * T - 0.0018819 * T * T)  // Mean elongation
        let Mp = normalizeAngle(134.9633964 + 477198.8675055 * T + 0.0087414 * T * T)  // Moon's mean anomaly
        let F = normalizeAngle(93.2720950 + 483202.0175233 * T - 0.0036539 * T * T)    // Moon's argument of latitude
        let omega = normalizeAngle(125.0445479 - 1934.1362891 * T + 0.0020754 * T * T) // Longitude of ascending node
        
        // Principal periodic terms for longitude (ELP2000 truncated)
        let Dr = D.radians, Mpr = Mp.radians, Fr = F.radians, omr = omega.radians
        let moonCorr =
              6.288774 * sin(Mpr)
            + 1.274027 * sin(2 * Dr - Mpr)
            + 0.658314 * sin(2 * Dr)
            + 0.213618 * sin(2 * Mpr)
            - 0.185116 * sin(Mr)           // Sun's mean anomaly correction
            - 0.114332 * sin(2 * Fr)
            + 0.058793 * sin(2 * Dr - 2 * Mpr)
            + 0.057066 * sin(2 * Dr - Mr - Mpr)
            + 0.053322 * sin(2 * Dr + Mpr)
            + 0.045758 * sin(2 * Dr - Mr)
            - 0.040923 * sin(Mr - Mpr)
            - 0.034720 * sin(Dr)
            - 0.030383 * sin(Mr + Mpr)
            + 0.015327 * sin(2 * Dr - 2 * Fr)
            - 0.012528 * sin(Mpr + 2 * Fr)
            + 0.010980 * sin(Mpr - 2 * Fr)
            + 0.010675 * sin(4 * Dr - Mpr)
            + 0.010034 * sin(3 * Mpr)
            + 0.008548 * sin(4 * Dr - 2 * Mpr)
            - 0.007888 * sin(2 * Dr + Mr - Mpr)
            - 0.006766 * sin(2 * Dr + Mr)
            - 0.005163 * sin(Dr - Mpr)
            + 0.004987 * sin(Dr + Mr)
            + 0.004036 * sin(2 * Dr - Mr + Mpr)
            + 0.003994 * sin(2 * Mpr + 2 * Dr)
            + 0.003861 * sin(4 * Dr)
            + 0.003665 * sin(2 * Dr - 3 * Mpr)
            - 0.002689 * sin(Mr - 2 * Mpr)
            - 0.002602 * sin(2 * Dr - Mpr + 2 * Fr)
            + 0.002390 * sin(2 * Dr - Mr - 2 * Mpr)
            - 0.002348 * sin(Dr + Mpr)
            + 0.002236 * sin(2 * Dr * 2)  // Higher order
            - 0.002120 * sin(Mr + 2 * Mpr)
        
        // Nutation correction
        let nutation = -0.00478 * sin(omr)
        
        let moonLong = normalizeAngle(Lm + moonCorr + nutation)
        positions.append(PlanetaryPosition(planet: .moon, sign: zodiacSign(for: moonLong), degree: moonLong, house: nil, isRetrograde: false))
        
        // Mercury (with equation of center)
        let mercM = normalizeAngle(174.7948 + 149472.5153 * T)
        let mercC2 = 23.4400 * sin(mercM.radians) + 2.9818 * sin(2 * mercM.radians)
        let mercLong = normalizeAngle(252.2509 + 149472.6747 * T - mercC2 * 0.1)  // Heliocentric → geocentric approximation
        positions.append(PlanetaryPosition(planet: .mercury, sign: zodiacSign(for: mercLong), degree: mercLong, house: nil, isRetrograde: false))
        
        // Venus
        let venM = normalizeAngle(50.4161 + 58517.8039 * T)
        let venC2 = 0.7758 * sin(venM.radians) + 0.0033 * sin(2 * venM.radians)
        let venLong = normalizeAngle(181.9798 + 58517.8157 * T + venC2)
        positions.append(PlanetaryPosition(planet: .venus, sign: zodiacSign(for: venLong), degree: venLong, house: nil, isRetrograde: false))
        
        // Mars
        let marsM = normalizeAngle(19.3730 + 19140.3023 * T)
        let marsC2 = 10.6912 * sin(marsM.radians) + 0.6228 * sin(2 * marsM.radians)
        let marsLong = normalizeAngle(355.4330 + 19140.2993 * T + marsC2 * 0.1)
        positions.append(PlanetaryPosition(planet: .mars, sign: zodiacSign(for: marsLong), degree: marsLong, house: nil, isRetrograde: false))
        
        // Outer planets — mean longitudes (sufficient for sign-level accuracy)
        let jupLong = normalizeAngle(34.3515 + 3034.9057 * T + 0.2225 * sin((225.4 + 2999.2 * T).radians))
        positions.append(PlanetaryPosition(planet: .jupiter, sign: zodiacSign(for: jupLong), degree: jupLong, house: nil, isRetrograde: false))
        
        let satLong = normalizeAngle(50.0774 + 1222.1138 * T + 0.1502 * sin((175.5 + 1221.6 * T).radians))
        positions.append(PlanetaryPosition(planet: .saturn, sign: zodiacSign(for: satLong), degree: satLong, house: nil, isRetrograde: false))
        
        let uraLong = normalizeAngle(314.055 + 428.947 * T + 0.0502 * sin((284.0 + 429.0 * T).radians))
        positions.append(PlanetaryPosition(planet: .uranus, sign: zodiacSign(for: uraLong), degree: uraLong, house: nil, isRetrograde: false))
        
        let nepLong = normalizeAngle(304.349 + 218.486 * T + 0.0131 * sin((37.2 + 218.5 * T).radians))
        positions.append(PlanetaryPosition(planet: .neptune, sign: zodiacSign(for: nepLong), degree: nepLong, house: nil, isRetrograde: false))
        
        let pluLong = normalizeAngle(238.929 + 145.178 * T + 0.0085 * sin((113.0 + 145.2 * T).radians))
        positions.append(PlanetaryPosition(planet: .pluto, sign: zodiacSign(for: pluLong), degree: pluLong, house: nil, isRetrograde: false))
        
        // North Node (mean)
        let nodeLong = normalizeAngle(125.0446 - 1934.1363 * T)
        positions.append(PlanetaryPosition(planet: .northNode, sign: zodiacSign(for: nodeLong), degree: nodeLong, house: nil, isRetrograde: true))
        
        return positions
    }
    
    // MARK: - House Calculation (Placidus Approximation — Fallback Only)
    
    private func calculateHouses(julianDay: Double, latitude: Double, longitude: Double) -> [HousePosition] {
        let T = (julianDay - 2451545.0) / 36525.0
        let gmst = normalizeAngle(280.46061837 + 360.98564736629 * (julianDay - 2451545.0) + 0.000387933 * T * T)
        let lst = normalizeAngle(gmst + longitude)
        let obliquity = (23.4393 - 0.0130 * T)
        
        // Ascendant
        let ascendant = normalizeAngle(
            atan2(
                cos(lst.radians),
                -(sin(obliquity.radians) * tan(latitude.radians) + cos(obliquity.radians) * sin(lst.radians))
            ).degrees
        )
        
        // MC (Midheaven)
        let mc = normalizeAngle(atan2(sin(lst.radians), cos(lst.radians) * cos(obliquity.radians)).degrees)
        
        // Placidus house cusps via semi-arc interpolation
        return placidusHouses(ascendant: ascendant, mc: mc, latitude: latitude, obliquity: obliquity)
    }
    
    private func placidusHouses(ascendant: Double, mc: Double, latitude: Double, obliquity: Double) -> [HousePosition] {
        // For Placidus, houses 2,3 and 11,12 are interpolated between IC-ASC and MC-ASC
        // For simplicity in fallback, we use semi-arc division
        let ic = normalizeAngle(mc + 180)
        
        // Semi-arc from IC to ASC (houses 1-3)
        let arcICtoASC = normalizeAngle(ascendant - ic)
        let cusp2 = normalizeAngle(ic + arcICtoASC * 2.0 / 3.0)
        let cusp3 = normalizeAngle(ic + arcICtoASC / 3.0)
        
        // Semi-arc from ASC to MC (houses 10-12)
        let arcASCtoMC = normalizeAngle(mc - ascendant)
        let cusp11 = normalizeAngle(ascendant + arcASCtoMC / 3.0)
        let cusp12 = normalizeAngle(ascendant + arcASCtoMC * 2.0 / 3.0)
        
        let cusps = [
            ascendant,                               // 1 (ASC)
            cusp2,                                   // 2
            cusp3,                                   // 3
            ic,                                      // 4 (IC)
            normalizeAngle(ic + arcICtoASC / 3.0 + 180), // 5
            normalizeAngle(cusp2 + 180),             // 6
            normalizeAngle(ascendant + 180),         // 7 (DSC)
            normalizeAngle(cusp2 + 180),             // 8
            normalizeAngle(cusp3 + 180),             // 9
            mc,                                      // 10 (MC)
            cusp11,                                  // 11
            cusp12                                   // 12
        ]
        
        return cusps.enumerated().map { (i, degree) in
            HousePosition(house: i + 1, sign: zodiacSign(for: degree), degree: degree)
        }
    }
    
    // MARK: - Aspect Calculation
    
    private func calculateAspects(planets: [PlanetaryPosition]) -> [Aspect] {
        var aspects: [Aspect] = []
        let aspectAngles: [(Aspect.AspectType, Double, Double)] = [
            (.conjunction, 0, 8), (.opposition, 180, 8),
            (.trine, 120, 6), (.square, 90, 6), (.sextile, 60, 4)
        ]
        
        for i in 0..<planets.count {
            for j in (i+1)..<planets.count {
                let angle = abs(planets[i].degree - planets[j].degree)
                let normalizedAngle = angle > 180 ? 360 - angle : angle
                
                for (type, targetAngle, maxOrb) in aspectAngles {
                    let orb = abs(normalizedAngle - targetAngle)
                    if orb <= maxOrb {
                        aspects.append(Aspect(planet1: planets[i].planet, planet2: planets[j].planet, type: type, orb: orb))
                    }
                }
            }
        }
        return aspects
    }
    
    // MARK: - Helpers
    
    func zodiacSign(for degree: Double) -> ZodiacSign {
        let normalized = normalizeAngle(degree)
        let signIndex = Int(normalized / 30.0)
        return ZodiacSign.allCases[signIndex % 12]
    }
    
    private func zodiacSignFromName(_ name: String) -> ZodiacSign {
        let lookup: [String: ZodiacSign] = [
            "aries": .aries, "taurus": .taurus, "gemini": .gemini,
            "cancer": .cancer, "leo": .leo, "virgo": .virgo,
            "libra": .libra, "scorpio": .scorpio, "sagittarius": .sagittarius,
            "capricorn": .capricorn, "aquarius": .aquarius, "pisces": .pisces
        ]
        return lookup[name.lowercased()] ?? .aries
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }
}

// MARK: - Errors

enum AstrologyError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(status: Int, message: String)
    case parseError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid API response"
        case .apiError(let status, let message): return "API error \(status): \(message)"
        case .parseError(let detail): return "Parse error: \(detail)"
        }
    }
}

// MARK: - Natal Chart Data

struct NatalChartData {
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let risingSign: ZodiacSign?
    let midheavenSign: ZodiacSign?    // MC — career direction, public role
    let planets: [PlanetaryPosition]
    let houses: [HousePosition]?
    let aspects: [Aspect]
}

// MARK: - Angle Extensions

private extension Double {
    var radians: Double { self * .pi / 180.0 }
    var degrees: Double { self * 180.0 / .pi }
}
