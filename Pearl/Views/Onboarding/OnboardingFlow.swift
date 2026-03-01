import SwiftUI

// MARK: - Onboarding Flow

struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pearlEngine: PearlEngine
    
    var body: some View {
        ZStack {
            CosmicBackground()
            
            VStack(spacing: 0) {
                // Back button + Progress indicator
                if viewModel.currentStep != .welcome && viewModel.currentStep != .generating && viewModel.currentStep != .firstReading {
                    HStack {
                        if viewModel.currentStep != .name {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.goBack()
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(PearlColors.textSecondary)
                                    .padding(12)
                            }
                        } else {
                            Spacer().frame(width: 40)
                        }
                        
                        Spacer()
                        
                        OnboardingProgress(currentStep: viewModel.currentStep)
                        
                        Spacer()
                        Spacer().frame(width: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.opacity)
                }
                
                // Step content
                Group {
                    switch viewModel.currentStep {
                    case .welcome:
                        WelcomeStep(onContinue: { viewModel.advance() })
                    case .name:
                        NameStep(
                            name: $viewModel.userName,
                            onContinue: {
                                FingerprintStore.shared.userName = viewModel.userName
                                viewModel.advance()
                            }
                        )
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
                            userName: viewModel.userName,
                            reading: viewModel.firstReading,
                            lifePurpose: viewModel.lifePurpose,
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
    case name
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
        case .name: return 0.2
        case .birthDate: return 0.4
        case .birthTime: return 0.6
        case .birthLocation: return 0.8
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
    }
}
