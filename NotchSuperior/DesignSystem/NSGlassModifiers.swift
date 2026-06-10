// ────────────────────────────────────────────────────────
// NotchSuperior — NSGlassModifiers.swift
// macOS 26/27 Liquid Glass surface system
//
// Uses the new glassEffect() modifier (macOS 26 SDK) with
// backgroundStyle(.glass) for true system-integrated Liquid Glass.
// Falls back to .ultraThinMaterial on macOS 15 and earlier.
//
// Siri glow ring: animated multi-stop gradient stroke that wraps
// any surface — used on AI Chat, HUD cards, and Live Activities.
// ────────────────────────────────────────────────────────

import SwiftUI

// MARK: — Core glass surface modifier

private struct NSGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tintOpacity: Double
    let shadowOpacity: Double
    let strokeOpacity: Double

    func body(content: Content) -> some View {
        #if compiler(>=6.3)
        if #available(macOS 26.0, *) {
            // macOS 26+: true Liquid Glass with system-depth rendering
            content
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 0.75)
                }
                .shadow(color: .black.opacity(shadowOpacity), radius: 20, y: 10)
        } else {
            fallbackBody(content: content)
        }
        #else
        fallbackBody(content: content)
        #endif
    }

    private func fallbackBody(content: Content) -> some View {
        // macOS 13–15 fallback: UIKit-style ultraThinMaterial
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
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 0.75)
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(shadowOpacity), radius: 18, y: 10)
    }
}

// MARK: — Siri aurora glow ring modifier

struct NSSiriGlowModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double       // 0.0 – 1.0
    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius + 3, style: .continuous)
                    .stroke(
                        AngularGradient(
                            colors: [
                                NSTokens.auroraViolet.opacity(intensity),
                                NSTokens.auroraBlue.opacity(intensity),
                                NSTokens.auroraTeal.opacity(intensity),
                                NSTokens.auroraMint.opacity(intensity),
                                NSTokens.auroraRose.opacity(intensity),
                                NSTokens.auroraViolet.opacity(intensity)
                            ],
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)),
                        lineWidth: 1.5
                    )
                    .blur(radius: 3)
                    .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(
                    .linear(duration: NSTokens.auroraRotationDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: — Liquid Glass morphing pill (Live Activities, HUDs)

struct NSLiquidPillModifier: ViewModifier {
    let cornerRadius: CGFloat
    @State private var glowOpacity: Double = 0.06

    func body(content: Content) -> some View {
        content
            .modifier(NSGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                tintOpacity: NSTokens.glassOpacity,
                shadowOpacity: 0.18,
                strokeOpacity: NSTokens.glassStrokeOpacity))
            .overlay {
                // Breathing inner glow — mimics Siri waveform ambient light
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                NSTokens.auroraBlue.opacity(glowOpacity),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60)
                    )
                    .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: NSTokens.auroraBreathDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    glowOpacity = 0.14
                }
            }
    }
}

// MARK: — View extensions

extension View {

    /// Standard notch-expanded glass surface (macOS 26 Liquid Glass / macOS 15 fallback)
    func notchGlass() -> some View {
        modifier(NSGlassSurfaceModifier(
            cornerRadius: NSTokens.notchExpandedRadius,
            tintOpacity: NSTokens.glassOpacity,
            shadowOpacity: 0.18,
            strokeOpacity: NSTokens.glassStrokeOpacity))
    }

    /// HUD card surface
    func hudGlass() -> some View {
        modifier(NSGlassSurfaceModifier(
            cornerRadius: NSTokens.hudCornerRadius,
            tintOpacity: NSTokens.glassOpacity,
            shadowOpacity: NSTokens.hudShadowOpacity,
            strokeOpacity: NSTokens.glassStrokeOpacity))
    }

    /// Shelf tile surface
    func shelfGlass() -> some View {
        modifier(NSGlassSurfaceModifier(
            cornerRadius: NSTokens.shelfCornerRadius,
            tintOpacity: 0.10,
            shadowOpacity: 0.16,
            strokeOpacity: 0.12))
    }

    /// Widget / card surface
    func widgetGlass() -> some View {
        modifier(NSGlassSurfaceModifier(
            cornerRadius: 24,
            tintOpacity: 0.11,
            shadowOpacity: 0.20,
            strokeOpacity: 0.12))
    }

    /// Siri aurora glow ring — use on AI chat, HUD cards, live activity pills
    func siriGlow(intensity: Double = 0.75, cornerRadius: CGFloat = 24) -> some View {
        modifier(NSSiriGlowModifier(cornerRadius: cornerRadius, intensity: intensity))
    }

    /// Liquid Glass morphing pill — full system for live activities and HUDs
    func liquidPill(cornerRadius: CGFloat = 22) -> some View {
        modifier(NSLiquidPillModifier(cornerRadius: cornerRadius))
    }
}
