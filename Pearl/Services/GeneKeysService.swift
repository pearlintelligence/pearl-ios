import Foundation

// MARK: - Gene Keys Service
// Maps birth data to Gene Key profiles using the I Ching / Human Design gate system
// Each Gene Key has a Shadow → Gift → Siddhi progression

class GeneKeysService {
    
    // MARK: - Gene Key Profile
    
    struct GeneKeyProfile: Codable {
        let lifeWork: GeneKey       // Sun personality gate
        let evolution: GeneKey      // Earth personality gate
        let radiance: GeneKey       // Sun design gate
        let purpose: GeneKey        // Earth design gate
        let pearlSequence: PearlSequence
    }
    
    struct GeneKey: Codable, Identifiable {
        var id: Int { number }
        let number: Int
        let shadow: String
        let gift: String
        let siddhi: String
        let theme: String
        let codonRing: String
    }
    
    struct PearlSequence: Codable {
        let vocation: GeneKey
        let culture: GeneKey
        let brand: GeneKey
        let pearl: GeneKey
    }
    
    // MARK: - Calculate Gene Key Profile
    
    func calculateProfile(birthDate: Date, birthTime: Date?) -> GeneKeyProfile {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: birthDate) ?? 1
        
        // Map sun longitude to gate (same system as Human Design)
        let sunLongitude = Double(dayOfYear) / 365.25 * 360.0
        let sunGate = gateForLongitude(sunLongitude)
        let earthGate = gateForLongitude(normalizeAngle(sunLongitude + 180))
        
        // Design gates (~88 days before birth)
        let designDate = calendar.date(byAdding: .day, value: -88, to: birthDate) ?? birthDate
        let designDayOfYear = calendar.ordinality(of: .day, in: .year, for: designDate) ?? 1
        let designSunLong = Double(designDayOfYear) / 365.25 * 360.0
        let designSunGate = gateForLongitude(designSunLong)
        let designEarthGate = gateForLongitude(normalizeAngle(designSunLong + 180))
        
        let lifeWork = geneKeyData(for: sunGate)
        let evolution = geneKeyData(for: earthGate)
        let radiance = geneKeyData(for: designSunGate)
        let purpose = geneKeyData(for: designEarthGate)
        
        // Pearl Sequence (derived from specific planetary positions)
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        let vocGate = gateOrder[((month * 7 + day * 3) % 64)]
        let culGate = gateOrder[((month * 11 + day * 5) % 64)]
        let brGate = gateOrder[((month * 13 + day * 7) % 64)]
        let pearlGate = gateOrder[((month * 17 + day * 11) % 64)]
        
        let pearlSequence = PearlSequence(
            vocation: geneKeyData(for: vocGate),
            culture: geneKeyData(for: culGate),
            brand: geneKeyData(for: brGate),
            pearl: geneKeyData(for: pearlGate)
        )
        
