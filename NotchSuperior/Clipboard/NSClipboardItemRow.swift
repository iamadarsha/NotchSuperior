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

    @State private var copied = false
    @State private var isHighlighted = false

    private static let relativeFmt: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var resolvedTitle: String {
        if item.type == .url, let text = item.text, let host = URL(string: text)?.host {
            return host
        }
        return item.displayTitle
    }

    private var relativeTimestamp: String {
        Self.relativeFmt.localizedString(for: item.addedAt, relativeTo: Date())
    }

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
                        VStack(alignment: .leading, spacing: 1) {
                            Text(resolvedTitle)
                                .font(.system(size: 12))
                                .lineLimit(1)
                            Text(relativeTimestamp)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(resolvedTitle)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(relativeTimestamp)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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

            // Copy button / copied checkmark
            Button(action: { performCopy() }) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                    .foregroundStyle(copied ? .green : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: copied)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(isHighlighted ? 0.05 : 0))
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { performCopy() }
        .onHover { isHighlighted = $0 }
        .contextMenu {
            Button("Copy") { engine.copyToPasteboard(item) }
            Button(item.isPinned ? "Unpin" : "Pin") { engine.pin(item) }
            Button("Set Label…") { showLabelDialog() }
            Divider()
            Button("Delete", role: .destructive) { engine.delete(item) }
                .disabled(item.isPinned)
        }
    }

    private func performCopy() {
        engine.copyToPasteboard(item)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
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
