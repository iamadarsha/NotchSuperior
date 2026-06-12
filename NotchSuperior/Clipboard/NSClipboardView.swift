// ────────────────────────────────────────────────────────
// NotchSuperior — NSClipboardView.swift
// Part of the boring.notch fork
// Phase: 4 — Clipboard & Snippets
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
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

    // MARK: - Date sectioning

    private enum DateSection: String {
        case today = "Today"
        case yesterday = "Yesterday"
        case thisWeek = "Earlier This Week"
        case older = "Older"
    }

    private func dateSection(for date: Date) -> DateSection {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return .today }
        if cal.isDateInYesterday(date) { return .yesterday }
        if let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()), date > weekAgo {
            return .thisWeek
        }
        return .older
    }

    private var groupedHistory: [(section: DateSection, items: [NSClipboardItem])] {
        let order: [DateSection] = [.today, .yesterday, .thisWeek, .older]
        let grouped = Dictionary(grouping: filteredHistory) { dateSection(for: $0.addedAt) }
        return order.compactMap { sec in
            guard let items = grouped[sec], !items.isEmpty else { return nil }
            return (section: sec, items: items)
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search clipboard...", text: $searchText)
                        .textFieldStyle(.plain)

                    if selectedTab == .history && !engine.history.filter({ !$0.isPinned }).isEmpty {
                        Button(action: {
                            engine.clearUnpinned()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity)
                        .help("Clear Unpinned History")
                    }
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

                ScrollView {
                    LazyVStack(spacing: 4) {
                        switch selectedTab {
                        case .history:
                            ForEach(groupedHistory, id: \.section.rawValue) { group in
                                Section {
                                    ForEach(group.items) { item in
                                        NSClipboardItemRow(item: item)
                                    }
                                } header: {
                                    Text(group.section.rawValue)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 4)
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)
                                }
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
                .applyScrollPhaseChange()

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

            // Keyboard shortcuts Cmd+1…Cmd+9 — hidden overlay buttons
            keyboardShortcutOverlay
        }
        .sheet(isPresented: $showNewSnippet) {
            NSSnippetEditorView(snippet: nil)
        }
        .sheet(item: $editingSnippet) { s in
            NSSnippetEditorView(snippet: s)
        }
    }

    // MARK: - Keyboard shortcut overlay

    @ViewBuilder
    private var keyboardShortcutOverlay: some View {
        let displayedItems: [NSClipboardItem] = {
            switch selectedTab {
            case .history:  return filteredHistory
            case .pinned:   return pinnedItems
            case .snippets: return []
            }
        }()

        ForEach(1...9, id: \.self) { n in
            Button("") {
                guard n <= displayedItems.count else { return }
                let item = displayedItems[n - 1]
                engine.copyToPasteboard(item)
                NotificationCenter.default.post(
                    name: Notification.Name("notchSuperiorClipboardDidCopy"),
                    object: item
                )
            }
            .keyboardShortcut(KeyEquivalent(Character(String(n))), modifiers: .command)
            .hidden()
        }
    }

    // MARK: - Filtered data

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

@available(macOS 14.0, *)
extension View {
    @ViewBuilder
    func applyScrollPhaseChange() -> some View {
        if #available(macOS 15.0, *) {
            self.onScrollPhaseChange { _, newPhase in
                BoringViewCoordinator.shared.clipboardIsScrolling =
                    (newPhase == .interacting || newPhase == .decelerating)
            }
        } else {
            self
        }
    }
}
