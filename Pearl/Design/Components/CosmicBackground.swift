import SwiftUI

// MARK: - Cosmic Background
// Animated starfield background used throughout the app

struct CosmicBackground: View {
    @State private var animateStars = false
    
    var body: some View {
        ZStack {
            // Base void
            PearlColors.void
                .ignoresSafeArea()
            
            // Nebula glow
            RadialGradient(
                colors: [
                    PearlColors.cosmic.opacity(0.08),
                    PearlColors.nebula.opacity(0.04),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            // Secondary glow
            RadialGradient(
                colors: [
                    PearlColors.gold.opacity(0.04),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            // Star particles
            StarFieldView()
                .opacity(animateStars ? 0.8 : 0.4)
                .animation(
                    .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                    value: animateStars
                )
        }
        .onAppear {
            animateStars = true
        }
    }
}

// MARK: - Star Field

struct StarFieldView: View {
    let starCount = 60
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<starCount, id: \.self) { i in
                StarParticle(index: i, bounds: geometry.size)
            }
        }
    }
}

struct StarParticle: View {
    let index: Int
    let bounds: CGSize
    
    @State private var opacity: Double = 0
    
    private var position: CGPoint {
        // Deterministic pseudo-random position based on index
        let x = CGFloat((index * 997 + 41) % Int(max(bounds.width, 1)))
        let y = CGFloat((index * 653 + 89) % Int(max(bounds.height, 1)))
        return CGPoint(x: x, y: y)
    }
    
    private var size: CGFloat {
        CGFloat([1.0, 1.5, 2.0, 1.0, 0.8][index % 5])
    }
    
    private var animationDuration: Double {
        Double([3.0, 4.0, 5.0, 3.5, 4.5][index % 5])
    }
    
    var body: some View {
        Circle()
            .fill(PearlColors.goldLight.opacity(opacity))
            .frame(width: size, height: size)
            .position(position)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index % 10) * 0.3)
                ) {
                    opacity = Double([0.6, 0.8, 1.0, 0.5, 0.7][index % 5])
                }
            }
    }
}

// MARK: - Diamond Motif

struct DiamondSymbol: View {
    var size: CGFloat = 12
    var color: Color = PearlColors.gold
    
    var body: some View {
        Text("✦")
            .font(.system(size: size))
            .foregroundColor(color)
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    var color: Color = PearlColors.gold
    var radius: CGFloat = 8
    var opacity: Double = 0.5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius * 2)
    }
}

extension View {
    func pearlGlow(color: Color = PearlColors.gold, radius: CGFloat = 8) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Shimmer Animation

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        PearlColors.goldLight.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .init(x: phase - 0.5, y: 0.5),
                    endPoint: .init(x: phase + 0.5, y: 0.5)
                )
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
