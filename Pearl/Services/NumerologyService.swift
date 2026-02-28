import Foundation

// MARK: - Numerology Service
// Comprehensive numerology calculations from birth date and name

class NumerologyService {
    
    // MARK: - Full Numerology Profile
    
    struct FullNumerologyProfile: Codable {
        let lifePath: NumerologyNumber
        let expression: NumerologyNumber
        let soulUrge: NumerologyNumber
        let personality: NumerologyNumber
        let birthday: NumerologyNumber
        let personalYear: Int
        let personalYearTheme: String
        let pinnacles: [Pinnacle]
        let challenges: [Challenge]
    }
    
    struct NumerologyNumber: Codable, Identifiable {
        var id: String { "\(type)-\(value)" }
        let type: String
        let value: Int
        let isMasterNumber: Bool
        let meaning: String
        let keywords: [String]
    }
    
    struct Pinnacle: Codable, Identifiable {
        var id: Int { period }
        let period: Int
        let number: Int
        let meaning: String
        let startAge: Int
        let endAge: Int?
    }
    
    struct Challenge: Codable, Identifiable {
        var id: Int { period }
        let period: Int
        let number: Int
        let meaning: String
    }
    
    // MARK: - Calculate Full Profile
    
    func calculateProfile(birthDate: Date, fullName: String) -> FullNumerologyProfile {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate)
        let day = components.day!
        let month = components.month!
        let year = components.year!
        
        let lifePath = calculateLifePath(day: day, month: month, year: year)
        let expression = calculateExpression(name: fullName)
        let soulUrge = calculateSoulUrge(name: fullName)
        let personality = calculatePersonality(name: fullName)
        let birthday = calculateBirthday(day: day)
        let personalYear = calculatePersonalYear(day: day, month: month)
        let pinnacles = calculatePinnacles(lifePath: lifePath.value, day: day, month: month, year: year)
        let challenges = calculateChallenges(day: day, month: month, year: year)
        
