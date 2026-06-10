// ────────────────────────────────────────────────────────
// NotchSuperior — NSFocusActivity.swift
// Part of the boring.notch fork
// Phase: 5 — Focus & Pomodoro Timer
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSFocusActivity: NSActivity {
    let id = UUID()
    let priority = 7
    let ttl: TimeInterval? = nil
    weak var engine: NSFocusEngine?

    @MainActor var compactView: AnyView {
        AnyView(
            HStack(spacing: 4) {
                Image(systemName: stateIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(stateColor)
                Text(timeString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        )
    }

    @MainActor var expandedView: AnyView {
        AnyView(NSFocusExpandedView(engine: engine))
    }

    @MainActor private var stateIcon: String {
        switch engine?.state {
        case .working:    return "timer"
        case .breaking:   return "cup.and.saucer"
        case .longBreak:  return "moon"
        default:          return "timer"
        }
    }

    @MainActor private var stateColor: Color {
        switch engine?.state {
        case .working:   return .red
        case .breaking:  return .green
        case .longBreak: return .blue
        default:         return .secondary
        }
    }

    @MainActor private var timeString: String {
        let s = engine?.secondsRemaining ?? 0
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
