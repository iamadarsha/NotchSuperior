// ────────────────────────────────────────────────────────
// NotchSuperior — NSDevSettingsSection.swift
// Part of the boring.notch fork
// Phase: 9 — Dev / Power-User Tools
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 26.0, *)
struct NSDevSettingsSection: View {
    @ObservedObject var engine = NSDevEngine.shared

    var body: some View {
        Form {
            Section("Git") {
                HStack {
                    Text("Repo Path")
                    TextField("~/code/myapp", text: $engine.config.gitRepoPath)
                        .textFieldStyle(.roundedBorder)
                }
            }
            Section("Docker") {
                Toggle("Show Docker Status", isOn: $engine.config.dockerEnabled)
            }
            Section("Network Latency") {
                HStack {
                    Text("Host")
                    TextField("api.myapp.com", text: $engine.config.latencyHost)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Check every")
                    Slider(value: $engine.config.latencyIntervalSec, in: 10...120, step: 10)
                    Text("\(Int(engine.config.latencyIntervalSec))s")
                        .frame(width: 30)
                }
            }
            Section("Terminal") {
                Picker("Shell", selection: Binding(
                    get: { UserDefaults.standard.string(forKey: "NSTerminalShell") ?? "/bin/zsh" },
                    set: { UserDefaults.standard.set($0, forKey: "NSTerminalShell") }
                )) {
                    Text("zsh").tag("/bin/zsh")
                    Text("bash").tag("/bin/bash")
                    Text("fish").tag("/usr/local/bin/fish")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Dev Tools")
        .onDisappear { engine.saveConfig() }
    }
}
