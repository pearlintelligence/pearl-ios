import Foundation

// MARK: - Human Design Type

enum HumanDesignType: String, Codable, CaseIterable {
    case generator = "Generator"
    case manifestingGenerator = "Manifesting Generator"
    case projector = "Projector"
    case manifestor = "Manifestor"
    case reflector = "Reflector"
}

// MARK: - Human Design Center

enum HDCenter: String, Codable, CaseIterable {
    case head, ajna, throat, g, heart, sacral, solarPlexus, spleen, root
    
    var displayName: String {
        switch self {
        case .head: return "Head"
        case .ajna: return "Ajna"
        case .throat: return "Throat"
        case .g: return "G Center"
        case .heart: return "Heart"
        case .sacral: return "Sacral"
        case .solarPlexus: return "Solar Plexus"
        case .spleen: return "Spleen"
        case .root: return "Root"
        }
    }
}

// MARK: - Human Design Service
// Calculates Human Design type, strategy, authority, profile from birth data

class HumanDesignService {
    
    // MARK: - Types
    
    // Human Design uses the I Ching hexagram system mapped to body graph gates
    // Full implementation requires ephemeris calculations for both personality (birth) 
    // and design (88 days before birth) positions
    
    struct HDCalculation {
        let type: HumanDesignType
        let strategy: String
        let authority: String
        let profile: String
        let definedCenters: [HDCenter]
        let undefinedCenters: [HDCenter]
    }
    
    // MARK: - Gate-Channel-Center Mapping
    
    // The 64 gates correspond to I Ching hexagrams
    // Channels connect two gates between two centers
    // When both gates of a channel are activated, the channel is "defined"
    // and both centers become "defined"
    
    struct Channel {
        let gate1: Int
        let gate2: Int
        let center1: HDCenter
        let center2: HDCenter
        let name: String
    }
    
    // The 36 channels of Human Design
    static let channels: [Channel] = [
        // Head to Ajna
        Channel(gate1: 64, gate2: 47, center1: .head, center2: .ajna, name: "Abstraction"),
        Channel(gate1: 61, gate2: 24, center1: .head, center2: .ajna, name: "Awareness"),
        Channel(gate1: 63, gate2: 4, center1: .head, center2: .ajna, name: "Logic"),
        
        // Ajna to Throat
        Channel(gate1: 17, gate2: 62, center1: .ajna, center2: .throat, name: "Acceptance"),
        Channel(gate1: 43, gate2: 23, center1: .ajna, center2: .throat, name: "Structuring"),
        Channel(gate1: 11, gate2: 56, center1: .ajna, center2: .throat, name: "Curiosity"),
        
        // Throat to G Center
        Channel(gate1: 31, gate2: 7, center1: .throat, center2: .g, name: "The Alpha"),
        Channel(gate1: 8, gate2: 1, center1: .throat, center2: .g, name: "Inspiration"),
        Channel(gate1: 33, gate2: 13, center1: .throat, center2: .g, name: "The Prodigal"),
        
        // Throat to others
        Channel(gate1: 20, gate2: 34, center1: .throat, center2: .sacral, name: "Charisma"),
        Channel(gate1: 20, gate2: 57, center1: .throat, center2: .spleen, name: "The Brainwave"),
        Channel(gate1: 16, gate2: 48, center1: .throat, center2: .spleen, name: "The Wavelength"),
        Channel(gate1: 12, gate2: 22, center1: .throat, center2: .solarPlexus, name: "Openness"),
        Channel(gate1: 35, gate2: 36, center1: .throat, center2: .solarPlexus, name: "Transitoriness"),
        Channel(gate1: 45, gate2: 21, center1: .throat, center2: .heart, name: "Money"),
        
        // G Center connections
        Channel(gate1: 10, gate2: 34, center1: .g, center2: .sacral, name: "Exploration"),
        Channel(gate1: 10, gate2: 57, center1: .g, center2: .spleen, name: "Perfected Form"),
        Channel(gate1: 15, gate2: 5, center1: .g, center2: .sacral, name: "Rhythm"),
        Channel(gate1: 46, gate2: 29, center1: .g, center2: .sacral, name: "Discovery"),
        Channel(gate1: 2, gate2: 14, center1: .g, center2: .sacral, name: "The Beat"),
        Channel(gate1: 25, gate2: 51, center1: .g, center2: .heart, name: "Initiation"),
        
        // Heart connections
        Channel(gate1: 26, gate2: 44, center1: .heart, center2: .spleen, name: "Surrender"),
        Channel(gate1: 40, gate2: 37, center1: .heart, center2: .solarPlexus, name: "Community"),
        
        // Sacral connections
        Channel(gate1: 59, gate2: 6, center1: .sacral, center2: .solarPlexus, name: "Intimacy"),
        Channel(gate1: 27, gate2: 50, center1: .sacral, center2: .spleen, name: "Preservation"),
        Channel(gate1: 34, gate2: 57, center1: .sacral, center2: .spleen, name: "Power"),
        Channel(gate1: 3, gate2: 60, center1: .sacral, center2: .root, name: "Mutation"),
        Channel(gate1: 42, gate2: 53, center1: .sacral, center2: .root, name: "Maturation"),
        Channel(gate1: 9, gate2: 52, center1: .sacral, center2: .root, name: "Concentration"),
        
        // Spleen connections
        Channel(gate1: 28, gate2: 38, center1: .spleen, center2: .root, name: "Struggle"),
        Channel(gate1: 18, gate2: 58, center1: .spleen, center2: .root, name: "Judgment"),
        Channel(gate1: 32, gate2: 54, center1: .spleen, center2: .root, name: "Transformation"),
        
        // Solar Plexus connections
        Channel(gate1: 30, gate2: 41, center1: .solarPlexus, center2: .root, name: "Recognition"),
        Channel(gate1: 55, gate2: 39, center1: .solarPlexus, center2: .root, name: "Emoting"),
        Channel(gate1: 49, gate2: 19, center1: .solarPlexus, center2: .root, name: "Synthesis"),
    ]
    
