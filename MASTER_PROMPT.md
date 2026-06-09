# ═══════════════════════════════════════════════════════════════════
# MASTER BUILD PROMPT — NotchSuperior (boring.notch Fork)
# ═══════════════════════════════════════════════════════════════════
# AI AGENT: You are building "NotchSuperior" — a production-grade
# fork of TheBoredTeam/boring.notch. You will work inside the
# already-downloaded boring.notch repo folder.
#
# ⚠️  CRITICAL: This session may be cut off at ANY moment due to
# context/compute limits. The developer switches between Codex,
# Claude Code, and Antigravity agents. After every major action
# (or ~every 5 minutes of work), you MUST update AGENT_CONTEXT.md
# (see Section 0). This is the single most important habit.
# ═══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────────
# SECTION 0 — CONTEXT HANDOFF SYSTEM (READ THIS FIRST, ALWAYS)
# ─────────────────────────────────────────────────────────────────
#
# You must maintain AGENT_CONTEXT.md in the repo root at all times.
# This file is the "baton" passed between AI agents when limits hit.
# Update it BEFORE and AFTER every significant code change.
#
# AGENT_CONTEXT.md must always contain:
#
#   ## Status
#   - Current Phase: (e.g. "Phase 1 — HUD Theming", "Phase 2 — AI Layer")
#   - Last Completed Task: (specific file + what was done)
#   - Next Task: (exact next step with file path)
#   - Blocked By: (any unresolved issue; "None" if clear)
#   - Build Status: (Compiles ✅ / Fails ❌ / Untested ❓)
#
#   ## File Map (updated as files are created/modified)
#   - List every new or modified file with a one-line description
#
#   ## Architecture Decisions
#   - Key choices made (e.g. "Used NotchSuperiorHUDEngine instead of
#     patching BoringHUDManager to avoid merge conflicts")
#
#   ## Known Issues / TODOs
#   - Anything unfinished or needing review
#
#   ## How to Resume
#   - Step-by-step instructions for the next agent to pick up cleanly
#   - Which branch to be on
#   - How to build: `open boringNotch.xcodeproj` → Cmd+R
#
# UPDATE AGENT_CONTEXT.md after EVERY task, not just at session end.
# If you are ever unsure what to do next, read AGENT_CONTEXT.md first.

# ─────────────────────────────────────────────────────────────────
# SECTION 1 — PROJECT IDENTITY
# ─────────────────────────────────────────────────────────────────
#
# App Name:         NotchSuperior
# Bundle ID:        com.notchsuperior.app
# Base Repo:        https://github.com/TheBoredTeam/boring.notch
# Working Branch:   feature/notch-superior (branch from dev)
# Target OS:        macOS 27 (Golden Gate) — minimum deployment target
#                   macOS 15.4 for backward compat where possible
# Language:         Swift 6, SwiftUI
# Xcode:            Xcode 26+
# Design Language:  Apple Liquid Glass (macOS/iOS 27 standard)
# Architecture:     MVVM + modular feature packages
#
# DO NOT rename or delete any existing boring.notch source files.
# ADD new files alongside existing ones. Mark your additions clearly
# with a header comment: // NOTCHSUPERIOR ADDITION — [FeatureName]

# ─────────────────────────────────────────────────────────────────
# SECTION 2 — IMMEDIATE SETUP (Do this before any feature work)
# ─────────────────────────────────────────────────────────────────
#
# Step 1: Create the working branch
#   git checkout dev
#   git checkout -b feature/notch-superior
#
# Step 2: Create AGENT_CONTEXT.md in the repo root (see Section 0).
#   Initial status: "Phase 0 — Setup Complete, Starting Phase 1"
#
# Step 3: Add a top-level folder: NotchSuperior/
#   All new source files go here. This keeps the fork clean and
#   merge-friendly with upstream boring.notch updates.
#
# Step 4: Update the Xcode project to include NotchSuperior/ group.
#
# Step 5: Verify the base app still compiles cleanly before adding
#   any new code. If it fails, fix build errors first. Document in
#   AGENT_CONTEXT.md under "Known Issues".
#
# Step 6: Update Info.plist:
#   CFBundleName → NotchSuperior
#   CFBundleDisplayName → NotchSuperior
#   NSHumanReadableCopyright → NotchSuperior — Built on boring.notch

