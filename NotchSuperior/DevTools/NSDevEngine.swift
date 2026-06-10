// ────────────────────────────────────────────────────────
// NotchSuperior — NSDevEngine.swift
// FIX (Bootstrap): Engine is now always started unconditionally;
//   widget enablement is self-gated here instead.
// FIX (Thread): shell() runs on a detached background Task so it
//   never blocks the @MainActor thread, eliminating UI hangs during
//   git/docker/nc calls.
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

    // Called unconditionally from NSuperiorBootstrap.
    // Self-gates: only polls if at least one relevant widget is enabled.
    func start() {
        loadConfig()
        guard !isRunning else { return }   // idempotent
        pollTask = Task {
            while !Task.isCancelled {
                // Self-gate: skip all work if dev widgets are all disabled
                if NSLayoutEngine.shared.effectiveWidgets.contains(.gitStatus)
                    || NSLayoutEngine.shared.effectiveWidgets.contains(.dockerStatus)
                    || NSLayoutEngine.shared.effectiveWidgets.contains(.networkLatency) {
                    await refresh()
                }
                try? await Task.sleep(nanoseconds:
                    UInt64(config.latencyIntervalSec) * 1_000_000_000)
            }
        }
    }

    private var isRunning: Bool { pollTask != nil && !(pollTask?.isCancelled ?? true) }

    func stop() { pollTask?.cancel(); pollTask = nil }

    func refresh() async {
        var updated: [NSDevStatusItem] = []
        let gitItem = await checkGit()
        updated.append(gitItem)
        if config.dockerEnabled {
            let dockerItem = await checkDocker()
            updated.append(dockerItem)
        }
        let latencyItem = await checkLatency()
        updated.append(latencyItem)
        items = updated
    }

    // MARK: — Git check (FIX: background Task — never blocks @MainActor)
    private func checkGit() async -> NSDevStatusItem {
        let repoPath = NSString(string: config.gitRepoPath).expandingTildeInPath
        let (branch, dirty): (String, String) = await Task.detached(priority: .utility) {
            let b = Self.shell("git -C \(repoPath) rev-parse --abbrev-ref HEAD 2>/dev/null")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let d = Self.shell("git -C \(repoPath) status --porcelain 2>/dev/null")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (b, d)
        }.value

        let value = branch.isEmpty ? "No repo" : branch + (dirty.isEmpty ? "" : " ●")
        let status: NSDevStatus = branch.isEmpty ? .error : (dirty.isEmpty ? .ok : .warn)
        return NSDevStatusItem(id: UUID(), label: "Git",
                                value: value, status: status,
                                icon: "arrow.triangle.branch")
    }

    // MARK: — Docker check (FIX: background Task)
    private func checkDocker() async -> NSDevStatusItem {
        let out = await Task.detached(priority: .utility) {
            Self.shell("docker ps --format '{{.Names}}' 2>/dev/null")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
        let count = out.isEmpty ? 0 : out.split(separator: "\n").count
        return NSDevStatusItem(id: UUID(), label: "Docker",
                                value: "\(count) running",
                                status: count > 0 ? .ok : .warn,
                                icon: "shippingbox")
    }

    // MARK: — Latency check (FIX: background Task)
    private func checkLatency() async -> NSDevStatusItem {
        let host = config.latencyHost
        let (ms, ok) = await Task.detached(priority: .utility) {
            let start = Date()
            let result = Self.shell("nc -zw1 \(host) 80 2>&1")
            let ms = Int(Date().timeIntervalSince(start) * 1000)
            let ok = result.contains("succeeded") || ms < 2000
            return (ms, ok)
        }.value
        return NSDevStatusItem(id: UUID(), label: host,
                                value: ok ? "\(ms)ms" : "unreachable",
                                status: ok ? (ms < 200 ? .ok : .warn) : .error,
                                icon: "network")
    }

    // MARK: — Shell helper (nonisolated — safe to call from detached Tasks)
    private static func shell(_ cmd: String) -> String {
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
