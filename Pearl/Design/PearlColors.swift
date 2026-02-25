import SwiftUI

// MARK: - Pearl Color System
// Dark cosmic void aesthetic with warm gold accents

enum PearlColors {
    // Primary
    static let gold = Color(hex: "C9A84C")
    static let goldLight = Color(hex: "E8D5A3")
    static let goldDim = Color(hex: "8B7635")
    
    // Backgrounds
    static let void = Color(hex: "0A0A0F")
    static let voidLight = Color(hex: "12121A")
    static let surface = Color(hex: "1A1A2E")
    static let surfaceLight = Color(hex: "242440")
    
    // Text
    static let textPrimary = Color(hex: "F5F0E8")
    static let textSecondary = Color(hex: "A09B8C")
    static let textMuted = Color(hex: "6B6760")
    
    // Accents
    static let cosmic = Color(hex: "6366F1")
    static let nebula = Color(hex: "8B5CF6")
    static let stardust = Color(hex: "F59E0B")
    
    // Semantic
    static let success = Color(hex: "34D399")
    static let warning = Color(hex: "FBBF24")
    static let error = Color(hex: "EF4444")
    
    // Gradients
    static let cosmicGradient = LinearGradient(
        colors: [void, surface],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let goldGradient = LinearGradient(
        colors: [gold, goldLight],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let nebulaGradient = LinearGradient(
        colors: [cosmic.opacity(0.3), nebula.opacity(0.1), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