# ─────────────────────────────────────────────────────────────────
# SECTION 3 — DESIGN SYSTEM (Liquid Glass / macOS 27)
# ─────────────────────────────────────────────────────────────────
#
# All UI must use Apple's Liquid Glass design language introduced in
# iOS/macOS 26 and refined in macOS 27 Golden Gate.
#
# Core SwiftUI APIs to use throughout:
#
#   .glassEffect()                     — primary surface material
#   GlassEffectContainer { }           — groups related glass elements
#   .glassEffectID("id", in: ns)       — coordinates glass transitions
#   .contentTransition(.symbolEffect(.replace))  — icon transitions
#   .background(.ultraThinMaterial)    — fallback for older targets
#   .background(.regularMaterial)      — modal/sheet surfaces
#
# Design tokens — define in NotchSuperior/DesignSystem/NSTokens.swift:
#
#   static let notchCornerRadius: CGFloat = 12          // pill shape
#   static let notchExpandedRadius: CGFloat = 20        // expanded
#   static let glassBlur: CGFloat = 20                  // backdrop
#   static let glassOpacity: Double = 0.12              // tint alpha
#   static let animationSpring = Animation.spring(      // all motion
#       response: 0.38, dampingFraction: 0.72)
#   static let subtleSpring = Animation.spring(
#       response: 0.25, dampingFraction: 0.85)
#
# Color palette (Liquid Glass aware):
#   - Primary surfaces: .ultraThinMaterial over wallpaper bleed-through
#   - Accent: System accent color (user-configurable in Settings)
#   - Text: .primary / .secondary / .tertiary — never hardcoded
#   - Never use flat opaque backgrounds on notch surfaces
#
# Typography (macOS 27 HIG):
#   - Notch collapsed: .caption2 (10pt) — SF Pro Rounded
#   - Notch expanded labels: .caption (12pt) — SF Pro
#   - Widget titles: .headline — SF Pro Display
#   - HUD values: .largeTitle.monospacedDigit()
#   - All text uses .foregroundStyle(.primary) over glass
#
# Motion rules:
#   - All expand/collapse: spring animation (NSTokens.animationSpring)
#   - HUD appear/dismiss: .easeOut(duration: 0.18)
#   - Never use linear animations for notch surfaces
#   - Live activity transitions: matchedGeometryEffect
#   - Respect: @Environment(\.accessibilityReduceMotion)

# ─────────────────────────────────────────────────────────────────
# SECTION 4 — FEATURE PHASES (Build in order. Update AGENT_CONTEXT
# after each phase and each sub-task within a phase.)
# ─────────────────────────────────────────────────────────────────

