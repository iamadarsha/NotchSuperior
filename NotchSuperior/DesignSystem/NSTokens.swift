// ────────────────────────────────────────────────────────
// NotchSuperior — NSTokens.swift
// macOS 26/27 Liquid Glass + Siri Aurora design tokens
// Includes full Siri-grade spring/bounce/morph animation system
// ────────────────────────────────────────────────────────

import SwiftUI

enum NSTokens {

    // MARK: — Geometry
    static let notchCornerRadius: CGFloat = 14
    static let notchExpandedRadius: CGFloat = 24
    static let hudCornerRadius: CGFloat = 26
    static let shelfCornerRadius: CGFloat = 20
    static let progressHeight: CGFloat = 2.5

    // MARK: — Glass surface
    static let glassBlur: CGFloat = 28
    static let glassOpacity: Double = 0.08
    static let glassStrokeOpacity: Double = 0.13
    static let hudShadowOpacity: Double = 0.22
    static let hairlineOpacity: Double = 0.16

    // MARK: — macOS 27 Siri Aurora colors
    // Spectrum: violet → blue → teal → mint — matches Apple Siri glow palette
    static let auroraViolet   = Color(red: 0.55, green: 0.20, blue: 0.95)
    static let auroraBlue     = Color(red: 0.20, green: 0.50, blue: 1.00)
    static let auroraTeal     = Color(red: 0.00, green: 0.80, blue: 0.85)
    static let auroraMint     = Color(red: 0.20, green: 0.95, blue: 0.75)
    static let auroraRose     = Color(red: 1.00, green: 0.30, blue: 0.55)
    static let auroraAmber    = Color(red: 1.00, green: 0.65, blue: 0.10)

    /// 5-stop aurora gradient used by NSSiriAuroraView
    static var auroraGradient: AngularGradient {
        AngularGradient(
            colors: [auroraViolet, auroraBlue, auroraTeal, auroraMint,
                     auroraRose, auroraAmber, auroraViolet],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360))
    }

    // MARK: — Profile bypass check
    private static var shouldAnimate: Bool {
        let presenting  = UserDefaults.standard.bool(forKey: "NSProfilePresenting")
        let batterySaver = UserDefaults.standard.bool(forKey: "NSProfileBatterySaver")
        return !presenting && !batterySaver
    }

    // MARK: — Animation system

    /// Standard notch open/close spring — snappy, physical
    static var animationSpring: Animation {
        shouldAnimate
            ? .spring(response: 0.42, dampingFraction: 0.72)
            : .linear(duration: 0.001)
    }

    /// Siri-grade "launch" spring — overshoots slightly like iOS 17+ bounce
    static var siriLaunchSpring: Animation {
        shouldAnimate
            ? .spring(response: 0.38, dampingFraction: 0.60, blendDuration: 0.1)
            : .linear(duration: 0.001)
    }

    /// HUD entrance — fast and precise
    static var hudEntrance: Animation {
        shouldAnimate
            ? .spring(response: 0.30, dampingFraction: 0.78)
            : .linear(duration: 0.001)
    }

    /// HUD dismiss — quick ease-out, no bounce
    static let hudDismiss = Animation.easeOut(duration: 0.20)

    /// Live Activity morph — smooth pill-to-card expansion
    static var liveActivityMorph: Animation {
        shouldAnimate
            ? .spring(response: 0.50, dampingFraction: 0.68)
            : .linear(duration: 0.001)
    }

    /// Aurora rotation period (seconds)
    static let auroraRotationDuration: Double = 6.0

    /// Aurora breathing pulse period (seconds)
    static let auroraBreathDuration: Double = 3.5

    /// Subtle widget appear
    static var widgetAppear: Animation {
        shouldAnimate
            ? .spring(response: 0.35, dampingFraction: 0.82)
            : .linear(duration: 0.001)
    }

    /// Shelf tile pop
    static var shelfPop: Animation {
        shouldAnimate
            ? .spring(response: 0.28, dampingFraction: 0.65)
            : .linear(duration: 0.001)
    }

    // Legacy alias for call-sites that use .subtleSpring
    static let subtleSpring = Animation.spring(response: 0.25, dampingFraction: 0.85)
    static let dismissAnimation = Animation.easeOut(duration: 0.18)
}
