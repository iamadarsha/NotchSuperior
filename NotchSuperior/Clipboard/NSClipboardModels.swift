// ────────────────────────────────────────────────────────
// NotchSuperior — NSClipboardModels.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Cocoa

enum NSClipboardItemType: String, Codable {
    case text, url, image, file, color, unknown
}

struct NSClipboardItem: Identifiable, Codable {
    let id: UUID
    let addedAt: Date
    let type: NSClipboardItemType
    var text: String?           // for .text and .url
    var imageData: Data?        // for .image (PNG)
    var filePath: String?       // for .file
    var colorHex: String?       // for .color (#RRGGBB)
    var isPinned: Bool
    var label: String?          // user-set display label

    // Display helper
    var displayTitle: String {
        label ?? text?.prefix(60).description
             ?? filePath?.split(separator:"/").last.map(String.init)
             ?? "Item"
    }
}

struct NSSnippet: Identifiable, Codable {
    let id: UUID
    var title: String
    var body: String
    var shortcut: String?       // e.g. "/addr" — typed in any app
    var tags: [String]
    var createdAt: Date
}