    // MARK: - Calculate HD Profile
    
    func calculate(
        birthDate: Date,
        birthTime: Date?,
        latitude: Double,
        longitude: Double
    ) async -> HDCalculation {
        // Full HD calculation requires:
        // 1. Personality Sun/Earth positions at birth → gates
        // 2. Design Sun/Earth positions 88° before birth → gates
        // 3. All planetary gates for both personality and design
        // 4. Check which channels are defined
        // 5. Determine type from defined centers
        
        // For MVP, we use a simplified calculation based on birth date
        // Full Swiss Ephemeris integration needed for production
        
        let personalityGates = calculatePersonalityGates(date: birthDate)
        let designGates = calculateDesignGates(date: birthDate)
        let allGates = Set(personalityGates + designGates)
        
        let definedChannels = Self.channels.filter { channel in
            allGates.contains(channel.gate1) && allGates.contains(channel.gate2)
        }
        
        let definedCenters = Set(definedChannels.flatMap { [$0.center1, $0.center2] })
        let allCenters: Set<HDCenter> = [.head, .ajna, .throat, .g, .heart, .sacral, .spleen, .solarPlexus, .root]
        let undefinedCenters = allCenters.subtracting(definedCenters)
        
        let type = determineType(defined: definedCenters)
        let strategy = type.strategy
        let authority = determineAuthority(defined: definedCenters)
        let profile = calculateProfile(date: birthDate)
        
        return HDCalculation(
            type: type,
            strategy: strategy,
            authority: authority,
            profile: profile,
            definedCenters: Array(definedCenters).sorted { $0.rawValue < $1.rawValue },
            undefinedCenters: Array(undefinedCenters).sorted { $0.rawValue < $1.rawValue }
        )
    }
    
    // MARK: - Gate Calculations (Simplified)
    
