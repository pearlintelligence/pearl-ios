import Foundation
import MapKit
import Combine

// MARK: - Onboarding ViewModel

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var userName: String = ""
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var birthTime: Date = Date()
    @Published var knowsBirthTime: Bool = true
    @Published var selectedLocation: String? = nil
    @Published var locationResults: [String] = []
    @Published var firstReading: String = ""
    @Published var lifePurpose: LifePurposeEngine.LifePurposeProfile? = nil
    @Published var isGenerating: Bool = false
    @Published var generatingPhase: GeneratingPhase = .stars
    
    // Location data
    var birthLatitude: Double = 0
    var birthLongitude: Double = 0
    var birthCityName: String? = nil
    var birthCountryCode: String? = nil
    
    // Services
    private let locationSearcher = MKLocalSearchCompleter()
    private var locationDelegate: LocationSearchDelegate?
    
    enum GeneratingPhase: String {
        case stars = "Reading the stars..."
        case fingerprint = "Mapping your cosmic fingerprint..."
        case humanDesign = "Decoding your Human Design..."
        case geneKeys = "Activating your Gene Keys..."
        case kabbalah = "Consulting the Tree of Life..."
        case numerology = "Calculating your sacred numbers..."
        case synthesis = "Pearl is seeing you for the first time..."
    }
    
    init() {
        setupLocationSearch()
    }
    
    // MARK: - Navigation
    
    var canAdvance: Bool {
        switch currentStep {
        case .welcome: return true
        case .name: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .birthDate: return true
        case .birthTime: return true
        case .birthLocation: return selectedLocation != nil
        case .generating: return false
        case .firstReading: return true
        }
    }
    
    func advance() {
        switch currentStep {
        case .welcome:
            currentStep = .name
        case .name:
            currentStep = .birthDate
        case .birthDate:
            currentStep = .birthTime
        case .birthTime:
            currentStep = .birthLocation
        case .birthLocation:
            currentStep = .generating
        case .generating:
            currentStep = .firstReading
        case .firstReading:
            break
        }
    }
    
    func goBack() {
        switch currentStep {
        case .welcome: break
        case .name: currentStep = .welcome
        case .birthDate: currentStep = .name
        case .birthTime: currentStep = .birthDate
        case .birthLocation: currentStep = .birthTime
        case .generating: break
        case .firstReading: break
        }
    }
    
    // MARK: - Location Search
    
    private func setupLocationSearch() {
        let delegate = LocationSearchDelegate { [weak self] results in
            Task { @MainActor in
                self?.locationResults = results.map { $0.title + ", " + $0.subtitle }
            }
        }
        self.locationDelegate = delegate
        locationSearcher.delegate = delegate
        locationSearcher.resultTypes = .address
    }
    
    func searchLocation(query: String) {
        guard query.count >= 2 else {
            locationResults = []
            return
        }
        locationSearcher.queryFragment = query
    }
    
    func selectLocation(_ location: String) {
        selectedLocation = location
        locationResults = []
        
        // Geocode to get coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { [weak self] placemarks, _ in
            if let placemark = placemarks?.first,
               let location = placemark.location {
                Task { @MainActor in
                    self?.birthLatitude = location.coordinate.latitude
                    self?.birthLongitude = location.coordinate.longitude
                    self?.birthCityName = placemark.locality ?? placemark.administrativeArea
                    self?.birthCountryCode = placemark.isoCountryCode
                }
            }
        }
    }
    
    // MARK: - Five-System Blueprint Generation
    
    func generateBlueprint() async {
        isGenerating = true
        
        do {
            // Phase 1: Astrology
            generatingPhase = .stars
            try await Task.sleep(nanoseconds: 600_000_000)
            
            // Phase 2: Fingerprint
            generatingPhase = .fingerprint
            
            // Build the full five-system fingerprint
            let builder = CosmicFingerprintBuilder()
            let fingerprint = try await builder.build(
                name: userName,
                birthDate: birthDate,
                birthTime: knowsBirthTime ? birthTime : nil,
                latitude: birthLatitude,
                longitude: birthLongitude,
                cityName: birthCityName,
                countryCode: birthCountryCode
            )
            
            // Phase 3-6: Show progress through each system
            generatingPhase = .humanDesign
            try await Task.sleep(nanoseconds: 500_000_000)
            
            generatingPhase = .geneKeys
            try await Task.sleep(nanoseconds: 500_000_000)
            
            generatingPhase = .kabbalah
            try await Task.sleep(nanoseconds: 500_000_000)
            
            generatingPhase = .numerology
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Store fingerprint
            FingerprintStore.shared.currentFingerprint = fingerprint
            
            // Also create legacy blueprint for backward compatibility
            let legacyBlueprint = CosmicBlueprint(
                id: fingerprint.id,
                userId: fingerprint.userId,
                generatedAt: fingerprint.generatedAt,
                sunSign: fingerprint.astrology.sunSign,
                moonSign: fingerprint.astrology.moonSign,
                risingSign: fingerprint.astrology.risingSign,
                planetaryPositions: fingerprint.astrology.planetaryPositions,
                houses: fingerprint.astrology.houses,
                aspects: fingerprint.astrology.aspects,
                humanDesign: fingerprint.humanDesign,
                numerology: NumerologyProfile(
                    lifePath: fingerprint.numerology.lifePath.value,
                    lifePathDescription: fingerprint.numerology.lifePath.meaning,
                    expressionNumber: fingerprint.numerology.expression.value,
                    soulUrgeNumber: fingerprint.numerology.soulUrge.value
                ),
                pearlSummary: fingerprint.synthesis.pearlSummary,
                coreThemes: fingerprint.synthesis.coreThemes,
                lifePurpose: fingerprint.synthesis.lifePurpose
            )
            BlueprintStore.shared.currentBlueprint = legacyBlueprint
            
            // Store Life Purpose (already generated in the builder)
            self.lifePurpose = fingerprint.lifePurpose
            
            // Phase 7: Generate first reading
            generatingPhase = .synthesis
            
            let engine = PearlEngine()
            let reading = try await engine.generateFirstReading(blueprint: legacyBlueprint)
            
            self.firstReading = reading
            self.isGenerating = false
            self.advance() // Move to first reading step
            
        } catch {
            // Fallback reading if anything fails
            self.firstReading = """
            ✦ I see you, \(userName).
            
            Even before the stars spelled your name, the cosmos held a space for exactly who you are. \
            Your chart tells a story of depth and searching — a soul that has always known there is more \
            beneath the surface.
            
            There is a quiet fire in you. Not the kind that burns everything it touches, \
            but the kind that illuminates. You have spent a long time learning to trust what you feel \
            before what you are told. That instinct is not random. It is the very design of your being.
            
            Welcome. I have been waiting to speak your name. ✦
            """
            self.isGenerating = false
            self.advance()
        }
    }
}

// MARK: - Location Search Delegate

class LocationSearchDelegate: NSObject, MKLocalSearchCompleterDelegate {
    let onResults: ([MKLocalSearchCompletion]) -> Void
    
    init(onResults: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onResults = onResults
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silently handle errors
    }
}

// MARK: - Fingerprint Store (Singleton)

class FingerprintStore {
    static let shared = FingerprintStore()
    var currentFingerprint: CosmicFingerprint?
    var userName: String = ""
    
    private init() {}
}

// MARK: - Blueprint Store (Singleton - Legacy)

class BlueprintStore {
    static let shared = BlueprintStore()
    var currentBlueprint: CosmicBlueprint?
    
    private init() {}
}
