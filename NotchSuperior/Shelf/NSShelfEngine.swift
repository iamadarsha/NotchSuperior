// ────────────────────────────────────────────────────────
// NotchSuperior — NSShelfEngine.swift
// Part of the boring.notch fork
// Phase: 3 — Shelf 2.0
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Cocoa
import Combine

@MainActor
final class NSShelfEngine: ObservableObject {
    static let shared = NSShelfEngine()
    
    @Published var stacks: [NSShelfStack] = []
    
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    private var shelfDirectoryURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("NotchSuperior", isDirectory: true)
    }
    
    private var shelfFileURL: URL {
        shelfDirectoryURL.appendingPathComponent("shelf.json")
    }
    
    private init() {
        loadFromDisk()
        
        if stacks.isEmpty {
            setupDefaultStacks()
        } else {
            purgeRebootExpiredIfNeeded()
        }
        
        purgeExpired()
        
        // Subscribe to NSWorkspace.shared.notificationCenter didActivateApplicationNotification
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.purgeExpired()
                }
            }
            .store(in: &cancellables)
            
        // Subscribe to NSApplication didBecomeActiveNotification
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.purgeExpired()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupDefaultStacks() {
        stacks = [
            NSShelfStack(id: UUID(), name: "Inbox", expiry: .after(86400), items: [], showBadge: true),
            NSShelfStack(id: UUID(), name: "Share Later", expiry: .onReboot, items: [], showBadge: true),
            NSShelfStack(id: UUID(), name: "Pinned", expiry: .never, items: [], showBadge: false)
        ]
        saveToDisk()
    }
    
    func add(url: URL, to stackID: UUID) {
        guard let index = stacks.firstIndex(where: { $0.id == stackID }) else { return }
        
        let item = NSShelfItem(id: UUID(), url: url, addedAt: Date(), stackID: stackID)
        stacks[index].items.append(item)
        saveToDisk()
    }
    
    func remove(item: NSShelfItem) {
        for index in 0..<stacks.count {
            if stacks[index].id == item.stackID {
                stacks[index].items.removeAll { $0.id == item.id }
            }
        }
        saveToDisk()
    }
    
    func move(item: NSShelfItem, to stackID: UUID) {
        var foundItem: NSShelfItem?
        for index in 0..<stacks.count {
            if stacks[index].id == item.stackID {
                if let itemIndex = stacks[index].items.firstIndex(where: { $0.id == item.id }) {
                    foundItem = stacks[index].items.remove(at: itemIndex)
                }
            }
        }
        
        if var movedItem = foundItem, let destIndex = stacks.firstIndex(where: { $0.id == stackID }) {
            movedItem.stackID = stackID
            stacks[destIndex].items.append(movedItem)
            saveToDisk()
        }
    }
    
    func createStack(name: String, expiry: NSShelfExpiry) {
        let stack = NSShelfStack(id: UUID(), name: name, expiry: expiry, items: [], showBadge: expiry != .never)
        stacks.append(stack)
        saveToDisk()
    }
    
    func purgeExpired() {
        let now = Date()
        var changed = false
        
        for index in 0..<stacks.count {
            let stack = stacks[index]
            let beforeCount = stack.items.count
            
            stacks[index].items = stack.items.filter { item in
                guard let expiresAt = stack.expiry.expiresAt(from: item.addedAt) else { return true }
                return expiresAt > now
            }
            
            if stacks[index].items.count != beforeCount {
                changed = true
            }
        }
        
        if changed {
            saveToDisk()
        }
    }
    
    private func purgeRebootExpiredIfNeeded() {
        var changed = false
        for index in 0..<stacks.count {
            if stacks[index].expiry == .onReboot {
                if !stacks[index].items.isEmpty {
                    stacks[index].items.removeAll()
                    changed = true
                }
            }
        }
        if changed {
            saveToDisk()
        }
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            if !fileManager.fileExists(atPath: shelfDirectoryURL.path) {
                try fileManager.createDirectory(at: shelfDirectoryURL, withIntermediateDirectories: true)
            }
            let data = try JSONEncoder().encode(stacks)
            try data.write(to: shelfFileURL)
        } catch {
            print("Failed to save shelf: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard fileManager.fileExists(atPath: shelfFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: shelfFileURL)
            stacks = try JSONDecoder().decode([NSShelfStack].self, from: data)
        } catch {
            print("Failed to load shelf: \(error)")
        }
    }
}
