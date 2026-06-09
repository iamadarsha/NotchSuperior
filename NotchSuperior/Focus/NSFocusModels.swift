// ────────────────────────────────────────────────────────
// NotchSuperior — NSFocusModels.swift
// Part of the boring.notch fork
// Phase: 5 — Focus & Pomodoro Timer
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Foundation

enum NSFocusMode: String, Codable, CaseIterable {
    case pomodoro, flow, custom
    var displayName: String { rawValue.capitalized }
}

struct NSFocusSession: Identifiable, Codable {
    let id: UUID
    let mode: NSFocusMode
    var workMinutes: Int       // default: pomodoro=25, flow=52, custom=user
    var breakMinutes: Int      // default: pomodoro=5,  flow=17, custom=user
    var longBreakMinutes: Int  // default: 15
    var completedRounds: Int
    var startedAt: Date?
}
