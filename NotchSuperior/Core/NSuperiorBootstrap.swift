// ────────────────────────────────────────────────────────
// NotchSuperior — NSuperiorBootstrap.swift
// Part of the boring.notch fork
// FIX 1: NSDevEngine always starts; widget guard moved inside the engine.
// FIX 2: Bluetooth #available gate lowered to macOS 13.0.
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

        // FIX 2: CoreBluetooth device detection is available since macOS 12;
        // the original macOS 14 gate was unnecessarily restrictive.
        if #available(macOS 13.0, *) {
            NSBluetoothObserver.shared.start()
        }

        // Load AI states
        NSAIEngine.shared.load()
        NSAINoteEngine.shared.load()

        // Setup Command Launcher
        NSCommandEngine.shared.setup()

        // Setup Layout Engine
        NSLayoutEngine.shared.setup()

        // FIX 1: Always start NSDevEngine unconditionally.
        // NSDevEngine.start() is idempotent and self-gates internally
        // based on config + widget enablement; a conditional here caused
        // the engine to never start when the layout profile was loaded
        // asynchronously or from a fresh (empty) default profile.
        NSDevEngine.shared.start()
    }
}
