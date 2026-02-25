import Foundation

// MARK: - Dashboard ViewModel

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var blueprint: CosmicBlueprint?
    @Published var currentInsight: WeeklyInsight?
    @Published var isLoading: Bool = false
    
    init() {
        loadBlueprint()
    }
    
    func loadBlueprint() {
        blueprint = BlueprintStore.shared.currentBlueprint
    }
    
    func refresh() async {
        isLoading = true
        // Reload blueprint and check for new insights
        loadBlueprint()
        
        // Simulate insight generation
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isLoading = false
    }
}
