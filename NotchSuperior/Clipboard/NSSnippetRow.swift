// ────────────────────────────────────────────────────────
// NotchSuperior — NSSnippetRow.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSSnippetRow: View {
    let snippet: NSSnippet
    @ObservedObject var engine = NSClipboardEngine.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                Text(snippet.body)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if let shortcut = snippet.shortcut {
                Text(shortcut)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            }
            Button(action: { engine.pasteSnippet(snippet) }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button("Copy to Clipboard") { engine.pasteSnippet(snippet) }
            Button("Delete", role: .destructive) { engine.deleteSnippet(snippet) }
        }
    }
}
