// ────────────────────────────────────────────────────────
// NotchSuperior — NSLayoutEngine.swift
// Part of the boring.notch fork
// Phase: 8 — Layout Engine & Settings UI
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Foundation
import AppKit

@MainActor
class NSLayoutEngine: ObservableObject {
    static let shared = NSLayoutEngine()

    @Published var profiles: [NSLayoutProfile] = []
    @Published var activeProfileID: UUID? = nil
    @Published var currentSpaceName: String = "Default"

    var activeProfile: NSLayoutProfile? {
        profiles.first { $0.id == activeProfileID }
    }

    var effectiveWidgets: [NSWidgetSlot] {
        guard let profile = activeProfile else { return defaultWidgets }
        // Check app override for frontmost app
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""
        if let override = profile.appOverrides[frontmost] {
            return override
        }
        return profile.enabledWidgets
    }

    private var defaultWidgets: [NSWidgetSlot] {
        NSLayoutPreset.mediaFirst.defaultWidgetOrder
    }

    // MARK: — Lifecycle

    func setup() {
        load()
        if profiles.isEmpty { createDefaultProfiles() }
        if activeProfileID == nil { activeProfileID = profiles.first?.id }
        observeFrontmostApp()
    }

    private func createDefaultProfiles() {
        let presets: [NSLayoutPreset] = [.mediaFirst, .productivity, .minimalHUD, .devHUD]
        profiles = presets.enumerated().map { i, preset in
            NSLayoutProfile(
                id: UUID(),
                name: preset.displayName,
                preset: preset,
                enabledWidgets: preset.defaultWidgetOrder,
                isActive: i == 0,
                appOverrides: [:]
            )
        }
        activeProfileID = profiles.first?.id
        save()
    }

    // MARK: — Profile management

    func activateProfile(_ id: UUID) {
        activeProfileID = id
        UserDefaults.standard.set(id.uuidString, forKey: "NSActiveLayoutProfile")
        save()
    }

    func createCustomProfile(name: String, widgets: [NSWidgetSlot]) -> NSLayoutProfile {
        let p = NSLayoutProfile(id: UUID(), name: name, preset: .custom,
                                 enabledWidgets: widgets, isActive: false,
                                 appOverrides: [:])
        profiles.append(p)
        save()
        return p
    }

    func updateProfile(_ profile: NSLayoutProfile) {
        if let i = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[i] = profile
            save()
        }
    }

    func deleteProfile(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        if activeProfileID == id { activeProfileID = profiles.first?.id }
        save()
    }

    func moveWidget(from source: IndexSet, to dest: Int, in profileID: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[i].enabledWidgets.move(fromOffsets: source, toOffset: dest)
        save()
    }

    func toggleWidget(_ slot: NSWidgetSlot, in profileID: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        if profiles[i].enabledWidgets.contains(slot) {
            profiles[i].enabledWidgets.removeAll { $0 == slot }
        } else {
            profiles[i].enabledWidgets.append(slot)
        }
        save()
    }

    func setAppOverride(bundleID: String, widgets: [NSWidgetSlot], in profileID: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[i].appOverrides[bundleID] = widgets
        save()
    }

    func removeAppOverride(bundleID: String, in profileID: UUID) {
        guard let i = profiles.firstIndex(where: { $0.id == profileID }) else { return }
        profiles[i].appOverrides.removeValue(forKey: bundleID)
        save()
    }

    // MARK: — App observation
    private var appObserver: NSObjectProtocol?

    private func observeFrontmostApp() {
        appObserver = NSWorkspace.shared.notificationCenter
            .addObserver(forName: NSWorkspace.didActivateApplicationNotification,
                         object: nil, queue: .main) { [weak self] _ in
                // Trigger effectiveWidgets recomputation via objectWillChange
                Task { @MainActor in self?.objectWillChange.send() }
            }
    }

    // MARK: — Persistence
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("layouts.json")
    }

    private struct Store: Codable {
        var profiles: [NSLayoutProfile]
        var activeProfileID: UUID?
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Store(profiles: profiles, activeProfileID: activeProfileID))
        else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func load() {
        if let idString = UserDefaults.standard.string(forKey: "NSActiveLayoutProfile"),
           let uuid = UUID(uuidString: idString) {
            activeProfileID = uuid
        }
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data)
        else { return }
        profiles = store.profiles
        if activeProfileID == nil {
            activeProfileID = store.activeProfileID
        }
    }
}
