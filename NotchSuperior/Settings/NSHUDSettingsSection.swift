// NOTCHSUPERIOR ADDITION -- HUD Settings

import SwiftUI

enum NSHUDPosition: String, CaseIterable, Identifiable {
    case inNotch = "In notch"
    case belowNotch = "Below notch"
    case bottomOfScreen = "Bottom of screen"

    var id: String { rawValue }
}

@available(macOS 14.0, *)
struct NSHUDSettingsSection: View {
    @AppStorage("NSHUDTheme") private var hudTheme = NSHUDTheme.liquidGlass.rawValue
    @AppStorage("NSHUDDismissDuration") private var dismissDuration = 2.5
    @AppStorage("NSHUDCombined") private var combinedHUDEnabled = true
    @AppStorage("NSHUDPosition") private var hudPosition = NSHUDPosition.inNotch.rawValue

    var body: some View {
        Form {
            Section {
                Picker("HUD Theme", selection: $hudTheme) {
                    ForEach(NSHUDTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hide HUD after \(dismissDuration, specifier: "%.1f")s")
                        Spacer()
                        Text("\(dismissDuration, specifier: "%.1f")s")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $dismissDuration, in: 1.0...5.0, step: 0.5)
                }

                Toggle("Show Now Playing + Volume in one card", isOn: $combinedHUDEnabled)

                Picker("HUD position", selection: $hudPosition) {
                    ForEach(NSHUDPosition.allCases) { position in
                        Text(position.rawValue).tag(position.rawValue)
                    }
                }
            } header: {
                Text("HUD & Display")
            } footer: {
                Text("Liquid Glass controls apply to the NotchSuperior HUD overlay and live HUD presentation behavior.")
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding()
        .navigationTitle("HUD & Display")
        .tint(.effectiveAccent)
    }
}

private extension NSHUDTheme {
    var label: String {
        switch self {
        case .liquidGlass:
            return "Liquid Glass"
        case .minimal:
            return "Minimal"
        case .oledBlack:
            return "OLED Black"
        case .iOSStyle:
            return "iOS Style"
        }
    }
}
