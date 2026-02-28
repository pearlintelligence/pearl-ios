import SwiftUI
import MapKit

// MARK: - Birth Date Step

struct BirthDateStep: View {
    @Binding var selectedDate: Date
    let onContinue: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                DiamondSymbol(size: 20)
                
                Text("When were you born?")
                    .font(PearlFonts.screenTitle)
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                
                Text("The stars hold your story from the very first breath.")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.bottom, 40)
            
            // Date picker
            DatePicker(
                "",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(PearlColors.gold)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            PearlPrimaryButton("Continue") {
                onContinue()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Birth Time Step

struct BirthTimeStep: View {
    @Binding var selectedTime: Date
    @Binding var knowsBirthTime: Bool
    let onContinue: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                DiamondSymbol(size: 20)
                
                Text("What time were you born?")
                    .font(PearlFonts.screenTitle)
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                
                Text("The exact moment shapes the lens\nthrough which you see the world.")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.bottom, 40)
            
            if knowsBirthTime {
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(PearlColors.gold)
                .opacity(showContent ? 1 : 0)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                PearlPrimaryButton(knowsBirthTime ? "Continue" : "Continue Without Time") {
                    onContinue()
                }
                
                PearlTextButton(
                    title: knowsBirthTime ? "I don't know my birth time" : "Actually, I do know it"
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        knowsBirthTime.toggle()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Birth Location Step

struct BirthLocationStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                DiamondSymbol(size: 20)
                    .padding(.top, 32)
                
                Text("Where were you born?")
                    .font(PearlFonts.screenTitle)
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                
                Text("Every place on Earth sees a different sky.")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.bottom, 32)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(PearlColors.textMuted)
                
                TextField("Search city or town...", text: $searchText)
                    .font(PearlFonts.bodyRegular)
                    .foregroundColor(PearlColors.textPrimary)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { _, newValue in
                        viewModel.searchLocation(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        viewModel.locationResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(PearlColors.textMuted)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(PearlColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(PearlColors.gold.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 32)
            .opacity(showContent ? 1 : 0)
            
            // Selected location
            if let location = viewModel.selectedLocation {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(PearlColors.gold)
                    Text(location)
                        .font(PearlFonts.bodyMedium(15))
                        .foregroundColor(PearlColors.goldLight)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(PearlColors.success)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(PearlColors.gold.opacity(0.08))
                )
                .padding(.horizontal, 32)
                .padding(.top, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Search results
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(viewModel.locationResults, id: \.self) { result in
                        Button {
                            viewModel.selectLocation(result)
                            searchText = result
                        } label: {
                            HStack {
                                Image(systemName: "mappin")
                                    .foregroundColor(PearlColors.textMuted)
                                    .frame(width: 24)
                                Text(result)
                                    .font(PearlFonts.body(15))
                                    .foregroundColor(PearlColors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            
            Spacer()
            
            PearlPrimaryButton("Continue") {
                onContinue()
            }
            .disabled(viewModel.selectedLocation == nil)
            .opacity(viewModel.selectedLocation != nil ? 1.0 : 0.4)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

// MARK: - Generating Step (Five-System)

struct GeneratingStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var rotationAngle: Double = 0
    @State private var innerRotation: Double = 0
    @State private var systemIcons: [SystemIcon] = [
        SystemIcon(symbol: "☉", label: "Astrology", offset: 0),
        SystemIcon(symbol: "◈", label: "Human Design", offset: 1),
        SystemIcon(symbol: "🧬", label: "Gene Keys", offset: 2),
        SystemIcon(symbol: "✡", label: "Kabbalah", offset: 3),
        SystemIcon(symbol: "𝟗", label: "Numerology", offset: 4),
    ]
    
    struct SystemIcon: Identifiable {
        let id = UUID()
        let symbol: String
        let label: String
        let offset: Int
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated cosmic mandala
            ZStack {
                // Outer ring
                Circle()
                    .stroke(PearlColors.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                // Rotating ring
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        PearlColors.goldGradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Middle ring
                Circle()
                    .stroke(PearlColors.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 150, height: 150)
                
                // Counter-rotating ring
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        PearlColors.goldLight.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-innerRotation))
                
                // Inner ring
                Circle()
                    .stroke(PearlColors.gold.opacity(0.1), lineWidth: 0.5)
                    .frame(width: 100, height: 100)
                
                // Five system icons orbiting
                ForEach(Array(systemIcons.enumerated()), id: \.element.id) { index, icon in
                    let angle = (Double(index) / 5.0 * 360.0 + rotationAngle * 0.3) * .pi / 180
                    Text(icon.symbol)
                        .font(.system(size: 20))
                        .position(
                            x: 100 + 75 * cos(angle),
                            y: 100 + 75 * sin(angle)
                        )
                        .opacity(0.7)
                }
                .frame(width: 200, height: 200)
                
                // Center diamond
                Text("✦")
                    .font(.system(size: 32))
                    .foregroundColor(PearlColors.gold)
                    .pearlGlow()
            }
            
            // Current phase text
            VStack(spacing: 12) {
                Text(viewModel.generatingPhase.rawValue)
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.generatingPhase.rawValue)
                    .id(viewModel.generatingPhase.rawValue)
                
                // Five system dots
                HStack(spacing: 8) {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(phaseIndex >= i ? PearlColors.gold : PearlColors.surface)
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: phaseIndex)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            // Start rotation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                innerRotation = 360
            }
            
            // Generate blueprint
            Task {
                await viewModel.generateBlueprint()
            }
        }
    }
    
    private var phaseIndex: Int {
        switch viewModel.generatingPhase {
        case .stars: return 0
        case .fingerprint: return 1
        case .humanDesign: return 2
        case .geneKeys: return 3
        case .kabbalah, .numerology: return 4
        case .synthesis: return 5
        }
    }
}

// MARK: - First Reading Step ("Why Am I Here?")

struct FirstReadingStep: View {
    let userName: String
    let reading: String
    let onContinue: () -> Void
    
    @State private var showHeader = false
    @State private var showReading = false
    @State private var showButton = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Text("✦")
                        .font(.system(size: 36))
                        .foregroundColor(PearlColors.gold)
                        .pearlGlow(radius: 16)
                    
                    Text("Pearl Speaks")
                        .font(PearlFonts.screenTitle)
                        .foregroundColor(PearlColors.goldLight)
                    
                    if !userName.isEmpty {
                        Text("For \(userName)")
                            .font(PearlFonts.pearlWhisper)
                            .foregroundColor(PearlColors.textSecondary)
                    }
                }
                .padding(.top, 60)
                .opacity(showHeader ? 1 : 0)
                .offset(y: showHeader ? 0 : 20)
                
                // Decorative divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(PearlColors.gold.opacity(0.2))
                        .frame(height: 0.5)
                    DiamondSymbol(size: 8, color: PearlColors.gold.opacity(0.4))
                    Rectangle()
                        .fill(PearlColors.gold.opacity(0.2))
                        .frame(height: 0.5)
                }
                .padding(.horizontal, 40)
                .opacity(showHeader ? 1 : 0)
                
                // Pearl's first reading — "Why Am I Here?"
                Text(reading)
                    .font(PearlFonts.pearlMessage)
                    .foregroundColor(PearlColors.goldLight)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showReading ? 1 : 0)
                    .offset(y: showReading ? 0 : 20)
                
                Spacer(minLength: 40)
                
                // Continue button
                VStack(spacing: 16) {
                    PearlPrimaryButton("Enter Your World", icon: "sparkles") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        onContinue()
                    }
                    
                    Text("Your journey with Pearl begins now")
                        .font(PearlFonts.caption)
                        .foregroundColor(PearlColors.textMuted)
                }
                .opacity(showButton ? 1 : 0)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                showHeader = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(1.0)) {
                showReading = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.5)) {
                showButton = true
            }
        }
    }
}
