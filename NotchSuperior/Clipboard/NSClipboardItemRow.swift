// ────────────────────────────────────────────────────────
// NotchSuperior — NSClipboardItemRow.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSClipboardItemRow: View {
    let item: NSClipboardItem
    @ObservedObject var engine = NSClipboardEngine.shared

    var body: some View {
        HStack(spacing: 8) {
            // Type icon
            Image(systemName: typeIcon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            // Preview / Display Title
            Group {
                if item.type == .image, let data = item.imageData,
                   let nsImg = NSImage(data: data) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else if item.type == .color, let hex = item.colorHex {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: NSColor(hex: hex) ?? .clear))
                            .frame(width: 16, height: 16)
                            .overlay {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                        Text(item.displayTitle)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                } else {
                    Text(item.displayTitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()

            // Pin button
            Button(action: { engine.pin(item) }) {
                Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundStyle(item.isPinned ? .yellow : .secondary)
            }
            .buttonStyle(.borderless)

            // Copy button
            Button(action: { engine.copyToPasteboard(item) }) {
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
            Button("Copy") { engine.copyToPasteboard(item) }
            Button(item.isPinned ? "Unpin" : "Pin") { engine.pin(item) }
            Button("Set Label…") { showLabelDialog() }
            Divider()
            Button("Delete", role: .destructive) { engine.delete(item) }
                .disabled(item.isPinned)
        }
    }

    private var typeIcon: String {
        switch item.type {
        case .text:    return "doc.text"
        case .url:     return "link"
        case .image:   return "photo"
        case .file:    return "folder"
        case .color:   return "paintpalette"
        case .unknown: return "questionmark"
        }
    }
    
    private func showLabelDialog() {
        let alert = NSAlert()
        alert.messageText = "Set Label for Clipboard Item"
        alert.informativeText = "Enter a custom display label for this clipboard item:"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        input.stringValue = item.label ?? ""
        alert.accessoryView = input
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let label = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            engine.setLabel(label, for: item)
        }
    }
}
