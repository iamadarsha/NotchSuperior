// ────────────────────────────────────────────────────────
// NotchSuperior — NSDevHUDView.swift
// Part of the boring.notch fork
// Phase: 9 — Dev / Power-User Tools
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

// Compact tile strip shown inside the notch when devHUD layout is active
@available(macOS 14.0, *)
struct NSDevHUDView: View {
    @ObservedObject var engine = NSDevEngine.shared

    var body: some View {
        HStack(spacing: 8) {
            ForEach(engine.items) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(item.status.color)
                    Text(item.value)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 5))
            }
            // Refresh button
            Button(action: { Task { await engine.refresh() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
    }
}

// Compact status view for the closed notch state
@available(macOS 14.0, *)
struct NSDevStatusTile: View {
    @ObservedObject var engine = NSDevEngine.shared
    @EnvironmentObject var vm: BoringViewModel

    var body: some View {
        HStack(spacing: 8) {
            // Git Branch
            if let gitItem = engine.items.first(where: { $0.icon == "arrow.triangle.branch" }) {
                HStack(spacing: 3) {
                    Image(systemName: gitItem.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(gitItem.status.color)
                    Text(gitItem.value)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            // Docker Count
            if let dockerItem = engine.items.first(where: { $0.icon == "shippingbox" }) {
                HStack(spacing: 3) {
                    Image(systemName: dockerItem.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(dockerItem.status.color)
                    Text(dockerItem.value.replacingOccurrences(of: " running", with: ""))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial, in: Capsule())
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(NSTokens.animationSpring) {
                vm.open()
            }
        }
    }
}

