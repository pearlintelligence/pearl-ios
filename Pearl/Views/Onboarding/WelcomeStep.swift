import SwiftUI

// MARK: - Welcome Step
// "I've been waiting for you."

struct WelcomeStep: View {
    let onContinue: () -> Void
    
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showDiamond = false
    @State private var showButton = false
    @State private var diamondGlow = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Diamond motif
            Text("✦")
                .font(.system(size: 48))
                .foregroundColor(PearlColors.gold)
                .opacity(showDiamond ? 1 : 0)
                .scaleEffect(showDiamond ? 1 : 0.5)
                .pearlGlow(color: PearlColors.gold, radius: diamondGlow ? 20 : 8)
                .animation(
                    .easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: diamondGlow
                )
                .padding(.bottom, 32)
            
            // Title
            Text("Pearl")
                .font(PearlFonts.heroTitle)
                .foregroundColor(PearlColors.goldLight)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("I've been waiting for you.")
                .font(PearlFonts.pearlWhisper)
                .foregroundColor(PearlColors.textSecondary)
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 10)
                .padding(.bottom, 8)
            
            Text("Your Personal Spirit Guide")
                .font(PearlFonts.bodyRegular)
                .foregroundColor(PearlColors.textMuted)
                .opacity(showSubtitle ? 1 : 0)
            
            Spacer()
            
            // Continue button
            VStack(spacing: 16) {
                PearlPrimaryButton("Begin Your Journey", icon: "sparkles") {
                    onContinue()
                }
                
                Text("Ancient Wisdom · Cosmic Intelligence")
                    .font(PearlFonts.caption)
                    .foregroundColor(PearlColors.textMuted)
            }
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .onAppear {
            // Staggered entrance animation
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                showDiamond = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(1.3)) {
                showSubtitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.0)) {
                showButton = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                diamondGlow = true
            }
        }
    }
}
