// ────────────────────────────────────────────────────────
// NotchSuperior — NSWeatherActivity.swift
// Part of the boring.notch fork
// Phase: 11 — Weather Live Activity
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Shows current temp + condition in the live activity band.
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSWeatherActivity: NSActivity {
    let id = UUID()
    let priority = 3    // lower than media/battery
    let ttl: TimeInterval? = nil    // persists until dismissed

    let data: NSWeatherData

    @MainActor
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 4) {
                Image(systemName: data.symbol)
                    .font(.system(size: 10))
                    .foregroundStyle(.yellow)
                Text(data.tempString)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        )
    }

    @MainActor
    var expandedView: AnyView {
        AnyView(
            HStack(spacing: 12) {
                Image(systemName: data.symbol)
                    .font(.system(size: 28))
                    .foregroundStyle(.yellow)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 2) {
                    Text(data.tempString)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(data.label)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(data.cityName)
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        )
    }
}
