// ────────────────────────────────────────────────────────
// NotchSuperior — NSBatteryActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSBatteryActivity: NSActivity {
    let id = UUID()
    let priority = 7
    let ttl: TimeInterval? = nil

    var compactView: AnyView {
        AnyView(NSBatteryCompactView())
    }

    var expandedView: AnyView {
        AnyView(NSBatteryExpandedView())
    }
}

struct NSBatteryCompactView: View {
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: batteryModel.isCharging ? "battery.100.bolt" : (batteryModel.levelBattery < 20 ? "battery.25" : "battery.75"))
                .font(.system(size: 10))
                .foregroundStyle(batteryModel.levelBattery < 20 ? .red : (batteryModel.isCharging ? .green : .primary))
            
            Text("\(Int(batteryModel.levelBattery))%")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 6)
    }
}

struct NSBatteryExpandedView: View {
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared

    var body: some View {
        VStack(spacing: 6) {
            Text("Battery Status")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Image(systemName: batteryModel.isCharging ? "battery.100.bolt" : (batteryModel.levelBattery < 20 ? "battery.25" : "battery.100"))
                    .font(.system(size: 20))
                    .foregroundStyle(batteryModel.levelBattery < 20 ? .red : (batteryModel.isCharging ? .green : .primary))
                
                Text("\(Int(batteryModel.levelBattery))%")
                    .font(.system(size: 20, weight: .bold))
            }
            
            Text(batteryModel.isCharging ? "Charging" : (batteryModel.levelBattery < 20 ? "Battery Low" : "Discharging"))
                .font(.system(size: 10))
                .foregroundStyle(batteryModel.levelBattery < 20 ? Color.red : Color.secondary)
        }
        .padding(10)
        .frame(width: 160)
    }
}
