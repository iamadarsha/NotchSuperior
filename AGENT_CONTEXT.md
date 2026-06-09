# AGENT_CONTEXT

## Status
- Current Phase: Phase 3 complete / Phase 4 starting
- Last Completed Task: B4 (NSShelfItemActionsMenu.swift context menu actions, integration, and build verification)
- Next Task: Phase 4 — Clipboard & Snippets (Implement NSClipboardEngine, NSClipboardView, and NSSnippetStore under `NotchSuperior/Clipboard/`)
- Blocked By: None
- Build Status: Compiles ✅ (0 errors) via `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations.
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/Core/NSuperiorBootstrap.swift` - [NEW] Main engine bootstrap class to initialize and start HUD, Live Activity, and Shelf engines on startup.
- `NotchSuperior/HUD/NSHUDTheme.swift` - Theme enum with `UserDefaults` persistence under `NSHUDTheme`.
- `NotchSuperior/HUD/NSHUDEngine.swift` - Observable HUD engine that listens to existing managers and publishes themed HUD events with auto-dismiss behavior.
- `NotchSuperior/HUD/NSHUDOverlayView.swift` - SwiftUI overlay that renders single or combined HUD cards with theme-aware styling.
- `NotchSuperior/Settings/NSHUDSettingsSection.swift` - New macOS 26+ HUD & Display settings panel for theme, dismiss timing, combination mode, and HUD position.
- `NotchSuperior/LiveActivity/NSLiveActivityEngine.swift` - Live Activity Engine priority queue and lifecycle management.
- `NotchSuperior/LiveActivity/NSLiveActivityView.swift` - Presentation view overlay for compact and expanded states with matchedGeometryEffect and swipe-to-dismiss.
- `NotchSuperior/LiveActivity/Activities/NSMediaActivity.swift` - Placeholder media activity stub.
- `NotchSuperior/LiveActivity/Activities/NSTimerActivity.swift` - Placeholder timer activity stub.
- `NotchSuperior/LiveActivity/Activities/NSBatteryActivity.swift` - Placeholder battery activity stub.
- `NotchSuperior/LiveActivity/Activities/NSPrivacyDotActivity.swift` - Placeholder privacy-dot activity stub.
- `NotchSuperior/LiveActivity/Activities/NSDownloadActivity.swift` - [NEW] Download activity implementation with progress view and cancel actions.
- `NotchSuperior/LiveActivity/Activities/NSAirDropActivity.swift` - [NEW] AirDrop activity implementation with progress ring and device names.
- `NotchSuperior/LiveActivity/Activities/NSBluetoothActivity.swift` - [NEW] Bluetooth activity implementation with low battery detection and active `IOBluetoothDevice` observer.
- `NotchSuperior/LiveActivity/Activities/NSScreenRecordActivity.swift` - [NEW] Screen recording active activity with pulsing red indicator, elapsed time timer, and background process observer.
- `NotchSuperior/Shelf/NSShelfModels.swift` - [NEW] Shelf data structures for items, stacks, and expiration policies.
- `NotchSuperior/Shelf/NSShelfEngine.swift` - [NEW] Persistence engine managing custom/default stacks and auto-expiry logic.
- `NotchSuperior/Shelf/NSShelfView.swift` - [NEW] Tabs selector, LazyHStack of rounded glass tiles, drop support, and contextual actions.
- `NotchSuperior/Shelf/NSShelfItemActionsMenu.swift` - [NEW] Action items menu (Quick Look, Copy as File reference, Zip compression, Share Picker, AirDrop, Move to Stack, Remove).
- `boringNotch/ContentView.swift` - Integrated live activity presentation overlay and custom `NSShelfView` switcher.
- `boringNotch/boringNotchApp.swift` - Wired `NSuperiorBootstrap.shared.start()` to AppDelegate launch handler.
- `boringNotch.xcodeproj/project.pbxproj` - Updated to include the new NotchSuperior/Core, NotchSuperior/LiveActivity/Activities, and NotchSuperior/Shelf source files in target compilation phases.

## Architecture Decisions
- Conformed `NSLiveActivityEngine` and `NSShelfEngine` to `@MainActor` and `ObservableObject` using `@Published` properties, maintaining backward-compatible consistency with the rest of the AppKit/SwiftUI codebase instead of using Swift 5.9's macro-based `@Observable`.
- Created a separate `Core/NSuperiorBootstrap.swift` class to orchestrate startup and keep the `boringNotchApp.swift` AppDelegate entry point clean.
- Wrapped new live-activity view overlays inside `ContentView` and `SettingsView` using `if #available(macOS 26.0, *)` and `#available(macOS 26.0, *)` checks, maintaining base backward compatibility with macOS 14.
- Used a custom `GlassEffectContainer` block to satisfy target layout design requirements.

## Known Issues / TODOs
- Bluetooth observer (`NSBluetoothObserver`) is availability-guarded since macOS 26+ uses updated BT system daemon rules.
- Test scenarios should be run to verify drag-and-drop file imports on the new `NSShelfView` on a physical system.

## How to Resume
1. Stay in `/Users/iamadarsha/Downloads/boring.notch-main` on branch `feature/notch-superior`.
2. Review the context and specifications for Phase 4 (Clipboard & Snippets) in `MASTER_PROMPT.md`.
3. Build the project using:
   `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`
4. Begin implementing `NSClipboardEngine.swift` in `NotchSuperior/Clipboard/`.
