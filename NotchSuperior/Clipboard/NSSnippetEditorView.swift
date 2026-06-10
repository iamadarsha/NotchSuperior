// ────────────────────────────────────────────────────────
// NotchSuperior — NSSnippetEditorView.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSSnippetEditorView: View {
    let snippet: NSSnippet?    // nil = new snippet
    @ObservedObject var engine = NSClipboardEngine.shared
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var bodyText  = ""
    @State private var shortcut = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Snippet name", text: $title)
                }
                Section("Content") {
                    TextEditor(text: $bodyText)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 80)
                }
                Section("Shortcut (optional)") {
                    TextField("/shortcut", text: $shortcut)
                        .autocorrectionDisabled()
                }
            }
            .formStyle(.grouped)
            .navigationTitle(snippet == nil ? "New Snippet" : "Edit Snippet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let s = snippet {
                            // update existing — mutate via engine
                            if let i = engine.snippets.firstIndex(where: { $0.id == s.id }) {
                                engine.snippets[i].title = title
                                engine.snippets[i].body  = bodyText
                                engine.snippets[i].shortcut = shortcut.isEmpty ? nil : shortcut
                            }
                        } else {
                            engine.addSnippet(title: title, body: bodyText, shortcut: shortcut.isEmpty ? nil : shortcut)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty || bodyText.isEmpty)
                }
            }
            .onAppear {
                if let s = snippet {
                    title = s.title
                    bodyText  = s.body
                    shortcut = s.shortcut ?? ""
                }
            }
        }
        .frame(minWidth: 360, minHeight: 300)
    }
}
