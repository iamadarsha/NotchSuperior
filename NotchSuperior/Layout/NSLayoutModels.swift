// ────────────────────────────────────────────────────────
// NotchSuperior — NSLayoutModels.swift
// Part of the boring.notch fork
// Phase: 8 — Layout Engine & Settings UI
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Foundation

enum NSLayoutPreset: String, Codable, CaseIterable {
    case mediaFirst      = "media_first"
    case productivity    = "productivity"
    case minimalHUD      = "minimal_hud"
    case devHUD          = "dev_hud"
    case custom          = "custom"

    var displayName: String {
        switch self {
        case .mediaFirst:   return "Media-First"
        case .productivity: return "Productivity"
        case .minimalHUD:   return "Minimal HUD"
        case .devHUD:       return "Dev HUD"
        case .custom:       return "Custom"
        }
    }

    var description: String {
        switch self {
        case .mediaFirst:   return "Album art, playback controls, visualizer front and center"
        case .productivity: return "Calendar, reminders, focus timer, clipboard access"
        case .minimalHUD:   return "Clean notch with only volume/brightness HUDs, no widgets"
        case .devHUD:       return "Git branch, Docker status, latency checks"
        case .custom:       return "Your saved arrangement"
        }
    }

    // Returns the default widget ordering for this preset
    var defaultWidgetOrder: [NSWidgetSlot] {
        switch self {
        case .mediaFirst:
            return [.musicVisualizer, .nowPlaying, .volumeHUD]
        case .productivity:
            return [.calendar, .reminders, .focusTimer, .clipboardShortcut]
        case .minimalHUD:
            return [.volumeHUD, .brightnessHUD]
        case .devHUD:
            return [.gitStatus, .dockerStatus, .networkLatency]
        case .custom:
            return []
        }
    }
}

enum NSWidgetSlot: String, Codable, CaseIterable, Identifiable {
    case musicVisualizer    = "music_visualizer"
    case nowPlaying         = "now_playing"
    case volumeHUD          = "volume_hud"
    case brightnessHUD      = "brightness_hud"
    case calendar           = "calendar"
    case reminders          = "reminders"
    case focusTimer         = "focus_timer"
    case clipboardShortcut  = "clipboard_shortcut"
    case gitStatus          = "git_status"
    case dockerStatus       = "docker_status"
    case networkLatency     = "network_latency"
    case cameraPreview      = "camera_preview"
    case weather            = "weather"
    case batteryDetailed    = "battery_detailed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .musicVisualizer:   return "Music Visualizer"
        case .nowPlaying:        return "Now Playing"
        case .volumeHUD:         return "Volume HUD"
        case .brightnessHUD:     return "Brightness HUD"
        case .calendar:          return "Calendar"
        case .reminders:         return "Reminders"
        case .focusTimer:        return "Focus Timer"
        case .clipboardShortcut: return "Clipboard"
        case .gitStatus:         return "Git Status"
        case .dockerStatus:      return "Docker Status"
        case .networkLatency:    return "Network Latency"
        case .cameraPreview:     return "Camera Preview"
        case .weather:           return "Weather"
        case .batteryDetailed:   return "Battery Detail"
        }
    }

    var icon: String {
        switch self {
        case .musicVisualizer:   return "waveform"
        case .nowPlaying:        return "music.note"
        case .volumeHUD:         return "speaker.wave.2"
        case .brightnessHUD:     return "sun.max"
        case .calendar:          return "calendar"
        case .reminders:         return "checklist"
        case .focusTimer:        return "timer"
        case .clipboardShortcut: return "doc.on.clipboard"
        case .gitStatus:         return "arrow.triangle.branch"
        case .dockerStatus:      return "shippingbox"
        case .networkLatency:    return "network"
        case .cameraPreview:     return "camera"
        case .weather:           return "cloud.sun"
        case .batteryDetailed:   return "battery.100"
        }
    }
}

struct NSLayoutProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var preset: NSLayoutPreset
    var enabledWidgets: [NSWidgetSlot]   // ordered list
    var isActive: Bool
    // Per-Space/app overrides (app bundle ID → enabled widgets)
    var appOverrides: [String: [NSWidgetSlot]]
}
