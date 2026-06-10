# AGENT_CONTEXT

## Status
- Current Phase: ALL PHASES COMPLETE (1–9)
- Last Completed Task: Phase 8 Layout Engine, Phase 9 Dev Tools, and Task C Final Polish (dynamically bypass spring animation, complete stub activities, README update).
- Next Task: Manual QA on real hardware — test all features.
- Blocked By: None
- Build Status: Compiles ✅ (0 errors) final via `xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations (with presenting/battery saver bypass).
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/Core/NSuperiorBootstrap.swift` - Main engine bootstrap class. Starts HUD, Live Activity, Shelf, Clipboard, AI/Command engines, Layout engine, and Dev engine.
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
- `NotchSuperior/LiveActivity/Activities/NSMediaActivity.swift` - Media now playing activity with controls.
- `NotchSuperior/LiveActivity/Activities/NSTimerActivity.swift` - Countdown timer live activity.
- `NotchSuperior/LiveActivity/Activities/NSBatteryActivity.swift` - Battery details and charging active activity.
- `NotchSuperior/LiveActivity/Activities/NSPrivacyDotActivity.swift` - Camera/Mic active privacy dot indicator activity.
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
- `NotchSuperior/AI/NSAIModels.swift` - AI provider, message, templates, and note structures.
- `NotchSuperior/AI/NSAIKeyStore.swift` - Secure keychain wrapper for saving and fetching API keys.
- `NotchSuperior/AI/NSAIEngine.swift` - Streaming API network completion manager and conversations storage.
- `NotchSuperior/AI/NSAIChatView.swift` - Overlay slide-down AI chat screen.
- `NotchSuperior/AI/NSAINoteEngine.swift` - AVAudioEngine voice capture, local speech-to-text transcriber, and summarization.
- `NotchSuperior/AI/NSAINotesView.swift` - Sidebar list and detail transcription workspace view.
- `NotchSuperior/AI/NSAISettingsSection.swift` - Secure key-saving form in Settings.
- `NotchSuperior/CommandLauncher/NSCommandModels.swift` - Launchable interfaces, shell script commands, and system Shortcuts wrappers.
- `NotchSuperior/CommandLauncher/NSCommandEngine.swift` - Search filtering engine indexer and custom commands list persistent writer (with terminal commands).
- `NotchSuperior/CommandLauncher/NSCommandLauncherView.swift` - Slide-down Command Launcher panel.
- `NotchSuperior/Layout/NSLayoutModels.swift` - Layout preset, widget slot and profile structures.
- `NotchSuperior/Layout/NSLayoutEngine.swift` - Layout manager with frontmost app observation overrides.
- `NotchSuperior/Layout/NSLayoutSettingsView.swift` - Drag-reorder layouts profile editor settings panel.
- `NotchSuperior/Layout/NSBehaviorProfilesView.swift` - Presenter mode, Battery Saver, and Focus mode toggle panel.
- `NotchSuperior/DevTools/NSDevModels.swift` - Developer status, config, and status item structures.
- `NotchSuperior/DevTools/NSDevEngine.swift` - Status monitoring engine checking Git, Docker, and Host ping latency.
- `NotchSuperior/DevTools/NSDevHUDView.swift` - Status tiles overlay view strip.
- `NotchSuperior/DevTools/NSTerminalDropView.swift` - Slide-down Guake-style terminal.
- `NotchSuperior/DevTools/NSDevSettingsSection.swift` - Git, Docker, latency, and shell configuration settings panel.
- `NotchSuperior/NOTCHSUPERIOR_README.md` - Markdown README summarizing NotchSuperior fork and build instructions.
- `boringNotch/ContentView.swift` - Integrated layout widget checks, terminal drop-down view, and HUD/clipboard checks.
- `boringNotch/boringNotchApp.swift` - Registered terminal key shortcuts listener.
- `boringNotch/Shortcuts/ShortcutConstants.swift` - Registered global backtick terminal shortcut constant.
- `boringNotch.xcodeproj/project.pbxproj` - Registered new Layout, DevTools, and README files/groups to compile target.

## Architecture Decisions
- Converted message UUIDs to string values for ScrollView scrolling targets in `NSAIChatView.swift` to resolve strict Swift compile type mismatches when using mixed String (e.g. `"streaming"`) and UUID targets.
- Implemented temporary conversation injection inside `NSAINoteEngine.swift` before calling `NSAIEngine.sendMessage(_:in:contextText:)` during note summarization to satisfy the conversation search validation checks in the engine.
- Leveraged `.onKeyPress` modifiers on `NSCommandLauncherView` to provide robust, localized arrow-key list navigation and Escape key dismissal on macOS.
- Updated sandbox entitlements and Plist descriptions for Speech Recognition and Microphone access to satisfy the SFSpeechRecognizer requirements.
- Implemented app frontmost activate observer to automatically notify layout engine of window focus changes, recalculating effective widgets and swapping presets instantly.
- Dynamically bypassed animation springs with zero-duration ease-out transitions when Battery Saver or Presenting Mode is turned on to reduce CPU wakeups and prevent projection display stutter.
- Utilized SwiftUI's optimized `Text(endDate, style: .timer)` to power the countdown timer live activity, achieving zero main-thread polling overhead.

## Known Issues / TODOs
- None. All features are fully implemented, committed, and clean-built. Verified via QA audit pass.

## QA Audit Pass (2026-06-10)
- Verified all 52 files from the spec exist and contain complete, non-stubbed implementations.
- Updated Sandbox Entitlements for Microphone and Speech Recognition to use standard App Sandbox keys (`com.apple.security.device.microphone` and `com.apple.security.personal-information.speech-recognition`).
- Fixed developer widget integration: wrapped widget slots (Music Player, Calendar, Camera) in `NotchHomeView.swift` with layout engine check (`isEnabled`), added `NSDevHUDView` under `NotchHomeView` when open, and integrated compact `NSDevStatusTile` into `ContentView.swift` for the closed state.
- Verified clean build (`** BUILD SUCCEEDED **`) for the `boringNotch` target in Xcode.

## How to Resume
1. Run on a real MacBook with a screen notch.
2. Open `boringNotch.xcodeproj` and compile the `boringNotch` target.
3. Perform manual QA on the settings options (General, Appearance, HUD & Display, Layout Profiles, Behavior Profiles, Dev Tools, AI Chat, etc.).

