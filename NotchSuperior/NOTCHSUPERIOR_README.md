# NotchSuperior

NotchSuperior is a powerful, production-grade fork of `boring.notch` that enhances the macOS notch with advanced tools, layout presets, secure AI capabilities, and high-performance developer features. It builds on the core project to transform the camera notch into a fluid, responsive command center.

## Core Phases & Enhancements

1. **Phase 1: HUD Engine & Apple Liquid Glass** — Replaces system volume and brightness displays with beautiful, customizable Liquid Glass overlays.
2. **Phase 2: Live Activity Engine** — Displays system notifications (downloads, battery warnings, microphone/camera usage) as animated notifications expanding directly from the notch.
3. **Phase 3: Shelf 2.0** — Introduces multi-stacks, smart contextual actions (compression, sharing, AirDrop shortcuts), and persistent stack storage.
4. **Phase 4: Clipboard & Snippets** — A segmented text/image clipboard history manager with snippet pin support and customized global shortcuts.
5. **Phase 5: Focus & Pomodoro** — Adds Pomodoro session timers integrated with system Focus modes, progress rings, and lofi/white-noise player controls.
6. **Phase 6: AI Chat & Notes** — Introduces local transcription voice memos via the Speech framework, secure Keychain API key storage, and streaming chat using Anthropic/OpenAI/Gemini.
7. **Phase 7: Command Launcher** — A quick-action command bar triggered via global hotkeys to execute shell scripts, Lock Screen, Empty Trash, or AI tasks.
8. **Phase 8: Layout Engine & Settings** — Integrates layout preset grids (Media-First, Productivity, Minimal, Dev HUD) and quick battery/presenter profiles.
9. **Phase 9: Dev / Power-User Tools** — Displays active Git branches, Docker status, network ping latency inside the notch, and introduces a Guake-style drop-down terminal toggled via `⌃`` (Control + backtick).

## Bring-Your-Own-Key (BYOK) AI Setup

AI services are fully bring-your-own-key. Users can securely add their OpenAI, Anthropic Claude, or Google Gemini keys in the API Keys settings panel. All keys are encrypted and stored locally in the macOS Keychain (`SecKeychainItem`), ensuring maximum privacy.

## System Requirements & Build Instructions

* **OS Requirement:** macOS 26+ (Golden Gate) for full Liquid Glass container features. Backwards compatible to macOS 15.4.
* **Xcode Version:** Xcode 26+ with Swift 6 concurrency.

### Build Steps:
1. Clone this repository branch.
2. Open `boringNotch.xcodeproj` in Xcode.
3. Select the `boringNotch` target.
4. Build and run (`Cmd+R` / `Cmd+B`).