# ── PHASE 1: HUD Engine + Design System Foundation ──────────────
#
# Goal: Replace and supercharge the existing HUD replacement system
# with a fully Liquid Glass themed, multi-theme HUD engine.
#
# Files to create:
#   NotchSuperior/HUD/NSHUDEngine.swift
#   NotchSuperior/HUD/NSHUDTheme.swift
#   NotchSuperior/HUD/NSHUDOverlayView.swift
#   NotchSuperior/DesignSystem/NSTokens.swift
#   NotchSuperior/DesignSystem/NSGlassModifiers.swift
#
# Tasks:
# 1.1  Create NSHUDTheme enum with cases:
#        .liquidGlass (default — Liquid Glass material)
#        .minimal (compact, no blur, 1-line)
#        .oledBlack (pure black, ultra contrast)
#        .iOSStyle (rounded pill, bottom-anchored)
#      Store selected theme in UserDefaults key "NSHUDTheme"
#
# 1.2  Build NSHUDEngine as an ObservableObject singleton that:
#        - Intercepts system volume/brightness/keyboard events
#          (use the same CGEventTap approach as existing BoringHUDManager
#           but wrap it in a new class — do not modify existing class)
#        - Publishes @Published var activeHUD: NSHUDEvent?
#        - Supports combined HUD (e.g., "Now Playing + Volume" in
#          one surface) — publish NSHUDEvent as enum with associated
#          values: .volume(Float), .brightness(Float),
#          .keyboardBacklight(Float), .combined([NSHUDEvent])
#        - Auto-dismisses after 2.4 seconds (configurable)
#
# 1.3  Build NSHUDOverlayView using SwiftUI:
#        - Reads from NSHUDEngine
#        - Renders using GlassEffectContainer + .glassEffect()
#        - Animates in/out with matchedGeometryEffect
#        - Shows a progress bar (thin, 2pt, accent colored) below icon
#        - Shows combined HUD as stacked glass pills
#        - Respects reduceMotion accessibility setting
#
# 1.4  Build NSGlassModifiers.swift with reusable ViewModifiers:
#        .notchGlass()       — standard notch surface
#        .hudGlass()         — HUD pill surface
#        .shelfGlass()       — shelf item surface
#        .widgetGlass()      — widget tile surface
#      Each applies appropriate .glassEffect() + corner radius +
#      shadow from NSTokens
#
# ── PHASE 2: Live Activity Engine ───────────────────────────────
#
# Goal: Unified live activity system that shows system events as
# Dynamic Island-style animations expanding from the notch.
#
# Files to create:
#   NotchSuperior/LiveActivity/NSLiveActivityEngine.swift
#   NotchSuperior/LiveActivity/NSLiveActivityView.swift
#   NotchSuperior/LiveActivity/Activities/ (subfolder)
#     → NSMediaActivity.swift
#     → NSTimerActivity.swift
#     → NSDownloadActivity.swift
#     → NSAirDropActivity.swift
#     → NSBluetoothActivity.swift
#     → NSBatteryActivity.swift
#     → NSScreenRecordActivity.swift
#     → NSPrivacyDotActivity.swift (mic/camera in use)
#
# Tasks:
# 2.1  NSLiveActivityEngine is an ObservableObject that:
#        - Maintains a priority queue of active activities
#        - Only one activity shows at a time (highest priority wins)
#        - Activity priority order (descending):
#            1. Privacy dot (mic/camera in use) — always on top
#            2. Screen recording in progress
#            3. Active timer / Pomodoro
#            4. Download in progress
#            5. Bluetooth connect/disconnect
#            6. AirDrop transfer
#            7. Battery critical
#            8. Media now playing
#        - Exposes @Published var currentActivity: any NSActivity?
#
# 2.2  NSLiveActivityView:
#        - Wraps existing boring.notch notch expansion view
#        - When an activity is active, shows its compact view inside
#          the notch using matchedGeometryEffect for expansion
#        - Gesture: tap = expand to full activity detail
#                   swipe left = dismiss
#                   swipe right = next activity
#
# 2.3  Each Activity file implements protocol NSActivity:
#        var id: UUID
#        var priority: Int
#        var compactView: AnyView      // fits inside collapsed notch
#        var expandedView: AnyView     // shown when tapped/expanded
#        var ttl: TimeInterval?        // nil = persistent
#
# 2.4  Wire NSPrivacyDotActivity to IOKit / TCC events to detect
#        microphone and camera use (mirror macOS privacy indicator logic)
#
# ── PHASE 3: Shelf 2.0 ──────────────────────────────────────────
#
# Goal: Upgrade the existing shelf with multi-stacks, smart actions,
# and better AirDrop workflow.
#
# Files to create (do NOT modify existing Shelf files, add new ones):
#   NotchSuperior/Shelf/NSShelfEngine.swift
#   NotchSuperior/Shelf/NSShelfView.swift
#   NotchSuperior/Shelf/NSShelfStack.swift
#   NotchSuperior/Shelf/NSShelfItemActionsMenu.swift
#
# Tasks:
# 3.1  NSShelfStack model:
#        - name: String (e.g. "Today", "Share Later", "Inbox")
#        - items: [NSShelfItem]
#        - expiryPolicy: enum (.never, .onReboot, .after(TimeInterval))
#        - showBadge: Bool (count + time remaining badge on notch)
#
# 3.2  NSShelfEngine manages multiple stacks. Default stacks:
#        "Inbox" (1-day expiry), "Share Later" (reboot expiry),
#        "Pinned" (never expires). User can add custom stacks.
#        Persists via Codable to ~/Library/Application Support/NotchSuperior/
#
# 3.3  NSShelfView:
#        - Horizontally scrollable row of stacks (tabs at top)
#        - Each stack shows items as rounded glass thumbnails
#        - Drag from Finder into notch → drops to active stack
#        - Right-click item → NSShelfItemActionsMenu
#
# 3.4  NSShelfItemActionsMenu actions (using SwiftUI Menu):
#        Quick Look, Copy, Compress, Share Sheet,
#        "Send via AirDrop to last device",
#        "Open With…" (shows default + user-fav apps),
#        "Move to Stack…" (submenu of stacks),
#        Remove
#
# ── PHASE 4: Clipboard & Snippets ───────────────────────────────
#
# Files:
#   NotchSuperior/Clipboard/NSClipboardEngine.swift
#   NotchSuperior/Clipboard/NSClipboardView.swift
#   NotchSuperior/Clipboard/NSSnippetStore.swift
#
# Tasks:
# 4.1  NSClipboardEngine:
#        - Monitors NSPasteboard with 0.5s polling
#        - Stores last 30 items in-memory (no persistence = privacy)
#        - Filters: text, URLs, images
#        - Deduplicates consecutive identical copies
#
# 4.2  NSClipboardView:
#        - Swipe down from notch (or keyboard shortcut) to open
#        - Shows items as compact glass pills in a vertical list
#        - Click to paste immediately
#        - Long press → pin as Snippet
#
# 4.3  NSSnippetStore:
#        - Persists pinned snippets to disk (Codable + JSON)
#        - User assigns hotkey to any snippet (format: ⌃⌥ + key)
#        - Snippets accessible from notch widget tile
#
# ── PHASE 5: Focus & Pomodoro Engine ────────────────────────────
#
# Files:
#   NotchSuperior/Focus/NSFocusEngine.swift
#   NotchSuperior/Focus/NSFocusTimerView.swift
#   NotchSuperior/Focus/NSFocusProfileStore.swift
#
# Tasks:
# 5.1  NSFocusEngine:
#        - Pomodoro timer: configurable work/break intervals
#        - Integrates with macOS Focus modes via EventKit
#        - Publishes live activity to NSLiveActivityEngine (priority 3)
#        - Optional: ambient music toggle (play lofi/white noise from
#          bundled URLs or system Music app playlist)
#
# 5.2  NSFocusProfileStore:
#        - Profiles: "Deep Work", "Writing", "Code Review", "Custom"
#        - Each profile has: timer settings, which widgets show,
#          which live activities are visible, HUD theme override
#
# 5.3  NSFocusTimerView:
#        - Compact: ring progress + time remaining inside notch
#        - Expanded: session title, breaks left, music toggle,
#          end session button
#
# ── PHASE 6: AI Layer ────────────────────────────────────────────
#
# Files:
#   NotchSuperior/AI/NSAIEngine.swift
#   NotchSuperior/AI/NSAIChatView.swift
#   NotchSuperior/AI/NSAINoteView.swift
#   NotchSuperior/AI/NSAICommandPalette.swift
#   NotchSuperior/AI/NSAIProviderSettings.swift
#
# Tasks:
# 6.1  NSAIEngine:
#        - Supports multiple providers via pluggable protocol NSAIProvider:
#            → OpenAI (GPT-4o)
#            → Anthropic Claude
#            → Google Gemini
#        - API keys stored in macOS Keychain (SecKeychainItem)
#        - Streaming responses via URLSession async/await
#        - Context injection: can read selected text via Accessibility API
#          (NSAccessibility) or current window title
#
# 6.2  NSAIChatView:
#        - Slides down from notch as glass panel (max 320pt tall)
#        - Input field at bottom, response streamed above
#        - "Context" button auto-injects selected text
#        - Provider selector (3 icons at top right)
#        - History: last 5 messages in session (in-memory only)
#
# 6.3  NSAICommandPalette:
#        - Global shortcut: ⌃⌥Space opens command bar in notch
#        - Built-in commands:
#            /summarize   — summarize selected text
#            /rewrite     — rewrite selected text
#            /translate   — translate (auto-detect → English or ↔)
#            /explain     — explain selected code/text
#            /todo        — extract action items from selected text
#            /email       — draft email reply from selected thread
#        - Each command runs inline; result shown as glass card
#        - "Insert" button pastes result at cursor
#
# 6.4  NSAINoteView:
#        - Press notch + hold 1s → voice memo recording starts
#        - Uses macOS Speech framework (local, on-device, no API key)
#          for transcription, then NSAIEngine for summarization
#        - Note appears as glass card, user can:
#            "Add to Reminders", "Copy", "Send to Obsidian"
#            (Obsidian via URL scheme: obsidian://new?content=...)
#
# 6.5  NSAIProviderSettings:
#        - Settings panel showing provider tiles
#        - Key input with show/hide toggle
#        - Connection test button (fires a test prompt)
#        - Active model selector (e.g., gpt-4o vs gpt-4o-mini)
#
# ── PHASE 7: Developer HUD & Terminal Drop-Down ─────────────────
#
# Files:
#   NotchSuperior/DevTools/NSDevHUDView.swift
#   NotchSuperior/DevTools/NSDevTerminalView.swift
#   NotchSuperior/DevTools/NSDevStatusTile.swift
#
# Tasks:
# 7.1  NSDevHUDView (hidden by default, toggleable in Settings):
#        Status tiles showing:
#        - Git branch + dirty state (shell out to `git status --short`)
#        - Active Docker/Colima containers (shell out to `docker ps`)
#        - Last npm/yarn test result (reads ~/.notchsuperior/test_status)
#        - Network latency to configured host (ping)
#        - CPU / RAM / GPU usage (using existing boring.notch stats)
#
# 7.2  NSDevTerminalView:
#        - ⌃⌥` opens a Guake-style terminal inside expanded notch
#        - Uses macOS PTY via Foundation Process + FileHandle
#        - Configurable shell (zsh by default, reads $SHELL)
#        - Max 8 lines visible; scrollable horizontally
#        - Glass background with monospace font (SF Mono 12pt)
#        - Dismiss: same shortcut or Escape
#
# 7.3  NSDevStatusTile:
#        - SwiftUI view that fits in a notch widget slot
#        - Shows compact: branch name + container count
#        - Tap expands NSDevHUDView
#
# ── PHASE 8: Layout Engine & Settings UI ────────────────────────
#
# Files:
#   NotchSuperior/Layout/NSLayoutEngine.swift
#   NotchSuperior/Layout/NSWidgetSlot.swift
#   NotchSuperior/Layout/NSLayoutPreset.swift
#   NotchSuperior/Settings/NSSettingsView.swift
#   NotchSuperior/Settings/Sections/ (subfolder with one file per section)
#
# Tasks:
# 8.1  NSLayoutEngine:
#        - Defines the notch as a grid of "slots" (left / center / right
#          in both collapsed and expanded states)
#        - Each slot holds an NSWidgetSlot (any SwiftUI view)
#        - Persists layout config as JSON
#        - Supports per-Space layouts: reads NSScreen.main + CGWindowListCopyWindowInfo
#          to identify active Space, switches layout profile
#
# 8.2  NSLayoutPreset enum:
#        .mediaFirst       (visualizer center, calendar right, stats left)
#        .productivity     (focus timer center, shelf right, calendar left)
#        .minimal          (clock center only)
#        .devHUD           (git tile left, network right, CPU center)
#        .custom           (user-arranged)
#
# 8.3  NSSettingsView (replace existing settings panel):
#        Use macOS 27 Settings-style sidebar + content area
#        Sections (one file each):
#          - General (startup, menu bar icon, default layout)
#          - Appearance (HUD theme, Liquid Glass opacity, accent color)
#          - Layout (drag-reorder widget slots, per-Space toggles)
#          - AI (provider keys, default model, command shortcut)
#          - Shelf (stacks config, expiry policies, AirDrop last device)
#          - Focus (Pomodoro intervals, profiles, ambient music)
#          - Developer (enable dev HUD, terminal shell, status tile config)
#          - Keyboard Shortcuts (global shortcut map, customizable)
#          - About (version, changelog, credits, update check)
#        Style: Use .formStyle(.grouped) with glass section backgrounds
#
# ── PHASE 9: Extension System (Skeleton) ────────────────────────
#
# Files:
#   NotchSuperior/Extensions/NSExtensionProtocol.swift
#   NotchSuperior/Extensions/NSExtensionHost.swift
#   NotchSuperior/Extensions/NSBuiltinExtensions.swift
#
# Tasks:
# 9.1  Define NSExtensionProtocol as a Swift protocol that any
#        future extension must implement. Properties needed:
#          var id: String            // reverse DNS
#          var displayName: String
#          var widgetView: AnyView   // compact notch slot view
#          var settingsView: AnyView // settings panel section
#          func activate()
#          func deactivate()
#
# 9.2  NSExtensionHost manages loaded extensions (start with built-ins
#        only; dynamic loading is future work):
#        - Registers extensions
#        - Sandboxes execution via Swift concurrency actors
#        - Exposes to NSLayoutEngine as widget slot providers
#
# 9.3  Register Phase 4 (Clipboard), Phase 5 (Focus), Phase 6 (AI),
#        and Phase 7 (Dev Tools) as NSExtension conforming built-ins