    private func calculatePersonalityGates(date: Date) -> [Int] {
        // Simplified: Map Sun longitude to gate
        // In production, calculate all 13 planetary positions
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let sunLongitude = Double(dayOfYear) / 365.25 * 360.0
        
        // Map longitude to gate (64 gates over 360°)
        let gateOrder = [41,19,13,49,30,55,37,63,22,36,25,17,21,51,42,3,27,24,2,23,8,20,16,35,45,12,15,52,39,53,62,56,31,33,7,4,29,59,40,64,47,6,46,18,48,57,32,50,28,44,1,43,14,34,9,5,26,11,10,58,38,54,61,60]
        
        let gateIndex = Int(sunLongitude / 5.625) % 64
        let sunGate = gateOrder[gateIndex]
        
        // Earth is always opposite Sun
        let earthIndex = (gateIndex + 32) % 64
        let earthGate = gateOrder[earthIndex]
        
        // Add some variety based on month/day for other planets
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        
        var gates = [sunGate, earthGate]
        gates.append(gateOrder[(month * 5 + day) % 64])
        gates.append(gateOrder[(month * 3 + day * 2) % 64])
        gates.append(gateOrder[(day * 7) % 64])
        
        return gates
    }
    
    private func calculateDesignGates(date: Date) -> [Int] {
        // Design calculation: ~88 days before birth
        let designDate = Calendar.current.date(byAdding: .day, value: -88, to: date) ?? date
        return calculatePersonalityGates(date: designDate)
    }
    
    // MARK: - Type Determination
    
    private func determineType(defined: Set<HDCenter>) -> HumanDesignType {
        let hasSacral = defined.contains(.sacral)
        let hasMotorToThroat = defined.contains(.throat) && 
            (defined.contains(.heart) || defined.contains(.solarPlexus) || defined.contains(.root))
        
        if hasSacral && hasMotorToThroat {
            return .manifestingGenerator
        } else if hasSacral {
            return .generator
        } else if hasMotorToThroat {
            return .manifestor
        } else if defined.count >= 2 {
            return .projector
        } else {
            return .reflector
        }
    }
    
    // MARK: - Authority Determination
    
    private func determineAuthority(defined: Set<HDCenter>) -> String {
        if defined.contains(.solarPlexus) { return "Emotional (Solar Plexus)" }
        if defined.contains(.sacral) { return "Sacral" }
        if defined.contains(.spleen) { return "Splenic" }
        if defined.contains(.heart) { return "Ego/Heart" }
        if defined.contains(.g) { return "Self-Projected" }
        if defined.contains(.ajna) { return "Mental (Environment)" }
        return "Lunar (Outer Authority)"
    }
    
    // MARK: - Profile Calculation
    
    private func calculateProfile(date: Date) -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        
        // Simplified profile from Sun gate line
        let personalityLine = ((day + month) % 6) + 1
        let designLine = ((day * 2 + month) % 6) + 1
        
        return "\(personalityLine)/\(designLine)"
    }
}

// MARK: - Human Design Type Extension

extension HumanDesignType {
    var strategy: String {
        switch self {
        case .manifestor: return "Inform Before Acting"
        case .generator: return "Wait to Respond"
        case .manifestingGenerator: return "Wait to Respond, Then Inform"
        case .projector: return "Wait for the Invitation"
        case .reflector: return "Wait a Lunar Cycle"
        }
    }
    
    var description: String {
        switch self {
        case .manifestor:
            return "You are here to initiate. Your energy creates impact and opens doors others cannot. The world moves when you do."
        case .generator:
            return "You are the life force of the world. Your sacral response guides you to what truly lights you up — follow it, and your energy becomes unstoppable."
        case .manifestingGenerator:
            return "You carry both the power to initiate and the sustained energy to build. You are meant to explore many paths — your efficiency comes from following your response."
        case .projector:
            return "You see what others cannot. Your gift is guiding and directing energy, but only when recognized and invited. Your wisdom is your superpower."
        case .reflector:
            return "You are a mirror for the world. Your openness allows you to sample all of life's possibilities. The lunar cycle is your compass."
        }
    }
}
