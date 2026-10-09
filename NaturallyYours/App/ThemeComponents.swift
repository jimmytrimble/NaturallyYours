import SwiftUI

// MARK: - Shared brand gradient

extension Color {
    /// A deeper rose used as the end stop of the brand gradient.
    static let nyPinkDark = Color(red: 0.85, green: 0.28, blue: 0.5)
}

extension LinearGradient {
    /// The signature pink → rose gradient used for primary calls to action.
    static var nyBrand: LinearGradient {
        LinearGradient(
            colors: [Color.nyPink, Color.nyPinkDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Primary button style

/// A polished, full-width gradient "pill" button used for primary actions across the app.
struct NYPrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .foregroundStyle(.white)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 20 : 32)
            .padding(.vertical, 15)
            .background(LinearGradient.nyBrand)
            .clipShape(Capsule())
            .shadow(color: Color.nyPink.opacity(0.4), radius: 10, y: 5)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == NYPrimaryButtonStyle {
    static var nyPrimary: NYPrimaryButtonStyle { NYPrimaryButtonStyle() }
    static func nyPrimary(fullWidth: Bool) -> NYPrimaryButtonStyle { NYPrimaryButtonStyle(fullWidth: fullWidth) }
}

/// A secondary outlined pill button (pink outline, pink text) for lower-emphasis actions.
struct NYSecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .foregroundStyle(.nyPink)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 20 : 32)
            .padding(.vertical, 14)
            .background(
                Capsule().stroke(Color.nyPink, lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == NYSecondaryButtonStyle {
    static var nySecondary: NYSecondaryButtonStyle { NYSecondaryButtonStyle() }
}

// MARK: - Screen title

/// A serif screen title used in place of plain navigation titles for a more editorial feel.
struct NYScreenTitle: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .foregroundStyle(.nyBlack)
            if let subtitle {
                Text(subtitle)
                    .font(.nyCaption(13))
                    .foregroundStyle(.nyGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
