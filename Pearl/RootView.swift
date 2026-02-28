import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingFlow()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: appState.hasCompletedOnboarding)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.currentTab) {
            DashboardView()
                .tabItem {
                    Label("Blueprint", systemImage: "sparkles")
                }
                .tag(AppState.Tab.dashboard)
            
            ChatView()
                .tabItem {
                    Label("Pearl", systemImage: "bubble.left.fill")
                }
                .tag(AppState.Tab.chat)
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "sun.and.horizon.fill")
                }
                .tag(AppState.Tab.insights)
            
            ProfileView()
                .tabItem {
                    Label("You", systemImage: "person.fill")
                }
                .tag(AppState.Tab.profile)
        }
        .tint(PearlColors.gold)
        .onAppear {
            // Style tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(PearlColors.void)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
