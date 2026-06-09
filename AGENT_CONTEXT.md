# AGENT_CONTEXT

## Status
- Current Phase: Phase 7 complete / Phase 8 starting
- Last Completed Task: Phase 6 (AI Chat & AI Notes Layer) and Phase 7 (Command Launcher) fully implemented, integrated, and verified compiling.
- Next Task: Phase 8 — Layout Engine & Settings UI
- Blocked By: None
- Build Status: Compiles ✅ (0 errors) via `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations.
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/Core/NSuperiorBootstrap.swift` - Main engine bootstrap class. Starts HUD, Live Activity, Shelf, Clipboard, and AI/Command engines.
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
- `NotchSuperior/LiveActivity/Activities/NSFocusActivity.swift` - Focus and Pomodoro live activity compact and expanded state handler.
- `NotchSuperior/Shelf/NSShelfModels.swift` - Shelf data structures for items, stacks, and expiration policies.
- `NotchSuperior/Shelf/NSShelfEngine.swift` - Persistence engine managing custom/default stacks.
- `NotchSuperior/Shelf/NSShelfView.swift` - Tabs selector, LazyHStack of rounded glass tiles, etc.
- `NotchSuperior/Shelf/NSShelfItemActionsMenu.swift` - Action items menu.
- `NotchSuperior/Clipboard/NSClipboardModels.swift` - Clipboard and Snippet data structures.
- `NotchSuperior/Clipboard/NSClipboardEngine.swift` - Polling pasteboard loop, deduplication, and persistence management.
- `NotchSuperior/Clipboard/NSClipboardView.swift` - Segemented tab manager for clipboard lists.
- `NotchSuperior/Clipboard/NSClipboardItemRow.swift` - List rows with contextual actions (pin, copy, label settings, delete).
- `NotchSuperior/Clipboard/NSSnippetRow.swift` - Text snippet presentation row.
- `NotchSuperior/Clipboard/NSSnippetEditorView.swift` - Grouped editor sheet for custom snippets.
- `NotchSuperior/Focus/NSFocusModels.swift` - Focus session options and stats structures.
- `NotchSuperior/Focus/NSFocusEngine.swift` - Focus/Pomodoro state machine.
- `NotchSuperior/Focus/NSFocusExpandedView.swift` - Circular ring progress display and session controls.
- `NotchSuperior/Focus/NSFocusSettingsSection.swift` - Stepper controls for focus/break durations.
- `NotchSuperior/AI/NSAIModels.swift` - [NEW] AI provider, message, templates, and note structures.
- `NotchSuperior/AI/NSAIKeyStore.swift` - [NEW] Secure keychain wrapper for saving and fetching API keys.
- `NotchSuperior/AI/NSAIEngine.swift` - [NEW] Streaming API network completion manager and conversations storage.
- `NotchSuperior/AI/NSAIChatView.swift` - [NEW] Overlay slide-down AI chat screen.
- `NotchSuperior/AI/NSAINoteEngine.swift` - [NEW] AVAudioEngine voice capture, local speech-to-text transcriber, and summarization.
- `NotchSuperior/AI/NSAINotesView.swift` - [NEW] Sidebar list and detail transcription workspace view.
- `NotchSuperior/AI/NSAISettingsSection.swift` - [NEW] Secure key-saving form in Settings.
- `NotchSuperior/CommandLauncher/NSCommandModels.swift` - [NEW] Launchable interfaces, shell script commands, and system Shortcuts wrappers.
- `NotchSuperior/CommandLauncher/NSCommandEngine.swift` - [NEW] Search filtering engine indexer and custom commands list persistent writer.
- `NotchSuperior/CommandLauncher/NSCommandLauncherView.swift` - [NEW] Slide-down Command Launcher panel.
- `boringNotch/ContentView.swift` - Integrated live activity, shelf, top slide-down clipboard panel, AI chat overlay, and command launcher overlay.
- `boringNotch/boringNotchApp.swift` - Wired NSuperiorBootstrap startup and registered global shortcuts.
- `boringNotch.xcodeproj/project.pbxproj` - Added new AI and CommandLauncher groups/files to compile target source list.

## Architecture Decisions
- Converted message UUIDs to string values for ScrollView scrolling targets in `NSAIChatView.swift` to resolve strict Swift compile type mismatches when using mixed String (e.g. `"streaming"`) and UUID targets.
- Implemented temporary conversation injection inside `NSAINoteEngine.swift` before calling `NSAIEngine.sendMessage(_:in:contextText:)` during note summarization to satisfy the conversation search validation checks in the engine.
- Leveraged `.onKeyPress` modifiers on `NSCommandLauncherView` to provide robust, localized arrow-key list navigation and Escape key dismissal on macOS.
- Updated sandbox entitlements and Plist descriptions for Speech Recognition and Microphone access to satisfy the SFSpeechRecognizer requirements.

## Known Issues / TODOs
- Layout profiles selection (Phase 8).

## How to Resume
1. Stay in `/Users/iamadarsha/Downloads/boring.notch-main` on branch `feature/notch-superior`.
2. Run command to verify build:
   `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`
3. Next task: Build Phase 8: Layout Engine & Settings UI.
