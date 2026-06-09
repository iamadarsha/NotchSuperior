// ────────────────────────────────────────────────────────
// NotchSuperior — NSAirDropActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSAirDropActivity: NSActivity {
    enum Direction: String, Codable {
        case sending
        case receiving
    }
    
    let id: UUID
    let priority: Int = 6
    let ttl: TimeInterval? = 8.0
    
    let deviceName: String
    let filename: String
    let direction: Direction
    
    init(id: UUID = UUID(), deviceName: String, filename: String, direction: Direction) {
        self.id = id
        self.deviceName = deviceName
        self.filename = filename
        self.direction = direction
    }
    
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.accentColor)
                Text(deviceName)
                    .lineLimit(1)
                    .font(.caption2)
            }
        )
    }
    
    var expandedView: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: direction == .sending ? "square.and.arrow.up" : "square.and.arrow.down")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(direction == .sending ? "Sending File..." : "Receiving File...")
                            .font(.headline)
                        Text(filename)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }
                
                Text(direction == .sending ? "To: \(deviceName)" : "From: \(deviceName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Spacer()
                    Button(action: {
                        NSLiveActivityEngine.shared.dismiss(id)
                    }) {
                        Text("Dismiss")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.primary.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        )
    }
}
