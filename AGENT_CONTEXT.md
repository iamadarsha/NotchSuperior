# AGENT_CONTEXT

## Status
- Current Phase: Phase 2 - Live Activity Scaffold Started
- Last Completed Task: Completed Step 5 handoff prep after a successful Debug build, Phase 1 `HUD & Display` settings integration, and Phase 2 live-activity stub registration.
- Next Task: Replace the Phase 2 stubs in `NotchSuperior/LiveActivity/` with real activity models, queueing logic, and notch presentation behavior, starting with `NSLiveActivityEngine.swift`.
- Blocked By: Global `xcode-select -s /Applications/Xcode.app/Contents/Developer` still requires `sudo`; this session built successfully via `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.
- Build Status: Compiles ✅ (0 errors) via `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build`

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations.
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/HUD/NSHUDTheme.swift` - Theme enum with `UserDefaults` persistence under `NSHUDTheme`.
- `NotchSuperior/HUD/NSHUDEngine.swift` - Observable HUD engine that listens to existing managers and publishes themed HUD events with auto-dismiss behavior.
- `NotchSuperior/HUD/NSHUDOverlayView.swift` - SwiftUI overlay that renders single or combined HUD cards with theme-aware styling.
- `NotchSuperior/Settings/NSHUDSettingsSection.swift` - New macOS 26+ HUD & Display settings panel for theme, dismiss timing, combination mode, and HUD position.
- `NotchSuperior/LiveActivity/NSLiveActivityEngine.swift` - Phase 2 stub activity engine and `NSActivity` protocol.
- `NotchSuperior/LiveActivity/NSLiveActivityView.swift` - Phase 2 stub live-activity presentation view.
- `NotchSuperior/LiveActivity/Activities/NSMediaActivity.swift` - Placeholder media activity stub.
- `NotchSuperior/LiveActivity/Activities/NSTimerActivity.swift` - Placeholder timer activity stub.
- `NotchSuperior/LiveActivity/Activities/NSBatteryActivity.swift` - Placeholder battery activity stub.
- `NotchSuperior/LiveActivity/Activities/NSPrivacyDotActivity.swift` - Placeholder privacy-dot activity stub.
- `boringNotch/ContentView.swift` - Mounted the new NotchSuperior HUD overlay on top of the existing notch UI.
- `boringNotch/components/Settings/SettingsView.swift` - Added the new `HUD & Display` navigation destination and availability-aware detail view.
- `boringNotch.xcodeproj/project.pbxproj` - Added the `NotchSuperior` group/files to the app target and updated bundle/display identity settings for NotchSuperior.

## Architecture Decisions
- The new NotchSuperior layer will be added in a parallel top-level `NotchSuperior/` folder to keep upstream merge paths clean.
- Existing boring.notch HUD and media-key code will be treated as the event seam; new HUD logic will observe and extend it rather than replace large portions of the original code in place.
- The first pass uses the existing `VolumeManager`, `BrightnessManager`, `KeyboardBacklightManager`, and `MusicManager` publishers as the authoritative live signal source, while still ensuring the existing media-key interceptor is active when HUD replacement is enabled.
- The `HUD & Display` pane is isolated behind a macOS 26 availability gate while the app continues to build against a macOS 14 deployment target.
- Phase 2 is scaffolded only: the `NSActivity` protocol and four stub activities compile, but no real priority queue or system integrations are implemented yet.

## Known Issues / TODOs
- The repo is now initialized locally with `origin` set to `https://github.com/TheBoredTeam/boring.notch.git` and the working branch is `feature/notch-superior`.
- Builds succeed, but the linker still warns that `MediaRemoteAdapter.framework` was built for macOS 15 while the app target is building for macOS 14.
- The remaining Phase 2 activity stubs from `MASTER_PROMPT.md` are still missing: download, AirDrop, Bluetooth, and screen-record activities.
- The HUD position control is wired into the overlay layout, but no notch-anchored live-activity choreography exists yet.

## How to Resume
1. Stay in `/Users/iamadarsha/Downloads/boring.notch-main`.
2. Read this file first, then open `/Users/iamadarsha/Downloads/boring.notch-main/MASTER_PROMPT.md` only if you need the broader staged roadmap.
3. Build with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -scheme boringNotch -destination "platform=macOS" -configuration Debug build` if the global developer directory is still unset.
4. Continue in `feature/notch-superior`.
5. Implement real `NSLiveActivityEngine` queueing and the remaining activity files under `NotchSuperior/LiveActivity/Activities/`.
6. After that, integrate `NSLiveActivityView` into the notch UI and start replacing placeholder `EmptyView()` bodies with real compact and expanded views.
