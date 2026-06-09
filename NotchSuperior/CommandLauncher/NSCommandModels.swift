// NOTCHSUPERIOR ADDITION
import Foundation
import AppKit

protocol NSLaunchable {
    var id: UUID { get }
    var title: String { get }
    var subtitle: String? { get }
    var icon: String { get }       // SF Symbol name
    var keywords: [String] { get }
    func execute() async
}

struct NSShortcutCommand: NSLaunchable, Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let icon: String
    let keywords: [String]
    let action: () async -> Void
    func execute() async { await action() }
}

struct NSShellCommand: NSLaunchable, Identifiable, Codable {
    let id: UUID
    var title: String
    var subtitle: String?
    var icon: String = "terminal"
    var shellScript: String
    var keywords: [String] = []
    func execute() async {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", shellScript]
        try? proc.run()
    }
}

struct NSShortcutAppCommand: NSLaunchable, Identifiable {
    // Wraps a macOS Shortcut (from Shortcuts.app)
    let id: UUID
    var title: String
    var subtitle: String? = "Shortcut"
    var icon: String = "sparkles"
    var shortcutName: String
    var keywords: [String] = []
    func execute() async {
        // Open via URL scheme: shortcuts://run-shortcut?name=...
        if let url = URL(string: "shortcuts://run-shortcut?name=\(shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName)") {
            NSWorkspace.shared.open(url)
        }
    }
}
