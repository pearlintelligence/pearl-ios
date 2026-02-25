import SwiftUI

// MARK: - Pearl Button Styles

struct PearlPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(PearlColors.void)
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    Text(title)
                        .font(PearlFonts.buttonText)
                }
            }
            .foregroundColor(PearlColors.void)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                PearlColors.goldGradient
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            .pearlGlow(color: PearlColors.gold, radius: 6)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.8 : 1.0)
    }
}

struct PearlSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(title)
                    .font(PearlFonts.buttonText)
            }
            .foregroundColor(PearlColors.gold)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(PearlColors.gold.opacity(0.4), lineWidth: 1)
                    .background(
                        PearlColors.gold.opacity(0.05)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
            )
        }
    }
}

struct PearlTextButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PearlFonts.bodyMedium(15))
                .foregroundColor(PearlColors.textSecondary)
                .underline(color: PearlColors.textMuted)
        }
    }
}
