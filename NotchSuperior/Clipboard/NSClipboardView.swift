// ────────────────────────────────────────────────────────
// NotchSuperior — NSClipboardView.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 26.0, *)
struct NSClipboardView: View {
    @ObservedObject var engine = NSClipboardEngine.shared
    @State private var searchText = ""
    @State private var selectedTab: ClipTab = .history
    @State private var editingSnippet: NSSnippet? = nil
    @State private var showNewSnippet = false

    enum ClipTab: String, CaseIterable {
        case history = "History"
        case pinned = "Pinned"
        case snippets = "Snippets"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search clipboard...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top], 8)

            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                ForEach(ClipTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            .padding(.top, 6)

            // Content
            ScrollView {
                LazyVStack(spacing: 4) {
                    switch selectedTab {
                    case .history:
                        ForEach(filteredHistory) { item in
                            NSClipboardItemRow(item: item)
                        }
                    case .pinned:
                        ForEach(pinnedItems) { item in
                            NSClipboardItemRow(item: item)
                        }
                    case .snippets:
                        ForEach(engine.snippets) { s in
                            NSSnippetRow(snippet: s)
                                .onTapGesture(count: 2) {
                                    editingSnippet = s
                                }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            if selectedTab == .snippets {
                Divider()
                Button(action: { showNewSnippet = true }) {
                    Label("New Snippet", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderless)
                .padding(8)
            }
        }
        .sheet(isPresented: $showNewSnippet) {
            NSSnippetEditorView(snippet: nil)
        }
        .sheet(item: $editingSnippet) { s in
            NSSnippetEditorView(snippet: s)
        }
    }

    private var filteredHistory: [NSClipboardItem] {
        let all = engine.history.filter { !$0.isPinned }
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var pinnedItems: [NSClipboardItem] {
        let all = engine.history.filter { $0.isPinned }
        guard !searchText.isEmpty else { return all }
        return all.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(searchText)
        }
    }
}
