// ────────────────────────────────────────────────────────
// NotchSuperior — NSShelfItemActionsMenu.swift
// Part of the boring.notch fork
// Phase: 3 — Shelf 2.0
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSShelfItemActionsMenu: View {
    let item: NSShelfItem
    @ObservedObject var engine = NSShelfEngine.shared
    
    var body: some View {
        Button(action: {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        }) {
            Label("Quick Look", systemImage: "eye")
        }
        
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.declareTypes([.fileURL, .string], owner: nil)
            pasteboard.writeObjects([item.url as NSURL])
        }) {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        Button(action: {
            compressItem(item)
        }) {
            Label("Compress", systemImage: "archivebox")
        }
        
        Button(action: {
            showShareSheet(for: item)
        }) {
            Label("Share…", systemImage: "square.and.arrow.up")
        }
        
        Button(action: {
            NSSharingService(named: .sendViaAirDrop)?.perform(withItems: [item.url])
        }) {
            Label("Send via AirDrop", systemImage: "wifi")
        }
        
        Divider()
        
        Menu("Move to Stack") {
            ForEach(engine.stacks) { stack in
                if stack.id != item.stackID {
                    Button(stack.name) {
                        engine.move(item: item, to: stack.id)
                    }
                }
            }
        }
        
        Button(role: .destructive, action: {
            engine.remove(item: item)
        }) {
            Label("Remove", systemImage: "trash")
        }
    }
    
    private func compressItem(_ item: NSShelfItem) {
        let fileURL = item.url
        let zipURL = fileURL.deletingPathExtension().appendingPathExtension("zip")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-j", zipURL.path, fileURL.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                NSShelfEngine.shared.add(url: zipURL, to: item.stackID)
            }
        } catch {
            print("Failed to compress file: \(error)")
        }
    }
    
    private func showShareSheet(for item: NSShelfItem) {
        guard let contentView = NSApp.keyWindow?.contentView else { return }
        let picker = NSSharingServicePicker(items: [item.url])
        let mouseLocation = NSEvent.mouseLocation
        let screenRect = NSRect(x: mouseLocation.x, y: mouseLocation.y, width: 1, height: 1)
        if let windowRect = NSApp.keyWindow?.convertFromScreen(screenRect) {
            picker.show(relativeTo: windowRect, of: contentView, preferredEdge: .minY)
        }
    }
}
