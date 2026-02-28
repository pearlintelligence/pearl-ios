import Foundation

// MARK: - Kabbalah Service
// Maps birth data to the Tree of Life — Sephirot, paths, and soul correction

class KabbalahService {
    
    // MARK: - Kabbalah Profile
    
    struct KabbalahProfile: Codable {
        let soulCorrection: SoulCorrection
        let birthSephirah: Sephirah
        let treeOfLifePositions: [TreePosition]
        let tikkunPath: String
    }
    
    struct SoulCorrection: Codable, Identifiable {
        var id: Int { number }
        let number: Int
        let name: String
        let description: String
        let challenge: String
        let correction: String
    }
    
    struct Sephirah: Codable, Identifiable {
        var id: String { name }
        let name: String
        let hebrewName: String
        let meaning: String
        let quality: String
        let position: Int  // 1-10 on the Tree
    }
    
    struct TreePosition: Codable, Identifiable {
        var id: String { sephirahName }
        let sephirahName: String
        let activation: Double  // 0.0-1.0 strength
        let description: String
    }
    
    // MARK: - Calculate Profile
    
    func calculateProfile(birthDate: Date, name: String) -> KabbalahProfile {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: birthDate)
        let month = calendar.component(.month, from: birthDate)
        let year = calendar.component(.year, from: birthDate)
        
        // Soul Correction is derived from the birth date
        let soulCorrectionNumber = calculateSoulCorrectionNumber(day: day, month: month, year: year)
        let soulCorrection = soulCorrectionData(for: soulCorrectionNumber)
        
        // Birth Sephirah — derived from month
        let sephirahIndex = (month - 1) % 10
        let birthSephirah = sephirot[sephirahIndex]
        
        // Tree of Life positions — derived from name numerology + birth data
        let nameValue = numericalValue(of: name)
        let positions = calculateTreePositions(nameValue: nameValue, day: day, month: month)
        
        // Tikkun path
        let tikkunPath = generateTikkunPath(soulCorrection: soulCorrection, sephirah: birthSephirah)
        
