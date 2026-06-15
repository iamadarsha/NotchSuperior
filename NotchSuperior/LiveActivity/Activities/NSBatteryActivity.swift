// ────────────────────────────────────────────────────────
// NotchSuperior — NSBatteryActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Updated: 2026-06-15 — added time-remaining display
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSBatteryActivity: NSActivity {
    let id = UUID()
    let priority = 7
    let ttl: TimeInterval? = nil

    @MainActor
    var compactView: AnyView {
        AnyView(NSBatteryCompactView())
    }

    @MainActor
    var expandedView: AnyView {
        AnyView(NSBatteryExpandedView())
    }
}

struct NSBatteryCompactView: View {
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryIcon)
                .font(.system(size: 10))
                .foregroundStyle(batteryColor)
            Text("\(Int(batteryModel.levelBattery))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 6)
    }

    private var batteryIcon: String {
        if batteryModel.isCharging { return "battery.100.bolt" }
        if batteryModel.levelBattery < 20 { return "battery.25" }
        if batteryModel.levelBattery < 50 { return "battery.50" }
        if batteryModel.levelBattery < 75 { return "battery.75" }
        return "battery.100"
    }

    private var batteryColor: Color {
        if batteryModel.isCharging { return .green }
        if batteryModel.levelBattery < 20 { return .red }
        if batteryModel.levelBattery < 40 { return .orange }
        return .primary
    }
}

struct NSBatteryExpandedView: View {
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared

    private var timeRemainingText: String? {
        // BatteryStatusViewModel exposes timeToFullCharge; try to derive time-to-empty
        // from IOPSCopyPowerSourcesInfo if available
        guard !batteryModel.isCharging else {
            if batteryModel.timeToFullCharge > 0 {
                let h = batteryModel.timeToFullCharge / 60
                let m = batteryModel.timeToFullCharge % 60
                if h > 0 { return "\(h)h \(m)m until full" }
                return "\(m)m until full"
            }
            return "Charging…"
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(batteryModel.isCharging ? "Charging" : "Battery")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: batteryModel.isCharging ? "battery.100.bolt" : "battery.75")
                    .font(.system(size: 22))
                    .foregroundStyle(batteryModel.levelBattery < 20 ? .red : (batteryModel.isCharging ? .green : .primary))
                    .symbolRenderingMode(.hierarchical)
                Text("\(Int(batteryModel.levelBattery))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(batteryModel.levelBattery < 20 ? Color.red : (batteryModel.isCharging ? .green : .white))
                        .frame(width: geo.size.width * CGFloat(batteryModel.levelBattery) / 100)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 4)

            if let timeText = timeRemainingText {
                Text(timeText)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            } else if !batteryModel.isCharging && batteryModel.levelBattery < 20 {
                Text("Battery Low")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(10)
        .frame(width: 180)
    }
}