# ─────────────────────────────────────────────────────────────────
# SECTION 5 — WIRING (After all phases, connect to existing app)
# ─────────────────────────────────────────────────────────────────
#
# 5a. In AppDelegate or the existing boringNotchApp.swift entry point,
#     add the following after the existing window setup:
#
#       // NOTCHSUPERIOR ADDITION — Main engine bootstrap
#       NSuperiorBootstrap.shared.start()
#
#     Create NotchSuperior/Core/NSuperiorBootstrap.swift that:
#       - Initializes NSHUDEngine, NSLiveActivityEngine, NSShelfEngine,
#         NSClipboardEngine, NSFocusEngine, NSAIEngine, NSLayoutEngine
#       - Injects them as @EnvironmentObject into the root SwiftUI view
#       - Starts any background pollers (clipboard, dev status)
#
# 5b. Overlay the existing NotchContentView with NSLayoutEngine's
#     active layout. Use ZStack: existing content underneath,
#     NSLayoutEngine overlay on top. This preserves all original
#     boring.notch behavior as a fallback layer.
#
# 5c. Wire NSHUDEngine to intercept BEFORE the existing HUD system
#     fires, by wrapping the existing CGEventTap in a priority check:
#       if NSHUDEngine.shared.isEnabled { return /* consume event */ }
#       // else fall through to original handler
#
# ─────────────────────────────────────────────────────────────────
# SECTION 6 — BUILD VERIFICATION CHECKLIST
# ─────────────────────────────────────────────────────────────────
#
# After each phase, verify:
# [ ] Project builds with 0 errors, 0 warnings (or document why)
# [ ] Existing boring.notch features still work (music, HUDs, shelf,
#     calendar, mirror, reminders, charging indicator)
# [ ] New feature works on macOS 27 simulator and/or real device
# [ ] No force unwraps (!), use guard let / if let
# [ ] All new classes/structs have // MARK: sections
# [ ] AGENT_CONTEXT.md updated with phase completion status
# [ ] Commit with message: "feat(notch-superior): Phase N — <name>"
#     e.g. "feat(notch-superior): Phase 1 — HUD Engine + Liquid Glass"
#
# ─────────────────────────────────────────────────────────────────
# SECTION 7 — AGENT SWITCH PROTOCOL
# ─────────────────────────────────────────────────────────────────
#
# When you (the AI agent) are about to hit a limit OR at the end of
# any task block, perform this handoff routine:
#
# HANDOFF ROUTINE:
# 1. Finish the current ATOMIC task (don't stop mid-function)
# 2. Ensure the project compiles (fix any errors first)
# 3. Run: git add -A && git commit -m "wip: agent handoff — <task>"
# 4. Update AGENT_CONTEXT.md (all fields in Section 0)
# 5. Run: git add AGENT_CONTEXT.md && git commit -m "docs: update agent context"
# 6. Print to console (or your output):
#      "HANDOFF READY — Next agent: read AGENT_CONTEXT.md first"
#      "Current Phase: X | Next Task: Y | Build: ✅/❌"
#
# When you (the next AI agent) are starting a session:
# 1. Read AGENT_CONTEXT.md BEFORE writing any code
# 2. Run `git log --oneline -10` to see recent work
# 3. Try to build: `xcodebuild -scheme boringNotch -quiet build`
# 4. Fix any build errors before adding new code
# 5. Continue from "Next Task" in AGENT_CONTEXT.md
#
# ─────────────────────────────────────────────────────────────────
# SECTION 8 — CODING STANDARDS
# ─────────────────────────────────────────────────────────────────
#
# - Swift 6 strict concurrency: use @MainActor on all SwiftUI views
# - No DispatchQueue.main.async — use Task { @MainActor in ... }
# - Prefer async/await over callbacks for all async operations
# - All UserDefaults keys defined in NSDefaultsKeys enum (one file)
# - All string literals that are user-visible must use NSLocalizedString
# - File header template for every new file:
#
#   // ────────────────────────────────────────────────────────
#   // NotchSuperior — [FileName].swift
#   // Part of the boring.notch fork by [your name]
#   // Phase: [N] — [Phase Name]
#   // Created: [Date]
#   // NOTCHSUPERIOR ADDITION
#   // ────────────────────────────────────────────────────────
#
# ─────────────────────────────────────────────────────────────────
# SECTION 9 — STARTING COMMAND FOR CODEX
# ─────────────────────────────────────────────────────────────────
#
# Codex: begin by executing SECTION 2 (setup) completely, then
# proceed to PHASE 1. Do not skip setup. Update AGENT_CONTEXT.md
# after EVERY sub-task (1.1, 1.2, 1.3, 1.4), not just after the
# full phase. Commit after each sub-task with a descriptive message.
#
# If you are Claude Code reading this for the first time:
#   → Read AGENT_CONTEXT.md first
#   → Check git log for last commit
#   → Build the project
#   → Continue from "Next Task"
#
# If you are Antigravity reading this for the first time:
#   → Same as above. AGENT_CONTEXT.md is your source of truth.
#   → This MASTER_PROMPT.md is in the repo root for reference.
#
# ─────────────────────────────────────────────────────────────────
# END OF MASTER PROMPT
# ─────────────────────────────────────────────────────────────────