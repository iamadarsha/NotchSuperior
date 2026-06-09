// ────────────────────────────────────────────────────────
// NotchSuperior — NSMediaActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSMediaActivity: NSActivity {
    let id = UUID()
    let priority = 1
    let ttl: TimeInterval? = nil

    var compactView: AnyView {
        AnyView(NSMediaCompactView())
    }

    var expandedView: AnyView {
        AnyView(NSMediaExpandedView())
    }
}

struct NSMediaCompactView: View {
    @ObservedObject var musicManager = MusicManager.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .frame(width: 16, height: 16)
                .cornerRadius(3)
            
            Text(musicManager.songTitle.isEmpty ? "Not Playing" : musicManager.songTitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            if musicManager.isPlaying {
                Image(systemName: "play.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct NSMediaExpandedView: View {
    @ObservedObject var musicManager = MusicManager.shared

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(nsImage: musicManager.albumArt)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(musicManager.songTitle.isEmpty ? "Unknown Title" : musicManager.songTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(musicManager.artistName.isEmpty ? "Unknown Artist" : musicManager.artistName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            
            HStack(spacing: 20) {
                Button(action: { musicManager.previousTrack() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
                
                Button(action: { musicManager.playPause() }) {
                    Image(systemName: musicManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
                
                Button(action: { musicManager.nextTrack() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                }
                .buttonStyle(.borderless)
            }
            .foregroundStyle(.primary)
            .padding(.top, 4)
        }
        .padding(8)
        .frame(width: 240)
    }
}
