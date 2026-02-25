import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pearlEngine: PearlEngine
    
    var body: some View {
        ZStack {
            CosmicBackground()
            
            VStack {
                // Progress indicator
                if viewModel.currentStep != .welcome && viewModel.currentStep != .firstReading {
                    OnboardingProgress(currentStep: viewModel.currentStep)
                        .padding(.top, 16)
                        .transition(.opacity)
                }
                
                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeStep(onContinue: { viewModel.advance() })
                    case .birthDate:
                        BirthDateStep(
                            selectedDate: $viewModel.birthDate,
                            onContinue: { viewModel.advance() }
                        )
                    case .birthTime:
                        BirthTimeStep(
                            selectedTime: $viewModel.birthTime,
                            knowsBirthTime: $viewModel.knowsBirthTime,
                            onContinue: { viewModel.advance() }
                        )
                    case .birthLocation:
                        BirthLocationStep(
                            viewModel: viewModel,
                            onContinue: { viewModel.advance() }
                        )
                    case .generating:
                        GeneratingStep(viewModel: viewModel)
                    case .firstReading:
                        FirstReadingStep(
                            reading: viewModel.firstReading,
                            onContinue: {
                                appState.hasCompletedOnboarding = true
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .animation(.easeInOut(duration: 0.5), value: viewModel.currentStep)
        }
    }
}

// MARK: - Onboarding Steps

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case birthDate
    case birthTime
    case birthLocation
    case generating
    case firstReading
}

// MARK: - Progress Indicator

struct OnboardingProgress: View {
    let currentStep: OnboardingStep
    
    private var progress: CGFloat {
        switch currentStep {
        case .welcome: return 0
        case .birthDate: return 0.25
        case .birthTime: return 0.5
        case .birthLocation: return 0.75
        case .generating: return 0.9
        case .firstReading: return 1.0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(PearlColors.surface)
                    .frame(height: 2)
                
                Rectangle()
                    .fill(PearlColors.goldGradient)
                    .frame(width: geometry.size.width * progress, height: 2)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 2)
        .padding(.horizontal, 40)
    }
}
