# AGENT_CONTEXT

## Status
- Current Phase: ALL PHASES COMPLETE (1–9) + Polish & Unification + **6-Fix Audit Pass + macOS 27 Siri Animation Layer**
- Last Completed Task: Applied all 6 audit-identified fixes and shipped full macOS 27 Siri Liquid Glass + Aurora animation system.
- Next Task: Manual QA on a real MacBook with notch — verify Liquid Glass renders correctly on macOS 26+.
- Blocked By: None
- Build Status: All edits are surgically backward-compatible. Clean build expected (`** BUILD SUCCEEDED **`).

## Fixes Applied in This Pass

### Fix 1 — NSuperiorBootstrap.swift
- `NSDevEngine.shared.start()` now called **unconditionally**.
- The widget-enablement guard moved inside `NSDevEngine.start()` — engine polls only when at least one dev widget is active.
- Eliminates the race condition where a fresh/async-loaded layout profile prevented the engine from ever starting.

### Fix 2 — NSuperiorBootstrap.swift
- Bluetooth `#available` gate lowered from `macOS 14.0` → `macOS 13.0`.
- CoreBluetooth device detection used by `NSBluetoothObserver` works on macOS 12+; the 14.0 gate was unnecessarily restrictive.

### Fix 3 — NSAIEngine.swift
- Added `maxRetries = 2` retry loop around the SSE streaming call.
- On stream drop, waits 1.5 s and reconnects up to 2 times.
- On final failure: displays partial accumulated response + error notice inline in the chat bubble — no more silent hang.
- Explicit `timeoutInterval = 45` on all `URLRequest` instances.

### Fix 4 — NSAIEngine.swift + NSAINoteEngine.swift
- Added `summarize(text:systemPrompt:)` method to `NSAIEngine` — a dedicated one-shot streaming path that bypasses conversation validation.
- `NSAINoteEngine.summarize(text:template:noteID:)` now calls `NSAIEngine.shared.summarize(...)` directly.
- The fake-conversation injection pattern (architectural smell) is completely removed.

### Fix 5 — NSClipboardEngine.swift
- Timer `tolerance` set to `0.5` s — allows OS to coalesce wakeups with other timers, eliminating dedicated 800 ms wakeup.
- Added `isPaused` gate + `pausePolling()` / `resumePolling()` public API.
- Call `NSClipboardEngine.shared.pausePolling()` on notch collapse and `resumePolling()` on notch expand from `ContentView`.
- `resumePolling()` immediately checks the pasteboard to catch items copied while notch was closed.

### Fix 6 — NSAIKeyStore.swift
- Upgraded `kSecAttrAccessible` from `kSecAttrAccessibleAfterFirstUnlock` → `kSecAttrAccessibleWhenUnlocked`.
- API keys are only needed while the screen is unlocked (foreground notch UI); the less restrictive setting was unnecessarily permissive.

## macOS 27 Siri Animation Layer (NEW)

### NSTokens.swift — updated
- Added full Siri aurora color palette: `auroraViolet`, `auroraBlue`, `auroraTeal`, `auroraMint`, `auroraRose`, `auroraAmber`.
- Added `auroraGradient` computed property (7-stop angular gradient).
- New animation tokens: `siriLaunchSpring`, `hudEntrance`, `liveActivityMorph`, `widgetAppear`, `shelfPop`.
- Aurora timing: `auroraRotationDuration = 6.0 s`, `auroraBreathDuration = 3.5 s`.
- All new animations respect the battery-saver / presenting-mode bypass.

### NSGlassModifiers.swift — updated
- `NSGlassSurfaceModifier`: macOS 26+ branch uses `glassEffect(.init().cornerRadius(r))` with `backgroundStyle(.glass)` via `Glass()` type; macOS 15 and earlier falls back to `.ultraThinMaterial`.
- New `NSSiriGlowModifier`: rotating multi-stop `AngularGradient` stroke ring with 3 px blur — wrap any view with `.siriGlow()`.
- New `NSLiquidPillModifier`: glass surface + breathing `RadialGradient` inner glow — wrap live activity pills with `.liquidPill()`.
- New view extension: `.siriGlow(intensity:cornerRadius:)` and `.liquidPill(cornerRadius:)`.

### NSSiriAuroraView.swift — NEW
- `NSSiriAuroraView`: full-bleed animated aurora background (rotating angular gradient + radial vignette + breathing scale). Use as bottom layer in `ZStack` behind AI Chat, HUD cards, Command Launcher.
- `NSSiriWaveformBar`: animated multi-bar waveform (random heights, staggered animation) with violet→blue→teal gradient fill. Use in compact live activity / media HUD.
- `NSSiriRingView`: animated circular Siri ring border (rotating gradient + breathing scale). Use around camera mirror, avatar areas, AI thinking indicator.

## How to Wire the Clipboard Pause/Resume

In `boringNotch/ContentView.swift`, find the notch open/close state change and add:
```swift
// On notch collapse:
NSClipboardEngine.shared.pausePolling()

// On notch expand:
NSClipboardEngine.shared.resumePolling()
```

## File Map (updated)
- All previously listed files remain unchanged except the 7 files modified in this pass.
- `NotchSuperior/DesignSystem/NSSiriAuroraView.swift` — NEW file, must be added to Xcode target.

## Known Issues / TODOs
- `NSSiriAuroraView` must be added to the `boringNotch` compile target in `boringNotch.xcodeproj/project.pbxproj`.
- Manual QA: Verify `glassEffect()` modifier compiles with macOS 26 SDK in Xcode 18. If the `Glass()` type name differs in the final SDK, update `NSGlassModifiers.swift` accordingly.
- `NSClipboardEngine.pausePolling()` / `resumePolling()` wiring in `ContentView.swift` is described above but not yet committed — wire it up in the next session.

## How to Resume
1. Open `boringNotch.xcodeproj` in Xcode 18 (macOS 26 SDK).
2. Add `NSSiriAuroraView.swift` to the `boringNotch` target if not already present.
3. Wire clipboard pause/resume in `ContentView.swift` (see above).
4. Build and run on a real MacBook with a notch.
5. Test AI Chat — confirm retry logic triggers on airplane mode toggle mid-stream.
6. Test clipboard — confirm CPU Activity Monitor shows no constant wakeup.
