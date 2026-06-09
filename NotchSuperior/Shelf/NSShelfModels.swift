// ────────────────────────────────────────────────────────
// NotchSuperior — NSShelfModels.swift
// Part of the boring.notch fork
// Phase: 3 — Shelf 2.0
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Cocoa

struct NSShelfItem: Identifiable, Codable {
    let id: UUID
    let url: URL
    let addedAt: Date
    var stackID: UUID
    
    var name: String {
        url.lastPathComponent
    }
    
    var thumbnail: NSImage? {
        NSWorkspace.shared.icon(forFile: url.path)
    }
}

enum NSShelfExpiry: Codable, Equatable {
    case never
    case onReboot
    case after(TimeInterval)

    func expiresAt(from date: Date) -> Date? {
        switch self {
        case .never: return nil
        case .onReboot: return nil  // checked at launch
        case .after(let t): return date.addingTimeInterval(t)
        }
    }
}

struct NSShelfStack: Identifiable, Codable {
    let id: UUID
    var name: String
    var expiry: NSShelfExpiry
    var items: [NSShelfItem]
    var showBadge: Bool
}
