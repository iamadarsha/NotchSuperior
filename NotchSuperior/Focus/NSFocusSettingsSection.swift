// ────────────────────────────────────────────────────────
// NotchSuperior — NSFocusSettingsSection.swift
// Part of the boring.notch fork
// Phase: 5 — Focus & Pomodoro Timer
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 26.0, *)
struct NSFocusSettingsSection: View {
    @AppStorage("NSFocusWorkMinutes")  var workMin: Int = 25
    @AppStorage("NSFocusBreakMinutes") var breakMin: Int = 5
    @AppStorage("NSFocusLongBreak")    var longMin: Int = 15
    @AppStorage("NSFocusMode")         var modeRaw: String = "pomodoro"

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Focus Mode", selection: $modeRaw) {
                    ForEach(NSFocusMode.allCases, id:\.rawValue) { m in
                        Text(m.displayName).tag(m.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Durations (minutes)") {
                Stepper("Work: \(workMin) min",  value: $workMin,  in: 1...120)
                Stepper("Break: \(breakMin) min", value: $breakMin, in: 1...60)
                Stepper("Long break: \(longMin) min", value: $longMin, in: 5...60)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Focus & Pomodoro")
    }
}
