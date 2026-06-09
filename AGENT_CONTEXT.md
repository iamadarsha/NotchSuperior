# AGENT_CONTEXT

## Status
- Current Phase: Phase 1 - HUD Engine and Design System Foundation
- Last Completed Task: Added the NotchSuperior HUD/design-system foundation, integrated the overlay into `boringNotch/ContentView.swift`, and registered the new files in `boringNotch.xcodeproj/project.pbxproj`.
- Next Task: Open the project in full Xcode, fix any compile-time API issues if they appear, then add Phase 1 settings/UI controls for `NSHUDTheme` selection and HUD behavior tuning.
- Blocked By: `xcodebuild` is unavailable because the active developer directory points to Command Line Tools instead of a full Xcode install.
- Build Status: Untested ❓

## File Map
- `AGENT_CONTEXT.md` - Cross-agent handoff status and working notes.
- `NotchSuperior/DesignSystem/NSTokens.swift` - Shared design tokens for the new NotchSuperior surfaces and animations.
- `NotchSuperior/DesignSystem/NSGlassModifiers.swift` - Reusable glass/material surface modifiers for notch, HUD, shelf, and widget surfaces.
- `NotchSuperior/HUD/NSHUDTheme.swift` - Theme enum with `UserDefaults` persistence under `NSHUDTheme`.
- `NotchSuperior/HUD/NSHUDEngine.swift` - Observable HUD engine that listens to existing managers and publishes themed HUD events with auto-dismiss behavior.
- `NotchSuperior/HUD/NSHUDOverlayView.swift` - SwiftUI overlay that renders single or combined HUD cards with theme-aware styling.
- `boringNotch/ContentView.swift` - Mounted the new NotchSuperior HUD overlay on top of the existing notch UI.
- `boringNotch.xcodeproj/project.pbxproj` - Added the `NotchSuperior` group/files to the app target and updated bundle/display identity settings for NotchSuperior.

## Architecture Decisions
- The new NotchSuperior layer will be added in a parallel top-level `NotchSuperior/` folder to keep upstream merge paths clean.
- Existing boring.notch HUD and media-key code will be treated as the event seam; new HUD logic will observe and extend it rather than replace large portions of the original code in place.
- The first pass uses the existing `VolumeManager`, `BrightnessManager`, `KeyboardBacklightManager`, and `MusicManager` publishers as the authoritative live signal source, while still ensuring the existing media-key interceptor is active when HUD replacement is enabled.

## Known Issues / TODOs
- The checkout is not currently a git repository, so branch creation from the prompt cannot be executed here.
- Full compile validation cannot run until the machine is switched to a full Xcode developer directory.
- The current implementation is a Phase 1 foundation pass; there is not yet a settings surface for selecting `NSHUDTheme`, and later phases from `MASTER_PROMPT.md` are still pending.

## How to Resume
1. Stay in `/Users/iamadarsha/Downloads/boring.notch-main`.
2. Read this file first, then open `/Users/iamadarsha/Downloads/boring.notch-main/MASTER_PROMPT.md` only if you need the broader staged roadmap.
3. When a full Xcode install is available, run `open boringNotch.xcodeproj` and build the `boringNotch` target.
4. If the build surfaces SwiftUI/API issues, start with the new files in `NotchSuperior/HUD/` and `NotchSuperior/DesignSystem/`.
5. After compile validation, continue with Phase 1 polishing or move to Phase 2 live activities depending on priority.
6. Intended branch from prompt: `feature/notch-superior` off `dev` once this checkout is backed by git.