        return FullNumerologyProfile(
            lifePath: lifePath,
            expression: expression,
            soulUrge: soulUrge,
            personality: personality,
            birthday: birthday,
            personalYear: personalYear,
            personalYearTheme: personalYearTheme(personalYear),
            pinnacles: pinnacles,
            challenges: challenges
        )
    }
    
    // MARK: - Life Path
    
    func calculateLifePath(day: Int, month: Int, year: Int) -> NumerologyNumber {
        let monthReduced = reduceToSingle(month)
        let dayReduced = reduceToSingle(day)
        let yearReduced = reduceToSingle(year)
        let total = reduceToSingle(monthReduced + dayReduced + yearReduced)
        
        return NumerologyNumber(
            type: "Life Path",
            value: total,
            isMasterNumber: [11, 22, 33].contains(total),
            meaning: lifePathMeaning(total),
            keywords: lifePathKeywords(total)
        )
    }
    
    // MARK: - Expression Number (from full name)
    
    func calculateExpression(name: String) -> NumerologyNumber {
        let value = reduceToSingle(letterSum(name))
        return NumerologyNumber(
            type: "Expression",
            value: value,
            isMasterNumber: [11, 22, 33].contains(value),
            meaning: expressionMeaning(value),
            keywords: expressionKeywords(value)
        )
    }
    
    // MARK: - Soul Urge (vowels only)
    
    func calculateSoulUrge(name: String) -> NumerologyNumber {
        let vowels = "aeiou"
        let vowelSum = name.lowercased().compactMap { char -> Int? in
            guard vowels.contains(char) else { return nil }
            return letterValue(char)
        }.reduce(0, +)
        let value = reduceToSingle(vowelSum)
        
        return NumerologyNumber(
            type: "Soul Urge",
            value: value,
            isMasterNumber: [11, 22, 33].contains(value),
            meaning: soulUrgeMeaning(value),
            keywords: soulUrgeKeywords(value)
        )
    }
    
    // MARK: - Personality Number (consonants only)
    
    func calculatePersonality(name: String) -> NumerologyNumber {
        let vowels = "aeiou"
        let consonantSum = name.lowercased().compactMap { char -> Int? in
            guard char.isLetter, !vowels.contains(char) else { return nil }
            return letterValue(char)
        }.reduce(0, +)
        let value = reduceToSingle(consonantSum)
        
        return NumerologyNumber(
            type: "Personality",
            value: value,
            isMasterNumber: [11, 22, 33].contains(value),
            meaning: personalityMeaning(value),
            keywords: personalityKeywords(value)
        )
    }
    
    // MARK: - Birthday Number
    
    func calculateBirthday(day: Int) -> NumerologyNumber {
        let value = reduceToSingle(day)
        return NumerologyNumber(
            type: "Birthday",
            value: value,
            isMasterNumber: false,
            meaning: birthdayMeaning(value),
            keywords: birthdayKeywords(value)
        )
    }
    
    // MARK: - Personal Year
    
    func calculatePersonalYear(day: Int, month: Int) -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return reduceToSingle(day + month + reduceToSingle(currentYear))
    }
    
    // MARK: - Pinnacles
    
    func calculatePinnacles(lifePath: Int, day: Int, month: Int, year: Int) -> [Pinnacle] {
        let monthR = reduceToSingle(month)
        let dayR = reduceToSingle(day)
        let yearR = reduceToSingle(year)
        
        let firstEnd = 36 - lifePath
        
        return [
            Pinnacle(period: 1, number: reduceToSingle(monthR + dayR), meaning: pinnacleMeaning(reduceToSingle(monthR + dayR)), startAge: 0, endAge: firstEnd),
            Pinnacle(period: 2, number: reduceToSingle(dayR + yearR), meaning: pinnacleMeaning(reduceToSingle(dayR + yearR)), startAge: firstEnd + 1, endAge: firstEnd + 9),
            Pinnacle(period: 3, number: reduceToSingle(reduceToSingle(monthR + dayR) + reduceToSingle(dayR + yearR)), meaning: pinnacleMeaning(reduceToSingle(reduceToSingle(monthR + dayR) + reduceToSingle(dayR + yearR))), startAge: firstEnd + 10, endAge: firstEnd + 18),
            Pinnacle(period: 4, number: reduceToSingle(monthR + yearR), meaning: pinnacleMeaning(reduceToSingle(monthR + yearR)), startAge: firstEnd + 19, endAge: nil),
        ]
    }
    
    // MARK: - Challenges
    
    func calculateChallenges(day: Int, month: Int, year: Int) -> [Challenge] {
        let monthR = reduceToSingle(month)
        let dayR = reduceToSingle(day)
        let yearR = reduceToSingle(year)
        
        let first = abs(monthR - dayR)
        let second = abs(dayR - yearR)
        let third = abs(first - second)
        let fourth = abs(monthR - yearR)
        
        return [
            Challenge(period: 1, number: first, meaning: challengeMeaning(first)),
            Challenge(period: 2, number: second, meaning: challengeMeaning(second)),
            Challenge(period: 3, number: third, meaning: challengeMeaning(third)),
            Challenge(period: 4, number: fourth, meaning: challengeMeaning(fourth)),
        ]
    }
    
    // MARK: - Helpers
    
    private func reduceToSingle(_ n: Int) -> Int {
        var num = abs(n)
        while num > 9 && num != 11 && num != 22 && num != 33 {
            num = String(num).compactMap { $0.wholeNumberValue }.reduce(0, +)
        }
        return num
    }
    
    private func letterValue(_ char: Character) -> Int {
        let values: [Character: Int] = [
            "a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6, "g": 7, "h": 8, "i": 9,
            "j": 1, "k": 2, "l": 3, "m": 4, "n": 5, "o": 6, "p": 7, "q": 8, "r": 9,
            "s": 1, "t": 2, "u": 3, "v": 4, "w": 5, "x": 6, "y": 7, "z": 8
        ]
        return values[char] ?? 0
    }
    
    private func letterSum(_ name: String) -> Int {
        name.lowercased().compactMap { letterValue($0) == 0 ? nil : letterValue($0) }.reduce(0, +)
    }
    
    // MARK: - Meaning Data
    
    private func lifePathMeaning(_ n: Int) -> String {
        let meanings: [Int: String] = [
            1: "The Leader — You are here to pioneer, to be original, to forge your own path. Independence and self-reliance define your journey.",
            2: "The Peacemaker — You are here to cooperate, to bring balance, to weave harmony from discord. Sensitivity is your superpower.",
            3: "The Creator — You are here to express, to create, to uplift through joy and communication. Your words and art carry light.",
            4: "The Builder — You are here to create lasting foundations. Stability, discipline, and dedication turn your visions into reality.",
            5: "The Adventurer — You are here to experience freedom in all its forms. Change is not your enemy — it is your element.",
            6: "The Nurturer — You are here to love deeply, to care for others, and to create beauty and harmony in the world around you.",
            7: "The Seeker — You are here to go deep, to question, to seek the truth beneath all surfaces. Solitude feeds your wisdom.",
            8: "The Powerhouse — You are here to master the material world. Abundance, authority, and achievement flow when you align with purpose.",
            9: "The Humanitarian — You are here to serve the world with compassion. Your life carries a universal quality — you are meant for everyone.",
            11: "The Intuitive Master — A master number carrying the vibration of spiritual insight and inspiration. You illuminate the path for others.",
            22: "The Master Builder — A master number carrying the power to manifest grand visions into physical reality. You build cathedrals.",
            33: "The Master Teacher — The highest master number. You embody unconditional love and spiritual upliftment. Your very presence heals.",
        ]
        return meanings[n] ?? meanings[reduceToSingle(n)] ?? "A unique numerological signature."
    }
    
    private func lifePathKeywords(_ n: Int) -> [String] {
        let keywords: [Int: [String]] = [
            1: ["Leadership", "Independence", "Innovation", "Courage"],
            2: ["Diplomacy", "Sensitivity", "Partnership", "Balance"],
            3: ["Creativity", "Expression", "Joy", "Communication"],
            4: ["Stability", "Foundation", "Discipline", "Dedication"],
            5: ["Freedom", "Adventure", "Change", "Versatility"],
            6: ["Love", "Nurturing", "Responsibility", "Beauty"],
            7: ["Wisdom", "Introspection", "Spirituality", "Analysis"],
            8: ["Abundance", "Power", "Achievement", "Authority"],
            9: ["Compassion", "Humanitarianism", "Wisdom", "Completion"],
            11: ["Intuition", "Illumination", "Inspiration", "Mastery"],
            22: ["Vision", "Manifestation", "Legacy", "Architecture"],
            33: ["Healing", "Teaching", "Unconditional Love", "Service"],
        ]
        return keywords[n] ?? keywords[reduceToSingle(n)] ?? ["Unique", "Special"]
    }
    
    private func expressionMeaning(_ n: Int) -> String {
        let base: [Int: String] = [
            1: "You express yourself through leadership and originality.",
            2: "You express yourself through cooperation and sensitivity.",
            3: "You express yourself through creativity and communication.",
            4: "You express yourself through structure and reliability.",
            5: "You express yourself through versatility and freedom.",
            6: "You express yourself through love and responsibility.",
            7: "You express yourself through wisdom and depth.",
            8: "You express yourself through achievement and mastery.",
            9: "You express yourself through compassion and vision.",
        ]
        return base[n > 9 ? reduceToSingle(n) : n] ?? "Your expression carries a unique signature."
    }
    
    private func expressionKeywords(_ n: Int) -> [String] { lifePathKeywords(n > 9 ? reduceToSingle(n) : n) }
    
    private func soulUrgeMeaning(_ n: Int) -> String {
        let base: [Int: String] = [
            1: "Your soul craves independence and the freedom to lead.",
            2: "Your soul craves deep partnership and harmony.",
            3: "Your soul craves creative expression and joyful communication.",
            4: "Your soul craves stability, order, and meaningful work.",
            5: "Your soul craves adventure, variety, and sensory experience.",
            6: "Your soul craves love, family, and creating beauty.",
            7: "Your soul craves truth, solitude, and spiritual understanding.",
            8: "Your soul craves mastery, influence, and material accomplishment.",
            9: "Your soul craves service to humanity and universal compassion.",
        ]
        return base[n > 9 ? reduceToSingle(n) : n] ?? "Your soul carries a deep and unique desire."
    }
    
    private func soulUrgeKeywords(_ n: Int) -> [String] { lifePathKeywords(n > 9 ? reduceToSingle(n) : n) }
    
    private func personalityMeaning(_ n: Int) -> String {
        "The world sees you through the lens of the number \(n) — \(lifePathKeywords(n > 9 ? reduceToSingle(n) : n).prefix(2).joined(separator: " and ").lowercased())."
    }
    
    private func personalityKeywords(_ n: Int) -> [String] { lifePathKeywords(n > 9 ? reduceToSingle(n) : n) }
    
    private func birthdayMeaning(_ n: Int) -> String {
        "Born on a \(n) day, you carry \(lifePathKeywords(n).first?.lowercased() ?? "a unique quality") as a natural talent."
    }
    
    private func birthdayKeywords(_ n: Int) -> [String] { Array(lifePathKeywords(n).prefix(2)) }
    
    private func personalYearTheme(_ n: Int) -> String {
        let themes: [Int: String] = [
            1: "New beginnings and fresh starts",
            2: "Patience, partnerships, and gestation",
            3: "Creative expression and social expansion",
            4: "Building foundations and hard work",
            5: "Change, freedom, and adventure",
            6: "Love, family, and responsibility",
            7: "Reflection, spirituality, and inner work",
            8: "Achievement, power, and abundance",
            9: "Completion, release, and humanitarianism",
        ]
        return themes[n > 9 ? reduceToSingle(n) : n] ?? "A unique year of transformation"
    }
    
    private func pinnacleMeaning(_ n: Int) -> String {
        "A period emphasizing \(lifePathKeywords(n > 9 ? reduceToSingle(n) : n).prefix(2).joined(separator: " and ").lowercased())."
    }
    
    private func challengeMeaning(_ n: Int) -> String {
        let challenges: [Int: String] = [
            0: "The challenge of all challenges — finding your own inner compass",
            1: "The challenge of asserting yourself and standing alone",
            2: "The challenge of patience, sensitivity, and cooperation",
            3: "The challenge of self-expression and overcoming self-doubt",
            4: "The challenge of discipline, commitment, and practical effort",
            5: "The challenge of handling freedom responsibly",
            6: "The challenge of responsibility without self-sacrifice",
            7: "The challenge of trust, faith, and emotional openness",
            8: "The challenge of power, money, and material mastery",
            9: "The challenge of letting go and serving the greater good",
        ]
        return challenges[n > 9 ? reduceToSingle(n) : n] ?? "A unique challenge for growth."
    }
}
