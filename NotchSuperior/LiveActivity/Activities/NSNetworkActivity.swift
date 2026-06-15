// ────────────────────────────────────────────────────────
// NotchSuperior — NSNetworkActivity.swift
// Part of the boring.notch fork
// Phase: 11 — Network Speed Live Activity
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Shows real-time download/upload speed in closed notch.
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSNetworkActivity: NSActivity {
    // Stable ID so re-posting with new speeds replaces the existing entry.
    static let stableID = UUID(uuidString: "BB000002-0000-0000-0000-000000000002")!
    let id: UUID = NSNetworkActivity.stableID
    let priority = 2
    let ttl: TimeInterval? = nil

    let downloadMB: Double
    let uploadMB:   Double

    @MainActor
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 6) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.cyan)
                    Text(NSSystemStatsEngine.formatBytes(downloadMB))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                    Text(NSSystemStatsEngine.formatBytes(uploadMB))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        )
    }

    @MainActor
    var expandedView: AnyView {
        AnyView(
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.cyan)
                    Text(NSSystemStatsEngine.formatBytes(downloadMB))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Download")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.orange)
                    Text(NSSystemStatsEngine.formatBytes(uploadMB))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Upload")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        )
    }
}
