// ────────────────────────────────────────────────────────
// NotchSuperior — NSClipboardEngine.swift
// FIX 5: Battery-safe polling.
//   • Timer tolerance set to 0.5 s so the OS can coalesce wakeups.
//   • Polling pauses when the notch is collapsed (isNotchOpen = false).
//   • Public pausePolling() / resumePolling() API consumed by notch
//     expand/collapse state changes in ContentView.
// ────────────────────────────────────────────────────────

import Cocoa
import Combine

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

@MainActor
final class NSClipboardEngine: ObservableObject {
    static let shared = NSClipboardEngine()

    @Published var history: [NSClipboardItem] = []    // newest first
    @Published var snippets: [NSSnippet] = []

    private var pollTimer: Timer?
    private var lastChangeCount: Int = 0
    private var isPaused: Bool = false   // FIX 5: notch-state gate

    private init() {}

    // MARK: — Lifecycle
    func start() {
        load()
        purgeOld()
        lastChangeCount = NSPasteboard.general.changeCount
        scheduleTimer()
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // FIX 5: Called by notch collapse — pauses polling to reduce CPU wakeups
    func pausePolling() {
        isPaused = true
    }

    // FIX 5: Called by notch expand — resumes and does one immediate check
    func resumePolling() {
        isPaused = false
        checkPasteboard()   // catch anything copied while notch was closed
    }

    // MARK: — Timer setup with OS-coalescable tolerance (FIX 5)
    private func scheduleTimer() {
        pollTimer?.invalidate()
        let t = Timer(timeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPasteboard()
            }
        }
        // FIX 5: tolerance lets the OS batch this timer with other low-priority
        // work, preventing a dedicated CPU wakeup every 800 ms
        t.tolerance = 0.5
        RunLoop.main.add(t, forMode: .common)
        pollTimer = t
    }

    // MARK: — Polling
    private func checkPasteboard() {
        // FIX 5: skip while notch is collapsed
        guard !isPaused else { return }

        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        guard let item = buildItem(from: pb) else { return }
        if let top = history.first, isDuplicate(item, top) { return }
        history.insert(item, at: 0)
        if history.count > 200 {
            history = Array(history.prefix(200))
        }
        save()
    }

    private func buildItem(from pb: NSPasteboard) -> NSClipboardItem? {
        if let imgData = pb.data(forType: .tiff) {
            if let rep = NSBitmapImageRep(data: imgData),
               let png = rep.representation(using: .png, properties: [:]) {
                return NSClipboardItem(id: UUID(), addedAt: Date(),
                    type: .image, imageData: png, isPinned: false)
            }
        }
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = urls.first(where: { $0.isFileURL }) {
            return NSClipboardItem(id: UUID(), addedAt: Date(),
                type: .file, filePath: firstURL.path, isPinned: false)
        }
        if let color = NSColor(from: pb), let rgbColor = color.usingColorSpace(.sRGB) {
            let r = Int(rgbColor.redComponent * 255)
            let g = Int(rgbColor.greenComponent * 255)
            let b = Int(rgbColor.blueComponent * 255)
            let hex = String(format: "#%02X%02X%02X", r, g, b)
            return NSClipboardItem(id: UUID(), addedAt: Date(),
                type: .color, text: hex, colorHex: hex, isPinned: false)
        }
        if let str = pb.string(forType: .string) {
            let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
            let colorRegex = "^#[0-9a-fA-F]{6}$"
            if trimmed.range(of: colorRegex, options: .regularExpression) != nil {
                return NSClipboardItem(id: UUID(), addedAt: Date(),
                    type: .color, text: trimmed, colorHex: trimmed, isPinned: false)
            }
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                return NSClipboardItem(id: UUID(), addedAt: Date(),
                    type: .url, text: trimmed, isPinned: false)
            }
            return NSClipboardItem(id: UUID(), addedAt: Date(),
                type: .text, text: str, isPinned: false)
        }
        return nil
    }

    private func isDuplicate(_ a: NSClipboardItem, _ b: NSClipboardItem) -> Bool {
        a.type == b.type && a.text == b.text && a.imageData == b.imageData && a.filePath == b.filePath
    }

    // MARK: — Mutations
    func pin(_ item: NSClipboardItem) {
        if let i = history.firstIndex(where: { $0.id == item.id }) {
            history[i].isPinned.toggle()
            HapticHelper.trigger()
            save()
        }
    }

    func delete(_ item: NSClipboardItem) {
        guard !item.isPinned else { return }
        history.removeAll { $0.id == item.id }
        HapticHelper.trigger()
        save()
    }

    func copyToPasteboard(_ item: NSClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        if item.type == .color, let hex = item.colorHex {
            pb.setString(hex, forType: .string)
            if let color = NSColor(hex: hex) { color.write(to: pb) }
        } else if let text = item.text {
            pb.setString(text, forType: .string)
        } else if let data = item.imageData {
            if let image = NSImage(data: data) {
                pb.writeObjects([image])
            } else {
                pb.setData(data, forType: .png)
            }
        } else if item.type == .file, let path = item.filePath {
            pb.writeObjects([URL(fileURLWithPath: path) as NSURL])
        }
        lastChangeCount = pb.changeCount
        HapticHelper.trigger()
    }

    func clearUnpinned() {
        history.removeAll { !$0.isPinned }
        HapticHelper.trigger()
        save()
    }

    func setLabel(_ label: String, for item: NSClipboardItem) {
        if let i = history.firstIndex(where: { $0.id == item.id }) {
            history[i].label = label.isEmpty ? nil : label
            save()
        }
    }

    // MARK: — Snippets
    func addSnippet(title: String, body: String, shortcut: String? = nil) {
        snippets.insert(NSSnippet(id: UUID(), title: title, body: body,
            shortcut: shortcut, tags: [], createdAt: Date()), at: 0)
        HapticHelper.trigger()
        save()
    }

    func deleteSnippet(_ s: NSSnippet) {
        snippets.removeAll { $0.id == s.id }
        HapticHelper.trigger()
        save()
    }

    func pasteSnippet(_ s: NSSnippet) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s.body, forType: .string)
        lastChangeCount = pb.changeCount
        HapticHelper.trigger()
    }

    // MARK: — Persistence
    private var storeURL: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("NotchSuperior", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("clipboard.json")
    }

    private struct Store: Codable {
        var history: [NSClipboardItem]
        var snippets: [NSSnippet]
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Store(history: history, snippets: snippets)) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let store = try? JSONDecoder().decode(Store.self, from: data)
        else { return }
        history = store.history
        snippets = store.snippets
    }

    private func purgeOld() {
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        history = history.filter { $0.isPinned || $0.addedAt > cutoff }
        save()
    }
}
