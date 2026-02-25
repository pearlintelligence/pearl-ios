import Foundation
import MapKit
import Combine

// MARK: - Onboarding ViewModel

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @Published var birthTime: Date = Date()
    @Published var knowsBirthTime: Bool = true
    @Published var selectedLocation: String? = nil
    @Published var locationResults: [String] = []
    @Published var firstReading: String = ""
    @Published var isGenerating: Bool = false
    
    // Location data
    var birthLatitude: Double = 0
    var birthLongitude: Double = 0
    
    private let locationSearcher = MKLocalSearchCompleter()
    private let astrologyService = AstrologyService()
    private var searchCancellable: AnyCancellable?
    private var locationDelegate: LocationSearchDelegate?
    
    init() {
        setupLocationSearch()
    }
    
    // MARK: - Navigation
    
    func advance() {
        switch currentStep {
        case .welcome:
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
                }
            }
        }
    }
    
    // MARK: - Blueprint Generation
    
    func generateBlueprint() async {
        isGenerating = true
        
        do {
            // Calculate natal chart
            let natalChart = try await astrologyService.calculateNatalChart(
                date: birthDate,
                time: knowsBirthTime ? birthTime : nil,
                latitude: birthLatitude,
                longitude: birthLongitude
            )
            
            // Build blueprint (simplified for prototype)
            let blueprint = CosmicBlueprint(
                id: UUID(),
                userId: UUID(),
                generatedAt: Date(),
                sunSign: natalChart.sunSign,
                moonSign: natalChart.moonSign,
                risingSign: natalChart.risingSign,
                planetaryPositions: natalChart.planets,
                houses: natalChart.houses,
                aspects: natalChart.aspects,
                humanDesign: HumanDesignProfile(
                    type: .generator,  // Placeholder — full HD calculation needed
                    strategy: "Wait to Respond",
                    authority: "Sacral",
                    profile: "3/5",
                    definedCenters: [.sacral, .root, .solarPlexus],
                    undefinedCenters: [.head, .ajna, .throat, .g, .heart, .spleen]
                ),
                numerology: NumerologyProfile(
                    lifePath: calculateLifePath(from: birthDate),
                    lifePathDescription: "",
                    expressionNumber: nil,
                    soulUrgeNumber: nil
                ),
                pearlSummary: "",
                coreThemes: [],
                lifePurpose: ""
            )
            
            // Store blueprint
            BlueprintStore.shared.currentBlueprint = blueprint
            
            // Generate Pearl's first reading
            let engine = PearlEngine()
            let reading = try await engine.generateFirstReading(blueprint: blueprint)
            
            self.firstReading = reading
            self.isGenerating = false
            self.advance() // Move to first reading step
            
        } catch {
            // Fallback reading if API fails
            self.firstReading = """
            ✦ I see you.
            
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
    
    // MARK: - Numerology Helper
    
    private func calculateLifePath(from date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        func reduceToSingle(_ n: Int) -> Int {
            var num = n
            while num > 9 && num != 11 && num != 22 && num != 33 {
                num = String(num).compactMap { $0.wholeNumberValue }.reduce(0, +)
            }
            return num
        }
        
        let monthReduced = reduceToSingle(components.month!)
        let dayReduced = reduceToSingle(components.day!)
        let yearReduced = reduceToSingle(components.year!)
        
        return reduceToSingle(monthReduced + dayReduced + yearReduced)
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

// MARK: - Blueprint Store (Singleton)

class BlueprintStore {
    static let shared = BlueprintStore()
    var currentBlueprint: CosmicBlueprint?
    
    private init() {}
}
