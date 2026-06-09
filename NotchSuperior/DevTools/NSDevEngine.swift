// ────────────────────────────────────────────────────────
// NotchSuperior — NSDevEngine.swift
// Part of the boring.notch fork
// Phase: 9 — Dev / Power-User Tools
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Foundation

@MainActor
class NSDevEngine: ObservableObject {
    static let shared = NSDevEngine()

    @Published var items: [NSDevStatusItem] = []
    @Published var config: NSDevConfig = NSDevConfig(
        gitRepoPath: "~/code",
        dockerEnabled: true,
        latencyHost: "1.1.1.1",
        latencyIntervalSec: 30)

    private var pollTask: Task<Void, Never>?

    func start() {
        loadConfig()
        pollTask = Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(nanoseconds:
                    UInt64(config.latencyIntervalSec * 1_000_000_000))
            }
        }
    }

    func stop() { pollTask?.cancel() }

    func refresh() async {
        var updated: [NSDevStatusItem] = []

        // GIT: current branch + dirty state
        let gitItem = await checkGit()
        updated.append(gitItem)

        // DOCKER: running containers count
        if config.dockerEnabled {
            let dockerItem = await checkDocker()
            updated.append(dockerItem)
        }

        // LATENCY: ping configured host
        let latencyItem = await checkLatency()
        updated.append(latencyItem)

        items = updated
    }

    // MARK: — Git check
    private func checkGit() async -> NSDevStatusItem {
        let repoPath = NSString(string: config.gitRepoPath)
            .expandingTildeInPath
        let branch = shell("git -C \(repoPath) rev-parse --abbrev-ref HEAD 2>/dev/null")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let dirty = shell("git -C \(repoPath) status --porcelain 2>/dev/null")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let value = branch.isEmpty ? "No repo" : branch + (dirty.isEmpty ? "" : " ●")
        let status: NSDevStatus = branch.isEmpty ? .error : (dirty.isEmpty ? .ok : .warn)

        return NSDevStatusItem(id: UUID(), label: "Git",
                                value: value, status: status,
                                icon: "arrow.triangle.branch")
    }

    // MARK: — Docker check
    private func checkDocker() async -> NSDevStatusItem {
        let out = shell("docker ps --format '{{.Names}}' 2>/dev/null")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let count = out.isEmpty ? 0 : out.split(separator: "\n").count
        return NSDevStatusItem(id: UUID(), label: "Docker",
                                value: "\(count) running",
                                status: count > 0 ? .ok : .warn,
                                icon: "shippingbox")
    }

    // MARK: — Latency check (simple TCP connect)
    private func checkLatency() async -> NSDevStatusItem {
        let host = config.latencyHost
        let start = Date()
        // Use Process + nc for simple ping
        let result = shell("nc -zw1 \(host) 80 2>&1")
        let ms = Int(Date().timeIntervalSince(start) * 1000)
        let ok = result.contains("succeeded") || ms < 2000
        return NSDevStatusItem(id: UUID(), label: host,
                                value: ok ? "\(ms)ms" : "unreachable",
                                status: ok ? (ms < 200 ? .ok : .warn) : .error,
                                icon: "network")
    }

    // MARK: — Shell helper (synchronous, short-lived commands only)
    private func shell(_ cmd: String) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", cmd]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(),
                      encoding: .utf8) ?? ""
    }

    // MARK: — Config persistence
    private var configURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior")
        try? FileManager.default.createDirectory(at: dir,
            withIntermediateDirectories: true)
        return dir.appendingPathComponent("devconfig.json")
    }

    func saveConfig() {
        guard let data = try? JSONEncoder().encode(config) else { return }
        try? data.write(to: configURL, options: .atomic)
    }

    func loadConfig() {
        guard let data = try? Data(contentsOf: configURL),
              let c = try? JSONDecoder().decode(NSDevConfig.self, from: data)
        else { return }
        config = c
    }
}
