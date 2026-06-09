// ────────────────────────────────────────────────────────
// NotchSuperior — NSLayoutSettingsView.swift
// Part of the boring.notch fork
// Phase: 8 — Layout Engine & Settings UI
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

// Full-featured layout editor UI
@available(macOS 26.0, *)
struct NSLayoutSettingsView: View {
    @ObservedObject var engine = NSLayoutEngine.shared
    @State private var selectedProfileID: UUID? = nil
    @State private var showNewProfileSheet = false
    @State private var newProfileName = ""
    @State private var showAppOverrideSheet = false

    private var selectedProfile: NSLayoutProfile? {
        guard let id = selectedProfileID else { return nil }
        return engine.profiles.first { $0.id == id }
    }

    var body: some View {
        NavigationSplitView {
            // Left: profile list
            List(engine.profiles, selection: $selectedProfileID) { profile in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.system(size: 13, weight: .medium))
                        Text(profile.preset.description)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if profile.id == engine.activeProfileID {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 13))
                    }
                }
                .tag(profile.id)
                .contextMenu {
                    Button("Activate") { engine.activateProfile(profile.id) }
                    if profile.preset == .custom {
                        Button("Delete", role: .destructive) {
                            engine.deleteProfile(profile.id)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: { showNewProfileSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationTitle("Layouts")
        } detail: {
            if let profile = selectedProfile {
                NSLayoutProfileDetailView(profile: profile)
                    .id(profile.id) // Ensure detail updates on switch
            } else {
                Text("Select a layout profile")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            selectedProfileID = selectedProfileID ?? engine.activeProfileID
        }
        .sheet(isPresented: $showNewProfileSheet) {
            NSNewProfileSheet(isPresented: $showNewProfileSheet)
        }
        .frame(minWidth: 560, minHeight: 340)
    }
}

@available(macOS 26.0, *)
struct NSLayoutProfileDetailView: View {
    @State var profile: NSLayoutProfile
    @ObservedObject var engine = NSLayoutEngine.shared
    @State private var showAppOverrideSheet = false

    private var allSlots: [NSWidgetSlot] { NSWidgetSlot.allCases }
    private var enabledSlots: [NSWidgetSlot] { profile.enabledWidgets }
    private var disabledSlots: [NSWidgetSlot] {
        allSlots.filter { !enabledSlots.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(profile.name)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if profile.id == engine.activeProfileID {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 12))
                } else {
                    Button("Set Active") {
                        engine.activateProfile(profile.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider()

            // Two-column widget editor
            HStack(alignment: .top, spacing: 0) {
                // Enabled widgets (draggable, ordered)
                VStack(alignment: .leading, spacing: 4) {
                    Label("Active Widgets", systemImage: "checkmark.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.top, 10)

                    List {
                        ForEach(enabledSlots) { slot in
                            HStack(spacing: 8) {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: 11))
                                Image(systemName: slot.icon)
                                    .frame(width: 18)
                                Text(slot.displayName)
                                    .font(.system(size: 12))
                                Spacer()
                                Button(action: {
                                    engine.toggleWidget(slot, in: profile.id)
                                    // Refresh local state
                                    if let updated = engine.profiles
                                        .first(where: { $0.id == profile.id }) {
                                        profile = updated
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 13))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .onMove { source, dest in
                            engine.moveWidget(from: source, to: dest, in: profile.id)
                            if let updated = engine.profiles
                                .first(where: { $0.id == profile.id }) {
                                profile = updated
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                .frame(maxWidth: .infinity)

                Divider()

                // Disabled widgets (add pool)
                VStack(alignment: .leading, spacing: 4) {
                    Label("Available Widgets", systemImage: "plus.circle")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12).padding(.top, 10)

                    List(disabledSlots) { slot in
                        HStack(spacing: 8) {
                            Image(systemName: slot.icon)
                                .frame(width: 18)
                            Text(slot.displayName)
                                .font(.system(size: 12))
                            Spacer()
                            Button(action: {
                                engine.toggleWidget(slot, in: profile.id)
                                if let updated = engine.profiles
                                    .first(where: { $0.id == profile.id }) {
                                    profile = updated
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .listStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            // App overrides section
            HStack {
                Text("Per-App Overrides")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Button("Add Override") { showAppOverrideSheet = true }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)

            if profile.appOverrides.isEmpty {
                Text("No app overrides. Overrides show different widgets when a specific app is frontmost.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16).padding(.bottom, 8)
            } else {
                List(Array(profile.appOverrides.keys), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID)
                            .font(.system(size: 11, design: .monospaced))
                        Spacer()
                        Text("\(profile.appOverrides[bundleID]?.count ?? 0) widgets")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 11))
                        Button(action: {
                            engine.removeAppOverride(bundleID: bundleID, in: profile.id)
                            if let updated = engine.profiles
                                .first(where: { $0.id == profile.id }) {
                                profile = updated
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 80)
            }
        }
        .sheet(isPresented: $showAppOverrideSheet) {
            NSAppOverrideSheet(profileID: profile.id, isPresented: $showAppOverrideSheet) {
                if let updated = engine.profiles.first(where: { $0.id == profile.id }) {
                    profile = updated
                }
            }
        }
    }
}

@available(macOS 26.0, *)
struct NSNewProfileSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var engine = NSLayoutEngine.shared
    @State private var name = ""
    @State private var basePreset: NSLayoutPreset = .mediaFirst

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Name") {
                    TextField("My Layout", text: $name)
                }
                Section("Start From") {
                    Picker("Base Preset", selection: $basePreset) {
                        ForEach(NSLayoutPreset.allCases.filter { $0 != .custom }, id: \.self) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Layout Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        _ = engine.createCustomProfile(
                            name: name.isEmpty ? "Custom" : name,
                            widgets: basePreset.defaultWidgetOrder)
                        isPresented = false
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 220)
    }
}

@available(macOS 26.0, *)
struct NSAppOverrideSheet: View {
    let profileID: UUID
    @Binding var isPresented: Bool
    @ObservedObject var engine = NSLayoutEngine.shared
    @State private var bundleID = ""
    @State private var selectedWidgets: Set<NSWidgetSlot> = []
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("App Bundle ID") {
                    TextField("com.apple.xcode", text: $bundleID)
                        .autocorrectionDisabled()
                }
                Section("Show Widgets") {
                    ForEach(NSWidgetSlot.allCases) { slot in
                        Toggle(isOn: Binding(
                            get: { selectedWidgets.contains(slot) },
                            set: { if $0 { selectedWidgets.insert(slot) }
                                   else { selectedWidgets.remove(slot) } }
                        )) {
                            Label(slot.displayName, systemImage: slot.icon)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("App Override")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        engine.setAppOverride(
                            bundleID: bundleID,
                            widgets: Array(selectedWidgets),
                            in: profileID)
                        onSave()
                        isPresented = false
                    }
                    .disabled(bundleID.isEmpty || selectedWidgets.isEmpty)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 320)
    }
}
