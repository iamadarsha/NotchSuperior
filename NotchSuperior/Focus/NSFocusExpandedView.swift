// ────────────────────────────────────────────────────────
// NotchSuperior — NSFocusExpandedView.swift
// Part of the boring.notch fork
// Phase: 5 — Focus & Pomodoro Timer
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 26.0, *)
struct NSFocusExpandedView: View {
    weak var engine: NSFocusEngine?
    @ObservedObject var obs = NSFocusEngine.shared

    var body: some View {
        VStack(spacing: 10) {
            // State label
            Text(stateLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(stateColor)

            // Circular progress ring
            ZStack {
                Circle().stroke(.tertiary, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(stateColor, style: StrokeStyle(
                        lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }
            .frame(width: 64, height: 64)
            .overlay {
                Text(timeString)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
            }

            // Round counter
            Text("Round \(obs.session.completedRounds + 1)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // Controls
            HStack(spacing: 16) {
                Button(action: { obs.skip() }) {
                    Image(systemName: "forward.fill")
                }
                .buttonStyle(.borderless)

                if obs.state == .working || obs.state == .breaking || obs.state == .longBreak {
                    Button(action: {
                        if obs.isPaused {
                            obs.resume()
                        } else {
                            obs.pause()
                        }
                    }) {
                        Image(systemName: obs.isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.borderless)
                }

                Button(action: { obs.stop() }) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(12)
        .frame(minWidth: 140)
    }

    // compute from engine state and session lengths
    private var progress: Double {
        let total: Int
        switch obs.state {
        case .working:   total = obs.session.workMinutes * 60
        case .breaking:  total = obs.session.breakMinutes * 60
        case .longBreak: total = obs.session.longBreakMinutes * 60
        case .idle:      return 0
        }
        return total > 0 ? 1.0 - Double(obs.secondsRemaining) / Double(total) : 0
    }

    private var stateLabel: String {
        if obs.isPaused {
            return "Paused"
        }
        switch obs.state {
        case .working:   return "Focus Time"
        case .breaking:  return "Short Break"
        case .longBreak: return "Long Break"
        case .idle:      return "Ready"
        }
    }

    private var stateColor: Color {
        switch obs.state {
        case .working:   return .red
        case .breaking:  return .green
        case .longBreak: return .blue
        case .idle:      return .secondary
        }
    }

    private var timeString: String {
        let s = obs.secondsRemaining
        return String(format: "%02d:%02d", s/60, s%60)
    }
}
