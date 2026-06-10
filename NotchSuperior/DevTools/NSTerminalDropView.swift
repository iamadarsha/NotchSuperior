// ────────────────────────────────────────────────────────
// NotchSuperior — NSTerminalDropView.swift
// Part of the boring.notch fork
// Phase: 9 — Dev / Power-User Tools
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

// Guake-style terminal drop panel from the notch
// Triggered by the command launcher or a keyboard shortcut ⌃`
@available(macOS 14.0, *)
struct NSTerminalDropView: View {
    @AppStorage("NSTerminalShell") var shellPath = "/bin/zsh"
    @AppStorage("NSTerminalOpen") var isOpen = false
    @State private var commandInput = ""
    @State private var outputLines: [String] = ["NotchSuperior Terminal ready.", "Type a command and press Return."]
    @State private var isRunning = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Output pane
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(outputLines.enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(line.hasPrefix("$") ? .green : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(i)
                        }
                    }
                    .padding(8)
                }
                .frame(minHeight: 120, maxHeight: 200)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
                .onChange(of: outputLines.count) { _ in
                    withAnimation {
                        proxy.scrollTo(outputLines.count - 1, anchor: .bottom)
                    }
                }
            }

            // Input bar
            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.green)
                TextField("command…", text: $commandInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .focused($inputFocused)
                    .onSubmit { runCommand() }
                if isRunning {
                    ProgressView().scaleEffect(0.5)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(Color.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 8))
        }
        .onAppear { inputFocused = true }
    }

    private func runCommand() {
        guard !commandInput.isEmpty, !isRunning else { return }
        let cmd = commandInput
        commandInput = ""
        outputLines.append("$ \(cmd)")
        isRunning = true

        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: shellPath)
            proc.arguments = ["-c", cmd]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            try? proc.run()
            proc.waitUntilExit()
            let out = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let lines = out.trimmingCharacters(in: .newlines)
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
            await MainActor.run {
                outputLines.append(contentsOf: lines.isEmpty ? ["(no output)"] : lines)
                isRunning = false
            }
        }
    }
}
