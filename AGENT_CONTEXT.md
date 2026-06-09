# AGENT_CONTEXT

## Status
- Current Phase: Phase 5 complete / Phase 6 starting
- Last Completed Task: Focus & Pomodoro Timer (implemented NSFocusEngine, NSFocusActivity, and settings interface)
- Next Task: Phase 6 — AI Chat + AI Notes Layer (Implement NSAIChatEngine, NSAIChatView, and NSAINoteEngine)
- Blocked By: None
- Build Status: Compiles ✅ (0 errors) via `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations.
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/Core/NSuperiorBootstrap.swift` - Main engine bootstrap class. Starts HUD, Live Activity, Shelf, and Clipboard engines.
- `NotchSuperior/HUD/NSHUDTheme.swift` - Theme enum with `UserDefaults` persistence under `NSHUDTheme`.
- `NotchSuperior/HUD/NSHUDEngine.swift` - Observable HUD engine that listens to existing managers and publishes themed HUD events.
- `NotchSuperior/HUD/NSHUDOverlayView.swift` - SwiftUI overlay that renders single or combined HUD cards.
- `NotchSuperior/Settings/NSHUDSettingsSection.swift` - HUD & Display settings panel for theme, dismiss timing, etc.
- `NotchSuperior/LiveActivity/NSLiveActivityEngine.swift` - Live Activity Engine priority queue with type-based dismissal support.
- `NotchSuperior/LiveActivity/NSLiveActivityView.swift` - Presentation view overlay for compact and expanded states.
- `NotchSuperior/LiveActivity/Activities/NSDownloadActivity.swift` - Download activity implementation.
- `NotchSuperior/LiveActivity/Activities/NSAirDropActivity.swift` - AirDrop activity implementation.
- `NotchSuperior/LiveActivity/Activities/NSBluetoothActivity.swift` - Bluetooth activity implementation.
- `NotchSuperior/LiveActivity/Activities/NSScreenRecordActivity.swift` - Screen recording active activity.
- `NotchSuperior/LiveActivity/Activities/NSFocusActivity.swift` - [NEW] Focus and Pomodoro live activity compact and expanded state handler.
- `NotchSuperior/Shelf/NSShelfModels.swift` - Shelf data structures for items, stacks, and expiration policies.
- `NotchSuperior/Shelf/NSShelfEngine.swift` - Persistence engine managing custom/default stacks.
- `NotchSuperior/Shelf/NSShelfView.swift` - Tabs selector, LazyHStack of rounded glass tiles, etc.
- `NotchSuperior/Shelf/NSShelfItemActionsMenu.swift` - Action items menu.
- `NotchSuperior/Clipboard/NSClipboardModels.swift` - [NEW] Clipboard and Snippet data structures.
- `NotchSuperior/Clipboard/NSClipboardEngine.swift` - [NEW] Polling pasteboard loop, deduplication, and persistence management.
- `NotchSuperior/Clipboard/NSClipboardView.swift` - [NEW] Segemented tab manager for clipboard lists.
- `NotchSuperior/Clipboard/NSClipboardItemRow.swift` - [NEW] List rows with contextual actions (pin, copy, label settings, delete).
- `NotchSuperior/Clipboard/NSSnippetRow.swift` - [NEW] Text snippet presentation row.
- `NotchSuperior/Clipboard/NSSnippetEditorView.swift` - [NEW] Grouped editor sheet for custom snippets.
- `NotchSuperior/Focus/NSFocusModels.swift` - [NEW] Focus session options and stats structures.
- `NotchSuperior/Focus/NSFocusEngine.swift` - [NEW] Focus/Pomodoro state machine.
- `NotchSuperior/Focus/NSFocusExpandedView.swift` - [NEW] Circular ring progress display and session controls.
- `NotchSuperior/Focus/NSFocusSettingsSection.swift` - [NEW] Stepper controls for focus/break durations.
- `boringNotch/ContentView.swift` - Integrated live activity, shelf, and top slide-down clipboard panel overlay.
- `boringNotch/boringNotchApp.swift` - Wired NSuperiorBootstrap startup and registered global shortcuts.
- `boringNotch.xcodeproj/project.pbxproj` - Added new Clipboard and Focus groups/files to compile target source list.

## Architecture Decisions
- Maintained backward compatibility with macOS 14 through `@available(macOS 26.0, *)` and `#available` runtime checks, protecting newer features (e.g. Liquid Glass material styles and live activity overlays).
- Extended `NSLiveActivityEngine` with type-based `dismiss(for:)` function to let features like `NSFocusEngine` cleanly tear down their UI presence on stop.
- Coupled `NSClipboardOpen` state to notch open state: when the clipboard panel is requested via ⌘⇧V, the notch is forced open. If the notch closes, the clipboard state is automatically reset to false.

## Known Issues / TODOs
- Local speech-to-text transcription engine for AI voice notes (Phase 6).

## How to Resume
1. Stay in `/Users/iamadarsha/Downloads/boring.notch-main` on branch `feature/notch-superior`.
2. Run command to verify build:
   `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`
3. Next task: Build Phase 6: AI Chat + AI Notes Layer (NSAIChatEngine, NSAIChatView, NSAINoteEngine).
