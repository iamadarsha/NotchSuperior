// ────────────────────────────────────────────────────────
// NotchSuperior — NSDownloadActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSDownloadActivity: NSActivity {
    let id: UUID
    let priority: Int = 6
    let ttl: TimeInterval? = nil
    
    let filename: String
    let progress: Double
    let url: URL?
    let bytesWritten: Int64
    let totalBytes: Int64
    
    init(id: UUID = UUID(), filename: String, progress: Double, url: URL? = nil, bytesWritten: Int64 = 0, totalBytes: Int64 = 100) {
        self.id = id
        self.filename = filename
        self.progress = progress
        self.url = url
        self.bytesWritten = bytesWritten
        self.totalBytes = totalBytes
        
        if progress >= 1.0 {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                NSLiveActivityEngine.shared.dismiss(id)
            }
        }
    }
    
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
                Text(filename)
                    .lineLimit(1)
                    .font(.caption2)
            }
        )
    }
    
    var expandedView: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text(filename)
                    .font(.headline)
                    .lineLimit(1)
                
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                
                HStack {
                    if totalBytes > 0 {
                        Text("\(ByteCountFormatter.string(fromByteCount: bytesWritten, countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(format: "%.0f%%", progress * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        NSLiveActivityEngine.shared.dismiss(id)
                    }) {
                        Text("Cancel")
                            .font(.caption)
                            .padding(.horizontal, 8)
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
