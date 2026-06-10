// ────────────────────────────────────────────────────────
// NotchSuperior — NSSiriAuroraView.swift
// macOS 27 Siri-style aurora background
//
// A layered, animated spectrum glow — rotating angular gradient
// masked through a radial vignette + breathing scale pulse.
// Used behind AI Chat, AI Notes, HUD cards, and Command Launcher.
//
// Usage:
//   ZStack {
//       NSSiriAuroraView()
//       // your content on top
//   }
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSSiriAuroraView: View {
    /// Controls how vivid the aurora is (0 = invisible, 1 = full spectrum)
    var intensity: Double = 0.55
    /// Blurs the raw gradient — higher = softer/more ambient
    var blur: CGFloat = 38

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.92
    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1 — slow-rotating angular spectrum
                AngularGradient(
                    colors: [
                        NSTokens.auroraViolet.opacity(intensity),
                        NSTokens.auroraBlue.opacity(intensity * 0.9),
                        NSTokens.auroraTeal.opacity(intensity),
                        NSTokens.auroraMint.opacity(intensity * 0.8),
                        NSTokens.auroraRose.opacity(intensity * 0.6),
                        NSTokens.auroraAmber.opacity(intensity * 0.4),
                        NSTokens.auroraViolet.opacity(intensity)
                    ],
                    center: .center)
                .rotationEffect(.degrees(rotation))
                .blur(radius: blur)
                .scaleEffect(scale)

                // Layer 2 — radial vignette mask (dark center → transparent edge)
                RadialGradient(
                    colors: [.black.opacity(0.45), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.55
                )
                .blendMode(.multiply)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(opacity)
        }
        .allowsHitTesting(false)
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.6)) { opacity = 1 }
            // Continuous slow rotation
            withAnimation(
                .linear(duration: NSTokens.auroraRotationDuration)
                .repeatForever(autoreverses: false)
            ) { rotation = 360 }
            // Breathing scale
            withAnimation(
                .easeInOut(duration: NSTokens.auroraBreathDuration)
                .repeatForever(autoreverses: true)
            ) { scale = 1.08 }
        }
        .onDisappear {
            withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
        }
    }
}

// MARK: — Compact Siri waveform bar (for HUD + compact live activity)

struct NSSiriWaveformBar: View {
    var barCount: Int = 5
    var color: Color = NSTokens.auroraBlue
    @State private var heights: [CGFloat] = []

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [NSTokens.auroraViolet, color, NSTokens.auroraTeal],
                            startPoint: .bottom,
                            endPoint: .top)
                    )
                    .frame(width: 3,
                           height: heights.indices.contains(i) ? heights[i] : 6)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.28...0.52))
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.07),
                        value: heights.indices.contains(i) ? heights[i] : 0)
            }
        }
        .onAppear {
            heights = (0..<barCount).map { _ in CGFloat.random(in: 6...22) }
            animate()
        }
    }

    private func animate() {
        Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
            withAnimation {
                heights = (0..<barCount).map { _ in CGFloat.random(in: 6...22) }
            }
        }
    }
}

// MARK: — Siri ring (circular breathing border used on camera + AI views)

struct NSSiriRingView: View {
    var size: CGFloat = 44
    var intensity: Double = 0.8
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        NSTokens.auroraViolet.opacity(intensity),
                        NSTokens.auroraBlue.opacity(intensity),
                        NSTokens.auroraTeal.opacity(intensity),
                        NSTokens.auroraMint.opacity(intensity),
                        NSTokens.auroraViolet.opacity(intensity)
                    ],
                    center: .center,
                    startAngle: .degrees(rotation),
                    endAngle: .degrees(rotation + 360)
                ),
                lineWidth: 2.5
            )
            .frame(width: size, height: size)
            .blur(radius: 2)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    scale = 1.12
                }
            }
    }
}
