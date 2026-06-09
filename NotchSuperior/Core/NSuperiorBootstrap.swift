// ────────────────────────────────────────────────────────
// NotchSuperior — NSuperiorBootstrap.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Foundation

@MainActor
final class NSuperiorBootstrap {
    static let shared = NSuperiorBootstrap()
    
    private init() {}
    
    func start() {
        // Initialize HUD Engine
        _ = NSHUDEngine.shared
        
        // Initialize Live Activity Engine
        _ = NSLiveActivityEngine.shared
        
        // Initialize Shelf Engine
        _ = NSShelfEngine.shared
        
        // Start screen recording observer
        NSScreenRecordObserver.shared.start()
        
        // Start Clipboard Engine
        NSClipboardEngine.shared.start()
        
        // Start Bluetooth Observer on supported OS versions
        if #available(macOS 26.0, *) {
            NSBluetoothObserver.shared.start()
        }
        
        // Load AI states
        NSAIEngine.shared.load()
        NSAINoteEngine.shared.load()
        
        // Setup Command Launcher
        NSCommandEngine.shared.setup()
        
        // Setup Layout Engine
        NSLayoutEngine.shared.setup()
        
        // Setup Dev Status Polling if needed
        if NSLayoutEngine.shared.effectiveWidgets.contains(.gitStatus)
            || NSLayoutEngine.shared.effectiveWidgets.contains(.dockerStatus)
            || NSLayoutEngine.shared.effectiveWidgets.contains(.networkLatency) {
            NSDevEngine.shared.start()
        }
    }
}
