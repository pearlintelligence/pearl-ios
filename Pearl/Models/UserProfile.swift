import Foundation
import SwiftData

// MARK: - User Profile

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var email: String?
    
    // Birth data
    var birthDate: Date
    var birthTime: Date?
    var birthLatitude: Double
    var birthLongitude: Double
    var birthLocationName: String
    var hasBirthTime: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var isPremium: Bool
    
    init(
        name: String,
        email: String? = nil,
        birthDate: Date,
        birthTime: Date? = nil,
        birthLatitude: Double,
        birthLongitude: Double,
        birthLocationName: String,
        hasBirthTime: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthLatitude = birthLatitude
        self.birthLongitude = birthLongitude
        self.birthLocationName = birthLocationName
        self.hasBirthTime = hasBirthTime
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPremium = false
    }
}

// MARK: - Cosmic Blueprint

struct CosmicBlueprint: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let generatedAt: Date
    
    // Astrology
    let sunSign: ZodiacSign
    let moonSign: ZodiacSign
    let risingSign: ZodiacSign?
    let planetaryPositions: [PlanetaryPosition]
    let houses: [HousePosition]?
    let aspects: [Aspect]
    
    // Human Design
    let humanDesign: HumanDesignProfile
    
    // Numerology
    let numerology: NumerologyProfile
    
    // Pearl's synthesis
    let pearlSummary: String
    let coreThemes: [String]
    let lifePurpose: String
}

// MARK: - Astrology Models

enum ZodiacSign: String, Codable, CaseIterable {
    case aries, taurus, gemini, cancer, leo, virgo
    case libra, scorpio, sagittarius, capricorn, aquarius, pisces
    
    var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }
    
    enum Element: String, Codable {
        case fire, earth, air, water
        
        var color: String {
            switch self {
            case .fire: return "EF4444"
            case .earth: return "22C55E"
            case .air: return "60A5FA"
            case .water: return "8B5CF6"
            }
        }
    }
}

enum Planet: String, Codable, CaseIterable {
    case sun, moon, mercury, venus, mars
    case jupiter, saturn, uranus, neptune, pluto
    case northNode, chiron
    
    var symbol: String {
        switch self {
        case .sun: return "☉"
        case .moon: return "☽"
        case .mercury: return "☿"
        case .venus: return "♀"
        case .mars: return "♂"
        case .jupiter: return "♃"
        case .saturn: return "♄"
        case .uranus: return "♅"
        case .neptune: return "♆"
        case .pluto: return "♇"
        case .northNode: return "☊"
        case .chiron: return "⚷"
        }
    }
    
    var displayName: String {
        switch self {
        case .northNode: return "North Node"
        default: return rawValue.capitalized
        }
    }
}

struct PlanetaryPosition: Codable, Identifiable {
    var id: String { "\(planet.rawValue)-\(sign.rawValue)" }
    let planet: Planet
    let sign: ZodiacSign
    let degree: Double
    let house: Int?
    let isRetrograde: Bool
}

struct HousePosition: Codable, Identifiable {
    var id: Int { house }
    let house: Int
    let sign: ZodiacSign
    let degree: Double
}

struct Aspect: Codable, Identifiable {
    var id: String { "\(planet1.rawValue)-\(type.rawValue)-\(planet2.rawValue)" }
    let planet1: Planet
    let planet2: Planet
    let type: AspectType
    let orb: Double
    
    enum AspectType: String, Codable {
        case conjunction, opposition, trine, square, sextile
        
        var symbol: String {
            switch self {
            case .conjunction: return "☌"
            case .opposition: return "☍"
            case .trine: return "△"
            case .square: return "□"
            case .sextile: return "⚹"
            }
        }
    }
}

// MARK: - Human Design Models

struct HumanDesignProfile: Codable {
    let type: HumanDesignType
    let strategy: String
    let authority: String
    let profile: String
    let definedCenters: [HDCenter]
    let undefinedCenters: [HDCenter]
}

// MARK: - Numerology Models

struct NumerologyProfile: Codable {
    let lifePath: Int
    let lifePathDescription: String
    let expressionNumber: Int?
    let soulUrgeNumber: Int?
}
