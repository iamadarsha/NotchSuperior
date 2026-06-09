// ────────────────────────────────────────────────────────
// NotchSuperior — NSTimerActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSTimerActivity: NSActivity {
    let id = UUID()
    let priority = 3
    let ttl: TimeInterval? = nil

    let title: String
    let endDate: Date

    var compactView: AnyView {
        AnyView(NSTimerCompactView(title: title, endDate: endDate))
    }

    var expandedView: AnyView {
        AnyView(NSTimerExpandedView(title: title, endDate: endDate))
    }
}

struct NSTimerCompactView: View {
    let title: String
    let endDate: Date

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
            
            Text(endDate, style: .timer)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 6)
    }
}

struct NSTimerExpandedView: View {
    let title: String
    let endDate: Date

    var body: some View {
        VStack(spacing: 6) {
            Label(title, systemImage: "timer")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.orange)
            
            Text(endDate, style: .timer)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text("Ends at " + endDate.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(width: 180)
    }
}
