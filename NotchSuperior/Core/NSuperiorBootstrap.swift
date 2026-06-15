// ────────────────────────────────────────────────────────
// NotchSuperior — NSuperiorBootstrap.swift
// Part of the boring.notch fork
// FIX 1: NSDevEngine always starts; widget guard moved inside the engine.
// FIX 2: Bluetooth #available gate lowered to macOS 13.0.
// ────────────────────────────────────────────────────────

import Foundation
import Combine

@MainActor
final class NSuperiorBootstrap {
    static let shared = NSuperiorBootstrap()

    private var cancellables = Set<AnyCancellable>()
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

        // Fetch weather on startup (Open-Meteo, zero API key).
        // Posts NSWeatherActivity to live activity when result arrives.
        // Posts NSNetworkActivity when significant network traffic is detected.
        if #available(macOS 14.0, *) {
            Task { @MainActor in
                NSWeatherEngine.shared.refresh()
                observeWeatherUpdates()
                observeNetworkActivity()
            }
        }
    }

    @available(macOS 14.0, *)
    @MainActor
    private func observeWeatherUpdates() {
        // Post immediately whenever weather changes (fires on first result too, no 30s delay).
        NSWeatherEngine.shared.$weather
            .compactMap { $0 }
            .removeDuplicates { $0.tempC == $1.tempC && $0.weatherCode == $1.weatherCode }
            .receive(on: RunLoop.main)
            .sink { w in
                NSLiveActivityEngine.shared.post(NSWeatherActivity(data: w))
            }
            .store(in: &cancellables)
    }

    @available(macOS 14.0, *)
    @MainActor
    private func observeNetworkActivity() {
        // Start the stats engine so it polls network data
        NSSystemStatsEngine.shared.startMonitoring()
        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 4_000_000_000)  // every 4s
                let dl = NSSystemStatsEngine.shared.downloadSpeedMB
                let ul = NSSystemStatsEngine.shared.uploadSpeedMB
                // Only show live activity when there's measurable traffic (> 50 KB/s)
                if dl > 0.05 || ul > 0.05 {
                    NSLiveActivityEngine.shared.post(NSNetworkActivity(downloadMB: dl, uploadMB: ul))
                } else {
                    // Use stable UUID so we dismiss the exact entry we posted
                    NSLiveActivityEngine.shared.dismiss(NSNetworkActivity.stableID)
                }
            }
        }
    }
}
