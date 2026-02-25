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
                
                Text("The exact moment shapes the lens through which you see the world.")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .multilineTextAlignment(.center)
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
                    .padding(.top, 60)
                
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

// MARK: - Generating Step

struct GeneratingStep: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var currentPhrase = 0
    @State private var phraseOpacity: Double = 1.0
    @State private var rotationAngle: Double = 0
    
    let phrases = [
        "Reading the stars...",
        "Mapping your cosmic fingerprint...",
        "Consulting the ancient wisdom...",
        "Finding the patterns in your design...",
        "Pearl is seeing you for the first time..."
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated cosmic ring
            ZStack {
                // Outer ring
                Circle()
                    .stroke(PearlColors.gold.opacity(0.2), lineWidth: 1)
                    .frame(width: 160, height: 160)
                
                // Rotating ring
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        PearlColors.goldGradient,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Inner ring
                Circle()
                    .stroke(PearlColors.gold.opacity(0.15), lineWidth: 1)
                    .frame(width: 120, height: 120)
                
                // Second rotating ring
                Circle()
                    .trim(from: 0, to: 0.2)
                    .stroke(
                        PearlColors.goldLight.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-rotationAngle * 0.7))
                
                // Center diamond
                Text("✦")
                    .font(.system(size: 32))
                    .foregroundColor(PearlColors.gold)
                    .pearlGlow()
            }
            
            // Animated phrases
            Text(phrases[currentPhrase])
                .font(PearlFonts.pearlWhisper)
                .foregroundColor(PearlColors.textSecondary)
                .opacity(phraseOpacity)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .onAppear {
            // Start rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // Cycle through phrases
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.4)) {
                    phraseOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    currentPhrase = (currentPhrase + 1) % phrases.count
                    withAnimation(.easeInOut(duration: 0.4)) {
                        phraseOpacity = 1
                    }
                }
            }
            
            // Generate blueprint
            Task {
                await viewModel.generateBlueprint()
            }
        }
    }
}

// MARK: - First Reading Step

struct FirstReadingStep: View {
    let reading: String
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var showButton = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text("✦")
                        .font(.system(size: 36))
                        .foregroundColor(PearlColors.gold)
                        .pearlGlow()
                    
                    Text("Pearl Speaks")
                        .font(PearlFonts.screenTitle)
                        .foregroundColor(PearlColors.goldLight)
                }
                .padding(.top, 60)
                .opacity(showContent ? 1 : 0)
                
                // Pearl's first reading
                Text(reading)
                    .font(PearlFonts.pearlMessage)
                    .foregroundColor(PearlColors.goldLight)
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
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
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.0)) {
                showButton = true
            }
        }
    }
}
