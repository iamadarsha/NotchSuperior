<div align="center">

<a href="https://github.com/iamadarsha/NotchSuperior">
  <img src="banner.svg" alt="NotchSuperior" width="100%">
</a>

<br/>

### Turn your MacBook's notch into a fluid, intelligent command center.

<p>
  <a href="https://github.com/iamadarsha/NotchSuperior/actions/workflows/cicd.yml"><img src="https://github.com/iamadarsha/NotchSuperior/actions/workflows/cicd.yml/badge.svg" alt="Build" /></a>
  <a href="https://github.com/iamadarsha/NotchSuperior/releases/latest"><img src="https://img.shields.io/github/v/release/iamadarsha/NotchSuperior?color=8A7CFF&label=release" alt="Release" /></a>
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000000?logo=apple&logoColor=white" alt="macOS 13+" />
  <img src="https://img.shields.io/badge/Swift-SwiftUI-FA7343?logo=swift&logoColor=white" alt="Swift" />
  <a href="https://discord.gg/c8JXA7qrPm"><img src="https://img.shields.io/discord/1234567890?color=5865F2&label=Discord&logo=discord&logoColor=white" alt="Discord" /></a>
</p>

<p>
  <a href="#-install">Install</a> ·
  <a href="#-features">Features</a> ·
  <a href="#-keyboard-shortcuts">Shortcuts</a> ·
  <a href="#-build-from-source">Build</a> ·
  <a href="#-extension-sdk">SDK</a>
</p>

</div>

---

**NotchSuperior** transforms the static cutout at the top of your MacBook into a gorgeous, interactive overlay — media controls, a file shelf, clipboard history, voice notes with on-device transcription, live system stats, a camera mirror, and secure local AI chat. All native SwiftUI. No telemetry. No account required.

<br/>

## ⚡ Install

One command — downloads the latest signed build, clears the Gatekeeper quarantine, and launches it:

```bash
curl -fsSL https://raw.githubusercontent.com/iamadarsha/NotchSuperior/main/install.sh | bash
```

<details>
<summary><strong>What does this do?</strong></summary>

<br/>

1. Downloads the latest verified `NotchSuperior.dmg` release.
2. Mounts the disk image.
3. Copies `NotchSuperior.app` into `/Applications` (falls back to `~/Applications`).
4. Removes the `com.apple.quarantine` flag so you skip the "unidentified developer" prompt.
5. Launches the app.

</details>

> Prefer to click? Grab the `.dmg` from the [**latest release**](https://github.com/iamadarsha/NotchSuperior/releases/latest), drag it to Applications, and open.

<br/>

## ✨ Features

| | Feature | What it does |
|:--:|---|---|
| 🎵 | **Now Playing** | Album art, scrubbable timeline, and transport controls for Apple Music, Spotify & more. |
| 📦 | **Dynamic Shelf** | Drag any file, image, or text onto the notch to stash it. Drag back out anywhere. |
| 📋 | **Clipboard Manager** | Searchable history with date grouping, pinned items, and reusable text snippets. |
| 🎙️ | **Voice Notes** | Record and transcribe **on-device** (no API key), then summarize with your own AI provider. |
| 📊 | **System Stats** | Live CPU, RAM, network, disk, and battery — with sparklines, in one glance. |
| 📷 | **Camera Mirror** | Quick front-camera preview with one-tap snapshot to your Desktop. |
| 🧠 | **Local AI Chat** | Talk to OpenAI, Claude, or Gemini. Keys live in your macOS Keychain — never leave your Mac. |
| 🌈 | **Siri Glow** | A breathing, multi-layer aurora border when the notch expands. |
| 📅 | **Calendar & Reminders** | Upcoming events and checkable iCloud reminders via EventKit. |
| 💻 | **Developer HUD** | Git branch, Docker containers, and network latency at a glance. |
| ⌨️ | **Command Launcher** | A fast keyboard-driven launcher right from the notch. |
| 🔔 | **Live Activities** | Weather, downloads, battery, AirDrop, focus timers — surfaced in the closed notch. |

<br/>

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>I</kbd> | Toggle the notch open / closed |
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>V</kbd> | Open the Clipboard manager |
| <kbd>⌘</kbd> <kbd>⇧</kbd> <kbd>A</kbd> | Open AI Chat |
| <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>~</kbd> | Drop down the developer terminal |
| <kbd>⌘</kbd> <kbd>1</kbd> … <kbd>9</kbd> | Copy clipboard item _n_ |

> Shortcuts are fully rebindable in **Settings → Shortcuts**.

<br/>

## 🛠️ Tips & Setup

<details>
<summary><strong>🎙️ On-device voice notes & AI summaries</strong></summary>

<br/>

1. Tap the **Notes** tab and hit record — speech is transcribed locally via Apple's Speech framework, no key required.
2. To summarize, open **Settings → AI**, pick a provider (OpenAI / Claude / Gemini), and paste your key. It's stored in the System Keychain (`kSecAttrAccessibleWhenUnlocked`) and never transmitted anywhere but the provider you choose.

</details>

<details>
<summary><strong>💻 Drop-down developer terminal</strong></summary>

<br/>

Press <kbd>⌃</kbd> <kbd>⌥</kbd> <kbd>~</kbd> for a Guake-style zsh terminal from the notch. It respects your shell environment and dismisses on click-away or <kbd>Esc</kbd>.

</details>

<details>
<summary><strong>📦 Camera snapshots</strong></summary>

<br/>

Open the **Camera** tab for a mirrored preview, then tap the shutter to save a timestamped PNG straight to your Desktop.

</details>

<br/>

## 🔌 Extension SDK

Other macOS apps can push custom Live Activities to the notch via the public `NSExtensionSDK` Swift package:

```swift
import NSExtensionSDK

let request = NSLiveActivityRequest(
    title: "Uploading Assets",
    subtitle: "24 of 100 files completed",
    progress: 0.24,
    systemImageName: "arrow.up.circle.fill",
    customIconColor: "green",
    actionLabel: "Cancel",
    actionNotificationName: "com.myapp.upload.cancel"
)

NSLiveActivityClient.shared.post(request: request)

let observer = NSLiveActivityClient.shared.observeAction(for: "com.myapp.upload.cancel") {
    print("User canceled the upload from the Notch!")
}
```

<br/>

## 🏗️ Build from Source

**Requirements:** macOS 13.0+ and Xcode 16+.

```bash
git clone https://github.com/iamadarsha/NotchSuperior.git
cd NotchSuperior
open boringNotch.xcodeproj
```

Then press <kbd>⌘</kbd> <kbd>R</kbd> to build and run.

<br/>

## 🤝 Contributing

Pull requests and ideas are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## 🌟 Credits

- [**MediaRemoteAdapter**](https://github.com/ungive/mediaremote-adapter) — powers the macOS Now Playing source.
- [**NotchDrop**](https://github.com/Lakr233/NotchDrop) — foundational concept for the drag-and-drop shelf.
- Built on the open-source [**boring.notch**](https://github.com/TheBoredTeam/boring.notch) project.
- Created and maintained by [**@iamadarsha**](https://instagram.com/iamadarsha).

<br/>

<div align="center">

If NotchSuperior makes your Mac better, please **star the repo** ⭐

</div>
