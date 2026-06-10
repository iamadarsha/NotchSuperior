<h1 align="center">
  <br>
  <a href="https://github.com/iamadarsha/NotchSuperior"><img src="https://framerusercontent.com/images/RFK4vs0kn8pRMuOO58JeyoemXA.png?scale-down-to=256" alt="NotchSuperior Logo" width="160"></a>
  <br>
  NotchSuperior
  <br>
</h1>

<p align="center">
  <strong>Transform your MacBook's notch into a fluid, responsive command center.</strong>
</p>

<p align="center">
  <img src="https://github.com/iamadarsha/NotchSuperior/actions/workflows/cicd.yml/badge.svg" alt="Build Status" />
  <a href="https://discord.gg/c8JXA7qrPm">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/c8JXA7qrPm?style=flat" alt="Discord" />
  </a>
  <a href="https://www.ko-fi.com/alexander5015">
    <img src="https://srv-cdn.himpfen.io/badges/kofi/kofi-flat.svg" alt="Support" />
  </a>
</p>

---

Say hello to **NotchSuperior**, a premium, high-performance utility that transforms your MacBook's screen notch from a static cutout into a gorgeous, interactive overlay. 

Built on the foundation of `boring.notch`, NotchSuperior introduces **Apple Intelligence Siri-style glow animations**, secure **local AI chat & voice transcriptions**, **Guake-style developer terminals**, customizable **layout profiles**, and a unified system **HUD replacement**.

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="NotchSuperior Preview Animation" width="600" />
</p>

---

## ⚡ Quick Install

You can download, install, bypass security quarantines, and launch **NotchSuperior** immediately with a **single terminal command**.

Open your Terminal app (`/Applications/Utilities/Terminal.app`) and paste the following:

```bash
curl -fsSL https://raw.githubusercontent.com/iamadarsha/NotchSuperior/feature/notch-superior/install.sh | bash
```

> [!NOTE]
> **What this command does:**
> 1. Downloads the latest verified release build of NotchSuperior.
> 2. Mounts the installation image.
> 3. Installs `NotchSuperior.app` into your `/Applications` folder.
> 4. Automatically clears the macOS gatekeeper quarantine (`xattr`) so you don't have to manually bypass "unidentified developer" warnings.
> 5. Launches the app instantly.

---

## ✨ Key Features

NotchSuperior is packed with features that fit seamlessly into macOS:

### 🌈 Apple Intelligence Siri Glow Border
When expanded, the notch features a multi-layered neon border that breathes, pulses, and rotates organic fluid colors. The gradient uses Siri's cyan, violet, blue, and pink color spectrum to deliver a world-class visual experience.

### 📷 Smart Camera Mirror
A quick-toggle webcam preview. Hover over the camera icon to reveal a mirrored webcam crop inside the notch. Features native permissions verification and custom aspect crops.

### 📅 Calendar & Reminders
A live productivity hub. Scroll through current and upcoming meetings, check off active iCloud reminders, and open your calendar application directly from the notch interface.

### 🎵 Now Playing & Waveform Visualizer
Compatible with Apple Music, Spotify, YouTube Music, and web players. Features customizable playback controls (favorite buttons, volume control, track seek slider) and timeline synchronization.

### 🧠 Secure Local AI & Voice Notes
- **Voice Memos**: Record voice memos directly from the notch.
- **On-Device STT**: Transcribes your voice notes locally using Apple's Speech Framework (no keys required).
- **AI Workspace**: Slide down chat panels using secure Keychain-stored OpenAI, Claude, or Gemini API keys to summarize, rewrite, or debug.

### 💻 Developer HUD & Terminal Drop-Down
- **System Metrics Tile**: Displays active Git branch, Docker container status, and network latency pings.
- **Guake-style Terminal**: Press `Ctrl + Opt + ~` to drop down a zsh terminal directly from the notch for swift CLI checks.

### 📦 Notch Shelf & Drag-and-Drop
Drag any file, folder, image, or text snippet to the top center of your screen to drop it onto the Notch Shelf. Includes AirDrop shortcuts and Quick Look previews.

---

## 🛠️ Configuration & Customization

NotchSuperior features a completely redesigned macOS 15-style preferences panel. 

- **General**: Customize start-on-login, preferred display targets, hover delay, and gesture sensitivity.
- **Appearance**: Adjust theme modifiers (Liquid Glass, Minimal, OLED Black), accent tints, and backing glass opacity.
- **Layout Profiles**: Drag-and-drop to reorder active widget slots or set app-specific layout profiles.

---

## 🏗️ Building from Source

If you prefer to compile NotchSuperior yourself, you can build it with Xcode:

### Prerequisites
- macOS **14 Sonoma** or later
- **Xcode 16** or later

### Build Instructions
1. Clone the repository:
   ```bash
   git clone https://github.com/iamadarsha/NotchSuperior.git
   cd NotchSuperior
   ```
2. Open the project:
   ```bash
   open boringNotch.xcodeproj
   ```
3. Press `Cmd + R` to compile and run the target.

---

## 🤝 Contributing

We welcome community pull requests and feature ideas! Check out our [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## 🌟 Support & Credits
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** — Powering the macOS Now Playing source.
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** — Foundational concept for drag-and-drop shelf mechanics.
- Icon design by [@maxtron95](https://github.com/maxtron95).
- Web design by [@himanshhhhuv](https://github.com/himanshhhhuv).

If you love NotchSuperior, please consider starring the repository or [buying us a coffee on Ko-Fi](https://www.ko-fi.com/alexander5015)!
