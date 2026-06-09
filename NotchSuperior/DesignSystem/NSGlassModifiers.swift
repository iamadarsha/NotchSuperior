// NOTCHSUPERIOR ADDITION -- Glass Modifiers

import SwiftUI

private struct NSGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tintOpacity: Double
    let shadowOpacity: Double
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.white.opacity(tintOpacity))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(shadowOpacity), radius: 18, y: 10)
    }
}

extension View {
    func notchGlass() -> some View {
        modifier(
            NSGlassSurfaceModifier(
                cornerRadius: NSTokens.notchExpandedRadius,
                tintOpacity: NSTokens.glassOpacity,
                shadowOpacity: 0.18,
                strokeOpacity: 0.14
            )
        )
    }

    func hudGlass() -> some View {
        modifier(
            NSGlassSurfaceModifier(
                cornerRadius: NSTokens.hudCornerRadius,
                tintOpacity: NSTokens.glassOpacity,
                shadowOpacity: NSTokens.hudShadowOpacity,
                strokeOpacity: 0.16
            )
        )
    }

    func shelfGlass() -> some View {
        modifier(
            NSGlassSurfaceModifier(
                cornerRadius: 18,
                tintOpacity: 0.1,
                shadowOpacity: 0.16,
                strokeOpacity: 0.12
            )
        )
    }

    func widgetGlass() -> some View {
        modifier(
            NSGlassSurfaceModifier(
                cornerRadius: 24,
                tintOpacity: 0.11,
                shadowOpacity: 0.2,
                strokeOpacity: 0.12
            )
        )
    }
}
