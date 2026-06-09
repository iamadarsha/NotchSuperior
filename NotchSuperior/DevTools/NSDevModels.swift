// ────────────────────────────────────────────────────────
// NotchSuperior — NSDevModels.swift
// Part of the boring.notch fork
// Phase: 9 — Dev / Power-User Tools
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSDevStatusItem: Identifiable {
    let id: UUID
    var label: String
    var value: String
    var status: NSDevStatus
    var icon: String  // SF Symbol
}

enum NSDevStatus {
    case ok, warn, error, loading
    var color: Color {
        switch self {
        case .ok:      return .green
        case .warn:    return .yellow
        case .error:   return .red
        case .loading: return .secondary
        }
    }
}

struct NSDevConfig: Codable {
    var gitRepoPath: String        // e.g. ~/code/myapp
    var dockerEnabled: Bool
    var latencyHost: String        // e.g. api.myapp.com
    var latencyIntervalSec: Double // default 30
}
