// ────────────────────────────────────────────────────────
// NotchSuperior — NSBehaviorProfilesView.swift
// Part of the boring.notch fork
// Phase: 8 — Layout Engine & Settings UI
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSBehaviorProfilesView: View {
    @AppStorage("NSProfilePresenting") var presenting = false
    @AppStorage("NSProfileBatterySaver") var batterySaver = false
    @AppStorage("NSProfileFocus") var focusMode = false

    var body: some View {
        Form {
            Section("Quick Profiles") {
                Toggle("Presenting Mode", isOn: $presenting)
                // When on: disable visualizer, mute animations,
                // hide non-essential widgets
                if presenting {
                    Text("Visualizer and animations are disabled while presenting.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }

                Toggle("Battery Saver", isOn: $batterySaver)
                if batterySaver {
                    Text("Reduces animation frame rate and disables background polling.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }

                Toggle("Focus Mode Override", isOn: $focusMode)
                if focusMode {
                    Text("Shows only the focus timer and minimal HUD.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Behavior Profiles")
        .onChange(of: presenting) { _, _ in applyBehavior() }
        .onChange(of: batterySaver) { _, _ in applyBehavior() }
        .onChange(of: focusMode) { _, _ in applyBehavior() }
    }

    private func applyBehavior() {
        // Notify NSHUDEngine and NSTokens to reduce animations
        // when presenting or battery saver is on.
        // Use UserDefaults — other engines read these keys on change.
        // NSHUDEngine should already check NSProfileBatterySaver
        // before launching the visualizer timer.
        // NSTokens.animationSpring can return .linear(duration:0.001)
        // when presenting is true.
        // Implement the check in NSTokens.swift:
        //   static var animationSpring: Animation {
        //     if UserDefaults.standard.bool(forKey:"NSProfilePresenting") {
        //       return .linear(duration: 0.001)
        //     }
        //     return .spring(response: 0.45, dampingFraction: 0.75)
        //   }
        UserDefaults.standard.synchronize()
    }
}
