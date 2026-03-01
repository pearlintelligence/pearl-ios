import SwiftUI

// MARK: - Name Step
// Sacred moment of introduction — "What shall I call you?"

struct NameStep: View {
    @Binding var name: String
    let onContinue: () -> Void
    
    @State private var showContent = false
    @FocusState private var isNameFocused: Bool
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 20) {
                DiamondSymbol(size: 20)
                
                Text("What shall I call you?")
                    .font(PearlFonts.screenTitle)
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                
                Text("A name carries vibration.\nI want to know yours.")
                    .font(PearlFonts.pearlWhisper)
                    .foregroundColor(PearlColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .padding(.bottom, 48)
            
            // Name input
            VStack(spacing: 8) {
                TextField("", text: $name)
                    .font(PearlFonts.oracleMedium(28))
                    .foregroundColor(PearlColors.goldLight)
                    .multilineTextAlignment(.center)
                    .focused($isNameFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.continue)
                    .onSubmit {
                        if isValid { onContinue() }
                    }
                    .placeholder(when: name.isEmpty) {
                        Text("Your name")
                            .font(PearlFonts.oracleLight(28))
                            .foregroundColor(PearlColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                
                // Subtle underline
                Rectangle()
                    .fill(
                        isNameFocused || !name.isEmpty
                        ? PearlColors.gold.opacity(0.4)
                        : PearlColors.surface
                    )
                    .frame(height: 1)
                    .frame(maxWidth: 200)
                    .animation(.easeInOut(duration: 0.3), value: isNameFocused)
            }
            .padding(.horizontal, 60)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            PearlPrimaryButton("Continue") {
                onContinue()
            }
            .disabled(!isValid)
            .opacity(isValid ? 1.0 : 0.4)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                isNameFocused = true
            }
        }
    }
}

// MARK: - Placeholder Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .center,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
