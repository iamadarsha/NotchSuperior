// NOTCHSUPERIOR ADDITION -- HUD Overlay

import SwiftUI

struct NSHUDOverlayView: View {
    @ObservedObject var engine = NSHUDEngine.shared
    @AppStorage("NSHUDPosition") private var hudPosition = NSHUDPosition.inNotch.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var hudNamespace

    var body: some View {
        VStack(spacing: 0) {
            if resolvedPosition == .bottomOfScreen {
                Spacer(minLength: 0)
            }

            VStack(spacing: 10) {
                if let activeHUD = engine.activeHUD {
                    hudBody(for: activeHUD)
                        .transition(reduceMotion ? .opacity : .move(edge: transitionEdge).combined(with: .opacity))
                }
            }
            .frame(maxWidth: 420)
            .padding(.top, resolvedPosition == .belowNotch ? 38 : 10)
            .padding(.bottom, resolvedPosition == .bottomOfScreen ? 32 : 0)

            if resolvedPosition != .bottomOfScreen {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: overlayAlignment)
        .allowsHitTesting(false)
        .animation(reduceMotion ? .easeOut(duration: 0.12) : NSTokens.animationSpring, value: engine.activeHUD?.id)
    }

    @ViewBuilder
    private func hudBody(for event: NSHUDEvent) -> some View {
        switch event {
        case .combined(let events):
            VStack(spacing: 8) {
                ForEach(Array(events.enumerated()), id: \.offset) { entry in
                    hudCard(for: entry.element)
                }
            }
        default:
            hudCard(for: event)
        }
    }

    @ViewBuilder
    private func hudCard(for event: NSHUDEvent) -> some View {
        let card = VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: symbol(for: event))
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 18)
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title(for: event))
                        .font(.caption)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle(for: event) {
                        Text(subtitle)
                            .font(eventValue(for: event) == nil ? .caption2 : .largeTitle.monospacedDigit())
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                }

                Spacer(minLength: 12)

                if let value = eventValue(for: event) {
                    Text("\(Int(value * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            if let value = eventValue(for: event) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: NSTokens.progressHeight)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(10, 220 * CGFloat(min(1, max(0, value)))), height: NSTokens.progressHeight)
                    }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .matchedGeometryEffect(id: event.id, in: hudNamespace)

        switch engine.selectedTheme {
        case .liquidGlass:
            card.hudGlass()
        case .minimal:
            card
                .background(Color.black.opacity(0.82))
                .clipShape(Capsule())
        case .oledBlack:
            card
                .background(
                    RoundedRectangle(cornerRadius: NSTokens.hudCornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.96))
                        .overlay {
                            RoundedRectangle(cornerRadius: NSTokens.hudCornerRadius, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                )
        case .iOSStyle:
            card
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }
                )
                .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        }
    }

    private func symbol(for event: NSHUDEvent) -> String {
        switch event {
        case .volume(let value):
            switch value {
            case 0: return "speaker.slash.fill"
            case 0..<0.33: return "speaker.wave.1.fill"
            case 0.33..<0.66: return "speaker.wave.2.fill"
            default: return "speaker.wave.3.fill"
            }
        case .brightness(let value):
            return value > 0.5 ? "sun.max.fill" : "sun.min.fill"
        case .keyboardBacklight(let value):
            return value > 0.5 ? "light.max" : "light.min"
        case .nowPlaying:
            return "music.note"
        case .combined:
            return "square.stack.3d.up.fill"
        }
    }

    private func title(for event: NSHUDEvent) -> String {
        switch event {
        case .volume:
            return "Volume"
        case .brightness:
            return "Brightness"
        case .keyboardBacklight:
            return "Keyboard"
        case .nowPlaying:
            return "Now Playing"
        case .combined:
            return "System HUD"
        }
    }

    private func subtitle(for event: NSHUDEvent) -> String? {
        switch event {
        case .nowPlaying(let title, let artist):
            if artist.isEmpty {
                return title
            }
            if title.isEmpty {
                return artist
            }
            return "\(title) - \(artist)"
        case .volume, .brightness, .keyboardBacklight:
            return nil
        case .combined:
            return nil
        }
    }

    private func eventValue(for event: NSHUDEvent) -> Float? {
        switch event {
        case .volume(let value), .brightness(let value), .keyboardBacklight(let value):
            return value
        case .nowPlaying, .combined:
            return nil
        }
    }

    private var resolvedPosition: NSHUDPosition {
        NSHUDPosition(rawValue: hudPosition) ?? .inNotch
    }

    private var overlayAlignment: Alignment {
        switch resolvedPosition {
        case .inNotch, .belowNotch:
            return .top
        case .bottomOfScreen:
            return .bottom
        }
    }

    private var transitionEdge: Edge {
        resolvedPosition == .bottomOfScreen ? .bottom : .top
    }
}
