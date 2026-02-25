import SwiftUI

// MARK: - Pearl Typography
// Cormorant Garamond for headings & Pearl's voice
// DM Sans for body & UI elements

enum PearlFonts {
    // MARK: - Font Registration
    
    static func registerFonts() {
        // Register custom fonts from bundle
        let fontNames = [
            "CormorantGaramond-Light",
            "CormorantGaramond-Regular",
            "CormorantGaramond-Medium",
            "CormorantGaramond-SemiBold",
            "CormorantGaramond-Bold",
            "CormorantGaramond-LightItalic",
            "CormorantGaramond-Italic",
            "DMSans-Regular",
            "DMSans-Medium",
            "DMSans-SemiBold",
            "DMSans-Bold",
        ]
        for name in fontNames {
            registerFont(named: name)
        }
    }
    
    private static func registerFont(named name: String) {
        guard let fontURL = Bundle.main.url(forResource: name, withExtension: "ttf"),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else { return }
        CTFontManagerRegisterGraphicsFont(font, nil)
    }
    
    // MARK: - Pearl's Voice (Cormorant Garamond)
    // Used for Pearl's messages, headings, oracle-style text
    
    static func oracle(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Regular", size: size)
    }
    
    static func oracleLight(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Light", size: size)
    }
    
    static func oracleMedium(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Medium", size: size)
    }
    
    static func oracleSemiBold(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-SemiBold", size: size)
    }
    
    static func oracleBold(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Bold", size: size)
    }
    
    static func oracleItalic(_ size: CGFloat) -> Font {
        .custom("CormorantGaramond-Italic", size: size)
    }
    
    // MARK: - UI Text (DM Sans)
    // Used for body text, buttons, labels, user input
    
    static func body(_ size: CGFloat) -> Font {
        .custom("DMSans-Regular", size: size)
    }
    
    static func bodyMedium(_ size: CGFloat) -> Font {
        .custom("DMSans-Medium", size: size)
    }
    
    static func bodySemiBold(_ size: CGFloat) -> Font {
        .custom("DMSans-SemiBold", size: size)
    }
    
    static func bodyBold(_ size: CGFloat) -> Font {
        .custom("DMSans-Bold", size: size)
    }
    
    // MARK: - Preset Styles
    
    static let heroTitle = oracleLight(40)
    static let screenTitle = oracleMedium(32)
    static let sectionTitle = oracleSemiBold(24)
    static let cardTitle = oracleMedium(20)
    static let pearlMessage = oracle(19)
    static let pearlWhisper = oracleItalic(17)
    
    static let bodyLarge = body(17)
    static let bodyRegular = body(15)
    static let bodySmall = body(13)
    static let caption = body(11)
    static let buttonText = bodySemiBold(15)
    static let labelText = bodyMedium(13)
}

// MARK: - Text Style Modifiers

struct PearlOracleStyle: ViewModifier {
    var size: CGFloat = 19
    
    func body(content: Content) -> some View {
        content
            .font(PearlFonts.oracle(size))
            .foregroundColor(PearlColors.goldLight)
            .lineSpacing(6)
    }
}

struct PearlBodyStyle: ViewModifier {
    var size: CGFloat = 15
    
    func body(content: Content) -> some View {
        content
            .font(PearlFonts.body(size))
            .foregroundColor(PearlColors.textPrimary)
            .lineSpacing(4)
    }
}

extension View {
    func oracleStyle(size: CGFloat = 19) -> some View {
        modifier(PearlOracleStyle(size: size))
    }
    
    func pearlBody(size: CGFloat = 15) -> some View {
        modifier(PearlBodyStyle(size: size))
    }
}