        return KabbalahProfile(
            soulCorrection: soulCorrection,
            birthSephirah: birthSephirah,
            treeOfLifePositions: positions,
            tikkunPath: tikkunPath
        )
    }
    
    // MARK: - Soul Correction Number
    
    private func calculateSoulCorrectionNumber(day: Int, month: Int, year: Int) -> Int {
        // Based on Kabbalistic numerology of the full birth date
        let sum = reduceToSingle(day) + reduceToSingle(month) + reduceToSingle(year)
        let result = reduceToRange(sum, min: 1, max: 72)
        return result
    }
    
    private func reduceToSingle(_ n: Int) -> Int {
        var num = abs(n)
        while num > 9 {
            num = String(num).compactMap { $0.wholeNumberValue }.reduce(0, +)
        }
        return num
    }
    
    private func reduceToRange(_ n: Int, min: Int, max: Int) -> Int {
        let range = max - min + 1
        return ((n - 1) % range) + min
    }
    
    private func numericalValue(of name: String) -> Int {
        // Hebrew gematria-style mapping
        let values: [Character: Int] = [
            "a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6, "g": 7, "h": 8, "i": 9,
            "j": 10, "k": 20, "l": 30, "m": 40, "n": 50, "o": 60, "p": 70, "q": 80, "r": 90,
            "s": 100, "t": 200, "u": 300, "v": 400, "w": 500, "x": 600, "y": 700, "z": 800
        ]
        return name.lowercased().compactMap { values[$0] }.reduce(0, +)
    }
    
    // MARK: - Tree Positions
    
    private func calculateTreePositions(nameValue: Int, day: Int, month: Int) -> [TreePosition] {
        return sephirot.map { sephirah in
            let seed = Double((nameValue + day * sephirah.position + month) % 100) / 100.0
            let activation = max(0.1, min(1.0, seed))
            
            return TreePosition(
                sephirahName: sephirah.name,
                activation: activation,
                description: sephirah.quality
            )
        }
    }
    
    // MARK: - Tikkun Path
    
    private func generateTikkunPath(soulCorrection: SoulCorrection, sephirah: Sephirah) -> String {
        return "Your soul correction of \(soulCorrection.name) invites you through the gateway of \(sephirah.name) (\(sephirah.meaning)). The work of your tikkun is \(soulCorrection.correction.lowercased())."
    }
    
    // MARK: - The 10 Sephirot
    
    let sephirot: [Sephirah] = [
        Sephirah(name: "Keter", hebrewName: "כתר", meaning: "Crown", quality: "Divine Will, the source of all creation", position: 1),
        Sephirah(name: "Chokmah", hebrewName: "חכמה", meaning: "Wisdom", quality: "The first flash of inspiration, raw creative force", position: 2),
        Sephirah(name: "Binah", hebrewName: "בינה", meaning: "Understanding", quality: "The womb of creation, where ideas take form", position: 3),
        Sephirah(name: "Chesed", hebrewName: "חסד", meaning: "Mercy", quality: "Unconditional love, expansion, generosity", position: 4),
        Sephirah(name: "Gevurah", hebrewName: "גבורה", meaning: "Strength", quality: "Discipline, boundaries, the power to refine", position: 5),
        Sephirah(name: "Tiferet", hebrewName: "תפארת", meaning: "Beauty", quality: "Harmony, balance, the heart of the Tree", position: 6),
        Sephirah(name: "Netzach", hebrewName: "נצח", meaning: "Victory", quality: "Endurance, eternity, creative persistence", position: 7),
        Sephirah(name: "Hod", hebrewName: "הוד", meaning: "Splendor", quality: "Intellect, communication, surrender to truth", position: 8),
        Sephirah(name: "Yesod", hebrewName: "יסוד", meaning: "Foundation", quality: "Connection, dreams, the bridge between worlds", position: 9),
        Sephirah(name: "Malkhut", hebrewName: "מלכות", meaning: "Kingdom", quality: "Manifestation, the physical world, grounding", position: 10),
    ]
    
    // MARK: - Soul Correction Data (72 Names of God)
    
    private func soulCorrectionData(for number: Int) -> SoulCorrection {
        let corrections: [SoulCorrection] = [
            SoulCorrection(number: 1, name: "Time Travel", description: "You have the ability to transcend linear time through consciousness.", challenge: "Impatience with the present moment", correction: "Learning to be fully present while holding vision of the future"),
            SoulCorrection(number: 2, name: "Recapturing the Sparks", description: "Your soul seeks to gather scattered fragments of light.", challenge: "Feeling scattered or unfocused", correction: "Gathering your energy and finding wholeness within"),
            SoulCorrection(number: 3, name: "Miracle Making", description: "You carry the potential to manifest the extraordinary.", challenge: "Doubt in your own power", correction: "Trusting in the miraculous nature of your being"),
            SoulCorrection(number: 4, name: "Eliminating Negative Thoughts", description: "Your mind is a powerful creator.", challenge: "Negative self-talk and limiting beliefs", correction: "Mastering the mind and choosing thoughts that serve your highest self"),
            SoulCorrection(number: 5, name: "Healing", description: "You are a natural healer of yourself and others.", challenge: "Taking on others' pain as your own", correction: "Learning to heal through Light rather than through absorption"),
            SoulCorrection(number: 6, name: "Dream State", description: "You access higher realms through dreams and vision.", challenge: "Escapism and avoiding reality", correction: "Grounding spiritual insight into practical action"),
            SoulCorrection(number: 7, name: "DNA of the Soul", description: "Your essence carries deep ancestral wisdom.", challenge: "Repeating family patterns unconsciously", correction: "Breaking generational chains through conscious awareness"),
            SoulCorrection(number: 8, name: "Defying Gravity", description: "You are meant to transcend limitations.", challenge: "Feeling weighed down by the physical world", correction: "Rising above circumstances through spiritual lightness"),
            SoulCorrection(number: 9, name: "Angelic Influences", description: "You have a strong connection to angelic realms.", challenge: "Feeling ungrounded or too ethereal", correction: "Bridging heaven and earth in daily life"),
            SoulCorrection(number: 10, name: "Looks Can Kill", description: "Your gaze carries immense power.", challenge: "Using personal magnetism for ego", correction: "Directing your power toward blessing others"),
            SoulCorrection(number: 11, name: "Letting Go", description: "Freedom comes through release.", challenge: "Holding on too tightly to outcomes", correction: "Surrendering control and trusting the flow of life"),
            SoulCorrection(number: 12, name: "Unconditional Love", description: "Your path leads to love without conditions.", challenge: "Placing conditions on love and acceptance", correction: "Opening the heart to love all beings as they are"),
            SoulCorrection(number: 13, name: "Heaven on Earth", description: "You are meant to bring paradise into the material world.", challenge: "Seeing spiritual and material as separate", correction: "Infusing every moment with sacred awareness"),
            SoulCorrection(number: 14, name: "Farewell to Arms", description: "Peace is your ultimate destination.", challenge: "Engaging in unnecessary conflicts", correction: "Choosing peace over being right"),
            SoulCorrection(number: 15, name: "Long-Range Vision", description: "You see further than most.", challenge: "Frustration when others cannot see what you see", correction: "Patience with the unfolding of your vision"),
            SoulCorrection(number: 16, name: "Dumping Depression", description: "Joy is your birthright.", challenge: "Cycles of melancholy and heaviness", correction: "Choosing joy as a spiritual practice"),
            SoulCorrection(number: 17, name: "Great Escape", description: "You seek liberation in all forms.", challenge: "Running from difficult situations", correction: "Finding freedom within constraints"),
            SoulCorrection(number: 18, name: "Fertility", description: "You create abundance wherever you go.", challenge: "Fear of scarcity or not having enough", correction: "Trusting in your infinite creative capacity"),
            SoulCorrection(number: 19, name: "Dialing God", description: "Direct connection to the Divine is your gift.", challenge: "Feeling spiritually disconnected", correction: "Cultivating constant communion with the sacred"),
            SoulCorrection(number: 20, name: "Victory Over Addictions", description: "Freedom from compulsive patterns.", challenge: "Addictive tendencies in various forms", correction: "Filling the void with spiritual nourishment"),
            SoulCorrection(number: 21, name: "Eradicate Plague", description: "You have the power to transform collective suffering.", challenge: "Absorbing collective negativity", correction: "Transmuting darkness into light for the collective"),
            SoulCorrection(number: 22, name: "Stop Fatal Attraction", description: "Wisdom in relationships.", challenge: "Attraction to harmful patterns", correction: "Choosing relationships that elevate your soul"),
            SoulCorrection(number: 23, name: "Sharing the Flame", description: "Your light is meant to be shared.", challenge: "Hoarding wisdom or hiding your gifts", correction: "Generously sharing your spiritual light"),
            SoulCorrection(number: 24, name: "Jealousy", description: "Transforming envy into inspiration.", challenge: "Comparing yourself to others", correction: "Celebrating others' success as your own"),
            SoulCorrection(number: 25, name: "Speak Your Mind", description: "Truth is your currency.", challenge: "Fear of speaking your truth", correction: "Finding the courage to voice what you know"),
            SoulCorrection(number: 26, name: "Order from Chaos", description: "You bring structure to the formless.", challenge: "Feeling overwhelmed by disorder", correction: "Finding the sacred pattern within apparent chaos"),
            SoulCorrection(number: 27, name: "Silent Partner", description: "Power through stillness.", challenge: "Needing external validation", correction: "Finding strength in quiet inner knowing"),
            SoulCorrection(number: 28, name: "Soul Mate", description: "Deep partnership is your teacher.", challenge: "Codependency or fear of intimacy", correction: "Becoming whole within to attract wholeness"),
            SoulCorrection(number: 29, name: "Removing Hatred", description: "Love dissolves all barriers.", challenge: "Harboring resentment or judgment", correction: "Practicing radical forgiveness"),
            SoulCorrection(number: 30, name: "Building Bridges", description: "You connect what is divided.", challenge: "Taking sides in conflicts", correction: "Seeing the unity beneath all division"),
            SoulCorrection(number: 31, name: "Finish What You Start", description: "Completion is your mastery.", challenge: "Starting many things, finishing few", correction: "Honoring commitments through to their natural end"),
            SoulCorrection(number: 32, name: "Memories", description: "The past holds keys to your future.", challenge: "Being trapped by past experiences", correction: "Mining wisdom from memory without being enslaved by it"),
            SoulCorrection(number: 33, name: "Revealing the Dark Side", description: "Shadow work is your path.", challenge: "Denying your shadow aspects", correction: "Embracing and integrating all parts of yourself"),
            SoulCorrection(number: 34, name: "Forget Thyself", description: "Service dissolves the ego.", challenge: "Self-centeredness or narcissism", correction: "Finding yourself through selfless service"),
            SoulCorrection(number: 35, name: "Sexual Energy", description: "Creative life force flows through you.", challenge: "Misusing sexual or creative energy", correction: "Channeling creative energy toward sacred purposes"),
            SoulCorrection(number: 36, name: "Fearless", description: "Courage is your essence.", challenge: "Hidden fears controlling decisions", correction: "Walking directly toward what you fear most"),
            SoulCorrection(number: 37, name: "The Big Picture", description: "You see the grand design.", challenge: "Getting lost in details", correction: "Maintaining perspective of the whole while attending to parts"),
            SoulCorrection(number: 38, name: "Circuitry", description: "You are a conduit for cosmic energy.", challenge: "Energetic overwhelm or burnout", correction: "Learning to conduct energy without depleting yourself"),
            SoulCorrection(number: 39, name: "Diamond in the Rough", description: "Pressure creates your brilliance.", challenge: "Resisting necessary challenges", correction: "Embracing difficulty as your path to refinement"),
            SoulCorrection(number: 40, name: "Global Transformation", description: "Your personal change ripples outward.", challenge: "Feeling too small to make a difference", correction: "Understanding that your transformation transforms the world"),
            SoulCorrection(number: 41, name: "Self-Appreciation", description: "You are worthy simply because you exist.", challenge: "Chronic self-deprecation", correction: "Recognizing your inherent divine worth"),
            SoulCorrection(number: 42, name: "Revealing the Concealed", description: "You see what is hidden.", challenge: "Using insight manipulatively", correction: "Revealing truth with compassion and timing"),
            SoulCorrection(number: 43, name: "Defying Death", description: "You transcend mortality through consciousness.", challenge: "Fear of death and endings", correction: "Living so fully that death becomes irrelevant"),
            SoulCorrection(number: 44, name: "Sweetening Judgment", description: "Mercy tempers justice.", challenge: "Being overly critical of self and others", correction: "Balancing discernment with compassion"),
            SoulCorrection(number: 45, name: "The Power of Prosperity", description: "Abundance is your natural state.", challenge: "Guilt around wealth or success", correction: "Receiving abundantly and sharing generously"),
            SoulCorrection(number: 46, name: "Absolute Certainty", description: "Faith beyond evidence.", challenge: "Needing proof before believing", correction: "Cultivating certainty in the unseen"),
            SoulCorrection(number: 47, name: "Global Communication", description: "Your words reach far.", challenge: "Miscommunication or gossip", correction: "Speaking words that heal and unite"),
            SoulCorrection(number: 48, name: "Unity", description: "Oneness is your truth.", challenge: "Feeling separate or isolated", correction: "Experiencing the interconnection of all life"),
            SoulCorrection(number: 49, name: "Happiness", description: "Joy is a choice and a practice.", challenge: "Conditional happiness", correction: "Choosing happiness regardless of circumstances"),
            SoulCorrection(number: 50, name: "Enough Is Never Enough", description: "Learning the art of satisfaction.", challenge: "Constant craving for more", correction: "Finding completeness in what is"),
            SoulCorrection(number: 51, name: "No Guilt", description: "Freedom from false guilt.", challenge: "Carrying guilt that isn't yours", correction: "Releasing guilt and stepping into innocence"),
            SoulCorrection(number: 52, name: "Passion", description: "Deep feeling is your fuel.", challenge: "Emotional overwhelm or numbness", correction: "Channeling passion into purposeful creation"),
            SoulCorrection(number: 53, name: "No Agenda", description: "Pure being without manipulation.", challenge: "Hidden agendas in relationships", correction: "Relating with pure authenticity"),
            SoulCorrection(number: 54, name: "The Death of Death", description: "You transcend all endings.", challenge: "Resistance to transformation", correction: "Welcoming each death as a doorway to rebirth"),
            SoulCorrection(number: 55, name: "Thought into Action", description: "Your thoughts manifest reality.", challenge: "Overthinking without acting", correction: "Translating inspiration into embodied action"),
            SoulCorrection(number: 56, name: "Dispelling Anger", description: "Transforming rage into power.", challenge: "Suppressed or explosive anger", correction: "Alchemizing anger into constructive force"),
            SoulCorrection(number: 57, name: "Listen to Your Heart", description: "The heart knows the way.", challenge: "Overriding heart wisdom with logic", correction: "Trusting the intelligence of the heart"),
            SoulCorrection(number: 58, name: "Letting Go of Ego", description: "True power lies beyond ego.", challenge: "Ego-driven decisions and identity", correction: "Discovering who you are beyond the ego"),
            SoulCorrection(number: 59, name: "Umbilical Cord", description: "Connection to source.", challenge: "Feeling cut off from spiritual nourishment", correction: "Remembering your eternal connection to the Divine"),
            SoulCorrection(number: 60, name: "Spiritual Cleansing", description: "Purification of the soul.", challenge: "Accumulating spiritual density", correction: "Regular practices of energetic clearing and renewal"),
            SoulCorrection(number: 61, name: "Water", description: "Flow is your nature.", challenge: "Rigidity and resistance to change", correction: "Becoming like water — adaptable, powerful, and life-giving"),
            SoulCorrection(number: 62, name: "Parent-Loss", description: "Transcending parental wounds.", challenge: "Unresolved parental relationships", correction: "Becoming your own loving parent"),
            SoulCorrection(number: 63, name: "Appreciation", description: "Gratitude transforms everything.", challenge: "Taking life for granted", correction: "Cultivating deep appreciation for every breath"),
            SoulCorrection(number: 64, name: "Casting Off Negativity", description: "You shed what no longer serves.", challenge: "Absorbing environmental negativity", correction: "Maintaining your light regardless of surroundings"),
            SoulCorrection(number: 65, name: "Spiritual Umbilical Cord", description: "Your connection to the infinite.", challenge: "Spiritual dryness or disconnection", correction: "Nurturing your invisible connection to all that is"),
            SoulCorrection(number: 66, name: "Accountability", description: "Owning your creation.", challenge: "Blaming external circumstances", correction: "Taking full responsibility for your life experience"),
            SoulCorrection(number: 67, name: "Great Expectations", description: "Release attachment to outcomes.", challenge: "Disappointment when reality doesn't match expectations", correction: "Surrendering expectations while maintaining intention"),
            SoulCorrection(number: 68, name: "Contacting Departed Souls", description: "You bridge the worlds of living and passed.", challenge: "Grief or fear of death", correction: "Understanding death as a doorway, not an ending"),
            SoulCorrection(number: 69, name: "Lost and Found", description: "What was lost returns transformed.", challenge: "Mourning what you've lost", correction: "Trusting that nothing is ever truly lost"),
            SoulCorrection(number: 70, name: "Remembering", description: "Ancient knowledge lives within you.", challenge: "Forgetting your true nature", correction: "Awakening the deep memory of who you really are"),
            SoulCorrection(number: 71, name: "Prophecy and Parallel Universes", description: "You sense multiple timelines.", challenge: "Confusion about which path to take", correction: "Trusting your inner sight to guide you through possibilities"),
            SoulCorrection(number: 72, name: "Spiritual Cleansing", description: "The final purification.", challenge: "Carrying collective karma", correction: "Serving as a vessel of purification for the world"),
        ]
        
        let index = ((number - 1) % corrections.count)
        return corrections[index]
    }
}
