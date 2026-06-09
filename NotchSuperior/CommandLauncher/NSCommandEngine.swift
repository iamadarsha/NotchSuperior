// NOTCHSUPERIOR ADDITION
import Foundation
import SwiftUI

@MainActor
class NSCommandEngine: ObservableObject {
    static let shared = NSCommandEngine()

    @Published var query: String = ""
    @Published var results: [any NSLaunchable] = []
    @Published var selectedIndex: Int = 0
    @Published var isVisible: Bool = false
    @Published var isRunning: Bool = false
    @Published var lastResult: String? = nil

    // Built-in commands
    private var builtins: [any NSLaunchable] = []

    // User-defined shell commands persisted to disk
    @Published var userCommands: [NSShellCommand] = []

    func setup() {
        buildBuiltins()
        loadUserCommands()
    }

    private func buildBuiltins() {
        builtins = [
            NSShortcutCommand(id: UUID(),
                title: "New AI Chat",
                subtitle: "Open AI Chat panel",
                icon: "bubble.left.and.bubble.right",
                keywords: ["ai", "chat", "ask"],
                action: {
                    UserDefaults.standard.set(true, forKey: "NSAIChatOpen")
                }),
            NSShortcutCommand(id: UUID(),
                title: "Start Focus Session",
                subtitle: "Begin a Pomodoro timer",
                icon: "timer",
                keywords: ["focus", "pomodoro", "timer", "work"],
                action: {
                    NSFocusEngine.shared.start()
                }),
            NSShortcutCommand(id: UUID(),
                title: "Show Clipboard",
                subtitle: "Open clipboard history",
                icon: "doc.on.clipboard",
                keywords: ["clipboard", "paste", "history"],
                action: {
                    UserDefaults.standard.set(true, forKey: "NSClipboardOpen")
                }),
            NSShortcutCommand(id: UUID(),
                title: "New Voice Note",
                subtitle: "Start recording immediately",
                icon: "mic.circle",
                keywords: ["note", "voice", "record", "memo"],
                action: {
                    let note = NSAINoteEngine.shared.createNote(title: "Voice Note")
                    NSAINoteEngine.shared.startRecording()
                }),
            NSShortcutCommand(id: UUID(),
                title: "Lock Screen",
                subtitle: nil,
                icon: "lock.display",
                keywords: ["lock", "screen", "sleep"],
                action: {
                    let proc = Process()
                    proc.executableURL = URL(fileURLWithPath:
                        "/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession")
                    proc.arguments = ["-suspend"]
                    try? proc.run()
                }),
            NSShortcutCommand(id: UUID(),
                title: "Empty Trash",
                subtitle: nil,
                icon: "trash",
                keywords: ["trash", "empty", "delete"],
                action: {
                    let script = "tell application \"Finder\" to empty trash"
                    let proc = Process()
                    proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                    proc.arguments = ["-e", script]
                    try? proc.run()
                }),
            NSShortcutCommand(id: UUID(),
                title: "Open Terminal",
                subtitle: "Open dropdown shell",
                icon: "terminal",
                keywords: ["terminal", "shell", "dev"],
                action: {
                    UserDefaults.standard.set(true, forKey: "NSTerminalOpen")
                }),
            NSShortcutCommand(id: UUID(),
                title: "Refresh Dev Status",
                subtitle: "Check Docker, Git, & Latency",
                icon: "arrow.clockwise",
                keywords: ["git", "docker", "latency", "refresh", "dev"],
                action: {
                    Task {
                        await NSDevEngine.shared.refresh()
                    }
                }),
        ]
    }

    func search(_ text: String) {
        query = text
        if text.isEmpty {
            results = builtins + userCommands
            selectedIndex = 0
            return
        }
        let lower = text.lowercased()
        let all: [any NSLaunchable] = builtins + userCommands
        results = all.filter { cmd in
            cmd.title.lowercased().contains(lower)
            || (cmd.subtitle?.lowercased().contains(lower) ?? false)
            || cmd.keywords.contains(where: { $0.contains(lower) })
        }
        selectedIndex = 0
    }

    func selectNext() {
        guard !results.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % results.count
    }

    func selectPrev() {
        guard !results.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + results.count) % results.count
    }

    func executeSelected() async {
        guard selectedIndex < results.count else { return }
        isRunning = true
        await results[selectedIndex].execute()
        isRunning = false
        isVisible = false
        query = ""
    }

    func show() { isVisible = true; search("") }
    func hide() { isVisible = false; query = "" }

    // MARK: — User command persistence
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for:.applicationSupportDirectory, in:.userDomainMask)[0]
            .appendingPathComponent("NotchSuperior")
        try? FileManager.default.createDirectory(at: dir,
            withIntermediateDirectories: true)
        return dir.appendingPathComponent("commands.json")
    }

    func addUserCommand(_ cmd: NSShellCommand) {
        userCommands.append(cmd)
        saveUserCommands()
    }

    func deleteUserCommand(_ id: UUID) {
        userCommands.removeAll { $0.id == id }
        saveUserCommands()
    }

    private func saveUserCommands() {
        guard let data = try? JSONEncoder().encode(userCommands) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func loadUserCommands() {
        guard let data = try? Data(contentsOf: storeURL),
              let cmds = try? JSONDecoder().decode([NSShellCommand].self, from: data)
        else { return }
        userCommands = cmds
    }
}
