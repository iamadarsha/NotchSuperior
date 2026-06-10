// ────────────────────────────────────────────────────────
// NotchSuperior — NSShelfView.swift
// Part of the boring.notch fork
// Phase: 3 — Shelf 2.0
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI
import UniformTypeIdentifiers

@available(macOS 14.0, *)
struct NSShelfView: View {
    @ObservedObject var engine = NSShelfEngine.shared
    @State private var selectedStackID: UUID?
    
    private var activeStackID: UUID? {
        selectedStackID ?? engine.stacks.first?.id
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Horizontal Stack Tabs
            HStack(spacing: 16) {
                ForEach(engine.stacks) { stack in
                    Button(action: {
                        selectedStackID = stack.id
                    }) {
                        HStack(spacing: 4) {
                            Text(stack.name)
                                .font(.caption.bold())
                                .foregroundColor(activeStackID == stack.id ? .primary : .secondary)
                            
                            if stack.showBadge && !stack.items.isEmpty {
                                Text("\(stack.items.count)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Stack Items LazyHStack
            let currentStack = engine.stacks.first(where: { $0.id == activeStackID })
            
            Group {
                if let items = currentStack?.items, !items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 14) {
                            ForEach(items) { item in
                                NSShelfItemTile(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .frame(height: 100)
                } else {
                    VStack {
                        Spacer()
                        Text("Drag files here to add to \(currentStack?.name ?? "stack")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let activeID = activeStackID else { return false }
            
            for provider in providers {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    var resolvedURL: URL?
                    if let url = item as? URL {
                        resolvedURL = url
                    } else if let nsURL = item as? NSURL {
                        resolvedURL = nsURL as URL
                    } else if let data = item as? Data {
                        resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
                    }
                    
                    if let url = resolvedURL {
                        Task { @MainActor in
                            NSShelfEngine.shared.add(url: url, to: activeID)
                        }
                    }
                }
            }
            return true
        }
    }
}

@available(macOS 14.0, *)
struct NSShelfItemTile: View {
    let item: NSShelfItem
    @ObservedObject var engine = NSShelfEngine.shared
    
    var body: some View {
        let stack = engine.stacks.first(where: { $0.id == item.stackID })
        let icon = item.thumbnail ?? NSWorkspace.shared.icon(for: UTType.item)
        
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .padding(12)
                    .shelfGlass()
                
                if let stack = stack, let expStr = expiryString(for: item, stack: stack) {
                    Text(expStr)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.red))
                        .foregroundColor(.white)
                        .offset(x: 4, y: -4)
                }
            }
            
            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 64)
                .foregroundColor(.primary)
        }
        .contextMenu {
            NSShelfItemActionsMenu(item: item)
        }
    }
    
    private func expiryString(for item: NSShelfItem, stack: NSShelfStack) -> String? {
        guard let expiresAt = stack.expiry.expiresAt(from: item.addedAt) else { return nil }
        let diff = expiresAt.timeIntervalSince(Date())
        if diff <= 0 { return "Exp" }
        
        if diff > 3600 {
            return "\(Int(diff / 3600))h"
        } else {
            return "\(Int(diff / 60))m"
        }
    }
}