        return GeneKeyProfile(
            lifeWork: lifeWork,
            evolution: evolution,
            radiance: radiance,
            purpose: purpose,
            pearlSequence: pearlSequence
        )
    }
    
    // MARK: - Gate Mapping
    
    private let gateOrder = [41,19,13,49,30,55,37,63,22,36,25,17,21,51,42,3,27,24,2,23,8,20,16,35,45,12,15,52,39,53,62,56,31,33,7,4,29,59,40,64,47,6,46,18,48,57,32,50,28,44,1,43,14,34,9,5,26,11,10,58,38,54,61,60]
    
    private func gateForLongitude(_ longitude: Double) -> Int {
        let normalized = normalizeAngle(longitude)
        let index = Int(normalized / 5.625) % 64
        return gateOrder[index]
    }
    
    private func normalizeAngle(_ angle: Double) -> Double {
        var result = angle.truncatingRemainder(dividingBy: 360.0)
        if result < 0 { result += 360.0 }
        return result
    }
    
    // MARK: - Gene Key Data (All 64 Keys)
    
    func geneKeyData(for number: Int) -> GeneKey {
        return allGeneKeys[number - 1]
    }
    
    private let allGeneKeys: [GeneKey] = [
        GeneKey(number: 1, shadow: "Entropy", gift: "Freshness", siddhi: "Beauty", theme: "From Self-Absorption to Fresh Beauty", codonRing: "Ring of Fire"),
        GeneKey(number: 2, shadow: "Dislocation", gift: "Orientation", siddhi: "Unity", theme: "Returning to the One", codonRing: "Ring of Water"),
        GeneKey(number: 3, shadow: "Chaos", gift: "Innovation", siddhi: "Innocence", theme: "Through the Eyes of a Child", codonRing: "Ring of Life and Death"),
        GeneKey(number: 4, shadow: "Intolerance", gift: "Understanding", siddhi: "Forgiveness", theme: "A Universal Panacea", codonRing: "Ring of Union"),
        GeneKey(number: 5, shadow: "Impatience", gift: "Patience", siddhi: "Timelessness", theme: "The Ending of Time", codonRing: "Ring of Light"),
        GeneKey(number: 6, shadow: "Conflict", gift: "Diplomacy", siddhi: "Peace", theme: "The Path to Peace", codonRing: "Ring of Alchemy"),
        GeneKey(number: 7, shadow: "Division", gift: "Guidance", siddhi: "Virtue", theme: "The Army of Light", codonRing: "Ring of Union"),
        GeneKey(number: 8, shadow: "Mediocrity", gift: "Style", siddhi: "Exquisiteness", theme: "The Diamond of Your True Self", codonRing: "Ring of Water"),
        GeneKey(number: 9, shadow: "Inertia", gift: "Determination", siddhi: "Invincibility", theme: "The Power of the Infinitesimal", codonRing: "Ring of Light"),
        GeneKey(number: 10, shadow: "Self-Obsession", gift: "Naturalness", siddhi: "Being", theme: "Being at Ease", codonRing: "Ring of Humanity"),
        GeneKey(number: 11, shadow: "Obscurity", gift: "Idealism", siddhi: "Light", theme: "The Light of Eden", codonRing: "Ring of Light"),
        GeneKey(number: 12, shadow: "Vanity", gift: "Discrimination", siddhi: "Purity", theme: "A Pure Heart", codonRing: "Ring of Trials"),
        GeneKey(number: 13, shadow: "Discord", gift: "Discernment", siddhi: "Empathy", theme: "Listening Through Love", codonRing: "Ring of Purification"),
        GeneKey(number: 14, shadow: "Compromise", gift: "Competence", siddhi: "Bounteousness", theme: "Radiating Prosperity", codonRing: "Ring of Fire"),
        GeneKey(number: 15, shadow: "Dullness", gift: "Magnetism", siddhi: "Florescence", theme: "An Eternally Flowering Spring", codonRing: "Ring of Seeking"),
        GeneKey(number: 16, shadow: "Indifference", gift: "Versatility", siddhi: "Mastery", theme: "Magical Genius", codonRing: "Ring of Prosperity"),
        GeneKey(number: 17, shadow: "Opinion", gift: "Far-Sightedness", siddhi: "Omniscience", theme: "The Eye", codonRing: "Ring of Humanity"),
        GeneKey(number: 18, shadow: "Judgement", gift: "Integrity", siddhi: "Perfection", theme: "The Healing Power of Mind", codonRing: "Ring of Matter"),
        GeneKey(number: 19, shadow: "Co-dependence", gift: "Sensitivity", siddhi: "Sacrifice", theme: "The Future Human Being", codonRing: "Ring of Gaia"),
        GeneKey(number: 20, shadow: "Superficiality", gift: "Self-Assurance", siddhi: "Presence", theme: "The Sacred Om", codonRing: "Ring of Life and Death"),
        GeneKey(number: 21, shadow: "Control", gift: "Authority", siddhi: "Valour", theme: "A Noble Life", codonRing: "Ring of Humanity"),
        GeneKey(number: 22, shadow: "Dishonour", gift: "Graciousness", siddhi: "Grace", theme: "Grace Under Pressure", codonRing: "Ring of Divinity"),
        GeneKey(number: 23, shadow: "Complexity", gift: "Simplicity", siddhi: "Quintessence", theme: "The Alchemy of Simplicity", codonRing: "Ring of Life and Death"),
        GeneKey(number: 24, shadow: "Addiction", gift: "Invention", siddhi: "Silence", theme: "The Paradise State", codonRing: "Ring of Life and Death"),
        GeneKey(number: 25, shadow: "Constriction", gift: "Acceptance", siddhi: "Universal Love", theme: "The Myth of the Sacred Wound", codonRing: "Ring of Humanity"),
        GeneKey(number: 26, shadow: "Pride", gift: "Artfulness", siddhi: "Invisibility", theme: "Sacred Tricksters", codonRing: "Ring of Light"),
        GeneKey(number: 27, shadow: "Selfishness", gift: "Altruism", siddhi: "Selflessness", theme: "Food of the Gods", codonRing: "Ring of Life and Death"),
        GeneKey(number: 28, shadow: "Purposelessness", gift: "Totality", siddhi: "Immortality", theme: "Embracing the Dark Side", codonRing: "Ring of Illusion"),
        GeneKey(number: 29, shadow: "Half-Heartedness", gift: "Commitment", siddhi: "Devotion", theme: "Leaping into the Void", codonRing: "Ring of Union"),
        GeneKey(number: 30, shadow: "Desire", gift: "Lightness", siddhi: "Rapture", theme: "Celestial Fire", codonRing: "Ring of Purification"),
        GeneKey(number: 31, shadow: "Arrogance", gift: "Leadership", siddhi: "Humility", theme: "Sounding Your Truth", codonRing: "Ring of No Return"),
        GeneKey(number: 32, shadow: "Failure", gift: "Preservation", siddhi: "Veneration", theme: "Ancestral Reverence", codonRing: "Ring of Illusion"),
        GeneKey(number: 33, shadow: "Forgetting", gift: "Mindfulness", siddhi: "Revelation", theme: "The Final Revelation", codonRing: "Ring of Trials"),
        GeneKey(number: 34, shadow: "Force", gift: "Strength", siddhi: "Majesty", theme: "The Beauty of the Beast", codonRing: "Ring of Alchemy"),
        GeneKey(number: 35, shadow: "Hunger", gift: "Adventure", siddhi: "Boundlessness", theme: "Wormholes and Miracles", codonRing: "Ring of Miracles"),
        GeneKey(number: 36, shadow: "Turbulence", gift: "Humanity", siddhi: "Compassion", theme: "Becoming Human", codonRing: "Ring of Divinity"),
        GeneKey(number: 37, shadow: "Weakness", gift: "Equality", siddhi: "Tenderness", theme: "Family Alchemy", codonRing: "Ring of Divinity"),
        GeneKey(number: 38, shadow: "Struggle", gift: "Perseverance", siddhi: "Honour", theme: "The Warrior of Light", codonRing: "Ring of Destiny"),
        GeneKey(number: 39, shadow: "Provocation", gift: "Dynamism", siddhi: "Liberation", theme: "The Tension of Transcendence", codonRing: "Ring of Seeking"),
        GeneKey(number: 40, shadow: "Exhaustion", gift: "Resolve", siddhi: "Divine Will", theme: "The Will to Surrender", codonRing: "Ring of Alchemy"),
        GeneKey(number: 41, shadow: "Fantasy", gift: "Anticipation", siddhi: "Emanation", theme: "The Prime Emanation", codonRing: "Ring of Origin"),
        GeneKey(number: 42, shadow: "Expectation", gift: "Detachment", siddhi: "Celebration", theme: "Letting Go of Living and Dying", codonRing: "Ring of Matter"),
        GeneKey(number: 43, shadow: "Deafness", gift: "Insight", siddhi: "Epiphany", theme: "Breakthrough", codonRing: "Ring of Destiny"),
        GeneKey(number: 44, shadow: "Interference", gift: "Teamwork", siddhi: "Synarchy", theme: "Karmic Relationships", codonRing: "Ring of Illusion"),
        GeneKey(number: 45, shadow: "Dominance", gift: "Synergy", siddhi: "Communion", theme: "Cosmic Communion", codonRing: "Ring of Prosperity"),
        GeneKey(number: 46, shadow: "Seriousness", gift: "Delight", siddhi: "Ecstasy", theme: "A Science of Luck", codonRing: "Ring of Matter"),
        GeneKey(number: 47, shadow: "Oppression", gift: "Transmutation", siddhi: "Transfiguration", theme: "Transmuting the Past", codonRing: "Ring of Alchemy"),
        GeneKey(number: 48, shadow: "Inadequacy", gift: "Resourcefulness", siddhi: "Wisdom", theme: "The Wonder of Uncertainty", codonRing: "Ring of Matter"),
        GeneKey(number: 49, shadow: "Reaction", gift: "Revolution", siddhi: "Rebirth", theme: "Changing the World from the Inside", codonRing: "Ring of the Whirlwind"),
        GeneKey(number: 50, shadow: "Corruption", gift: "Equilibrium", siddhi: "Harmony", theme: "Cosmic Order", codonRing: "Ring of Illuminati"),
        GeneKey(number: 51, shadow: "Agitation", gift: "Initiative", siddhi: "Awakening", theme: "Initiative to Awakening", codonRing: "Ring of Humanity"),
        GeneKey(number: 52, shadow: "Stress", gift: "Restraint", siddhi: "Stillness", theme: "The Stillpoint", codonRing: "Ring of Seeking"),
        GeneKey(number: 53, shadow: "Immaturity", gift: "Expansion", siddhi: "Superabundance", theme: "Evolving Beyond Evolution", codonRing: "Ring of Seeking"),
        GeneKey(number: 54, shadow: "Greed", gift: "Aspiration", siddhi: "Ascension", theme: "The Serpent Path", codonRing: "Ring of Gaia"),
        GeneKey(number: 55, shadow: "Victimisation", gift: "Freedom", siddhi: "Freedom", theme: "The Dragonfly's Dream", codonRing: "Ring of the Whirlwind"),
        GeneKey(number: 56, shadow: "Distraction", gift: "Enrichment", siddhi: "Intoxication", theme: "Divine Intoxication", codonRing: "Ring of Trials"),
        GeneKey(number: 57, shadow: "Unease", gift: "Intuition", siddhi: "Clarity", theme: "A Gentle Wind", codonRing: "Ring of Matter"),
        GeneKey(number: 58, shadow: "Dissatisfaction", gift: "Vitality", siddhi: "Bliss", theme: "From Dissatisfaction to Bliss", codonRing: "Ring of Seeking"),
        GeneKey(number: 59, shadow: "Dishonesty", gift: "Intimacy", siddhi: "Transparency", theme: "The Dragon in Your Genome", codonRing: "Ring of Union"),
        GeneKey(number: 60, shadow: "Limitation", gift: "Realism", siddhi: "Justice", theme: "The Cracking of the Vessel", codonRing: "Ring of Gaia"),
        GeneKey(number: 61, shadow: "Psychosis", gift: "Inspiration", siddhi: "Sanctity", theme: "The Holy of Holies", codonRing: "Ring of Gaia"),
        GeneKey(number: 62, shadow: "Intellect", gift: "Precision", siddhi: "Impeccability", theme: "The Language of Light", codonRing: "Ring of No Return"),
        GeneKey(number: 63, shadow: "Doubt", gift: "Inquiry", siddhi: "Truth", theme: "Reaching the Source", codonRing: "Ring of Origin"),
        GeneKey(number: 64, shadow: "Confusion", gift: "Imagination", siddhi: "Illumination", theme: "The Aurora", codonRing: "Ring of Origin"),
    ]
}
