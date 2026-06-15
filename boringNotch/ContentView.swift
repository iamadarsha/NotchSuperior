//
//  ContentView.swift
//  boringNotchApp
//
//  Created by Harsh Vardhan Goswami  on 02/08/24
//  Modified by Richard Kunkli on 24/08/2024.
//

import AVFoundation
import Combine
import Defaults
import KeyboardShortcuts
import SwiftUI
import SwiftUIIntrospect

@MainActor
struct ContentView: View {
    @EnvironmentObject var vm: BoringViewModel
    @ObservedObject var webcamManager = WebcamManager.shared

    @ObservedObject var coordinator = BoringViewCoordinator.shared
    @ObservedObject var musicManager = MusicManager.shared
    @ObservedObject var batteryModel = BatteryStatusViewModel.shared
    @ObservedObject var brightnessManager = BrightnessManager.shared
    @ObservedObject var volumeManager = VolumeManager.shared
    @ObservedObject private var notchSuperiorHUDEngine = NSHUDEngine.shared
    @ObservedObject private var liveActivityEngine = NSLiveActivityEngine.shared
    @ObservedObject private var shelfEngine = NSShelfEngine.shared
    @ObservedObject private var commandEngine = NSCommandEngine.shared
    @ObservedObject private var layoutEngine = NSLayoutEngine.shared
    @AppStorage("NSClipboardOpen") var clipboardOpen = false
    @AppStorage("NSAIChatOpen") var aiChatOpen = false
    @AppStorage("NSTerminalOpen") var terminalOpen = false
    
    private func isEnabled(_ slot: NSWidgetSlot) -> Bool {
        layoutEngine.effectiveWidgets.contains(slot)
    }
    
    private func isActivityEnabled() -> Bool {
        guard let activity = liveActivityEngine.currentActivity else { return false }
        let name = String(describing: type(of: activity))
        if name.contains("Media") {
            return isEnabled(.nowPlaying)
        }
        if name.contains("Timer") || name.contains("Focus") {
            return isEnabled(.focusTimer)
        }
        if name.contains("Battery") {
            return isEnabled(.batteryDetailed)
        }
        return true
    }
    @State private var hoverTask: Task<Void, Never>?
    @State private var isHovering: Bool = false
    @State private var anyDropDebounceTask: Task<Void, Never>?
    @State private var mouseClickMonitor: Any?
    @State private var localClickMonitor: Any?
    // Independent auto-close watchdog — decoupled from SwiftUI hover events.
    @State private var autoCloseWatchdog: Task<Void, Never>?
    @State private var mouseLeftAt: Date?

    @State private var gestureProgress: CGFloat = .zero

    @State private var haptics: Bool = false

    @Namespace var albumArtNamespace

    @Default(.useMusicVisualizer) var useMusicVisualizer

    @Default(.showNotHumanFace) var showNotHumanFace

    // Shared interactive spring for movement/resizing to avoid conflicting animations
    private let animationSpring = Animation.interactiveSpring(response: 0.38, dampingFraction: 0.8, blendDuration: 0)

    private let extendedHoverPadding: CGFloat = 30
    private let zeroHeightHoverPadding: CGFloat = 10

    private var topCornerRadius: CGFloat {
       ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                ? cornerRadiusInsets.opened.top
                : cornerRadiusInsets.closed.top
    }

    private var currentNotchShape: NotchShape {
        NotchShape(
            topCornerRadius: topCornerRadius,
            bottomCornerRadius: ((vm.notchState == .open) && Defaults[.cornerRadiusScaling])
                ? cornerRadiusInsets.opened.bottom
                : cornerRadiusInsets.closed.bottom
        )
    }

    private var computedChinWidth: CGFloat {
        var chinWidth: CGFloat = vm.closedNotchSize.width

        if coordinator.expandingView.type == .battery && coordinator.expandingView.show
            && vm.notchState == .closed && Defaults[.showPowerStatusNotifications]
        {
            chinWidth = 640
        } else if (!coordinator.expandingView.show || coordinator.expandingView.type == .music)
            && vm.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle)
            && coordinator.musicLiveActivityEnabled && !vm.hideOnClosed
        {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        } else if !coordinator.expandingView.show && vm.notchState == .closed
            && (!musicManager.isPlaying && musicManager.isPlayerIdle) && Defaults[.showNotHumanFace]
            && !vm.hideOnClosed
        {
            chinWidth += (2 * max(0, vm.effectiveClosedNotchHeight - 12) + 20)
        }

        return chinWidth
    }

    var body: some View {
        // Calculate scale based on gesture progress only
        let gestureScale: CGFloat = {
            guard gestureProgress != 0 else { return 1.0 }
            let scaleFactor = 1.0 + gestureProgress * 0.01
            return max(0.6, scaleFactor)
        }()
        
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                let mainLayout = NotchLayout()
                    .frame(alignment: .top)
                    .padding(
                        .horizontal,
                        vm.notchState == .open
                        ? Defaults[.cornerRadiusScaling]
                        ? (cornerRadiusInsets.opened.top) : (cornerRadiusInsets.opened.bottom)
                        : cornerRadiusInsets.closed.bottom
                    )
                    .padding([.horizontal, .bottom], vm.notchState == .open ? 12 : 0)
                    .background(.black)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(.black)
                            .frame(height: 1)
                            .padding(.horizontal, topCornerRadius)
                    }
                    .clipShape(currentNotchShape)
                    .shadow(
                        color: ((vm.notchState == .open || isHovering) && Defaults[.enableShadow])
                            ? .black.opacity(0.7) : .clear, radius: Defaults[.cornerRadiusScaling] ? 6 : 4
                    )
                    // Glow overlay placed AFTER clipShape so its blur can render
                    // into the glowHorizontalPadding canvas (30 pts per side) without
                    // being hard-clipped to the notch shape boundary.
                    .overlay {
                        if vm.notchState == .open && Defaults[.showSiriGlowBorder] {
                            SiriGlowBorder(shape: currentNotchShape)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(
                        .bottom,
                        vm.effectiveClosedNotchHeight == 0 ? 10 : 0
                    )
                
                mainLayout
                    // Cap width to the notch content area so the transparent glow
                    // padding on each side (glowHorizontalPadding/2 per side) does not
                    // participate in hover detection — previously the full 700pt window
                    // width kept isHovering=true even after the cursor left the notch.
                    .frame(
                        width: vm.notchState == .open ? openNotchSize.width : nil,
                        height: vm.notchState == .open ? vm.notchSize.height : nil
                    )
                    .conditionalModifier(true) { view in
                        let openAnimation = Animation.spring(response: 0.42, dampingFraction: 0.8, blendDuration: 0)
                        let closeAnimation = Animation.spring(response: 0.45, dampingFraction: 1.0, blendDuration: 0)

                        return view
                            .animation(vm.notchState == .open ? openAnimation : closeAnimation, value: vm.notchState)
                            .animation(.smooth, value: gestureProgress)
                    }
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        handleHover(hovering)
                    }
                    .conditionalModifier(Defaults[.enableGestures]) { view in
                        view
                            .panGesture(
                                direction: .down,
                                isEnabled: { coordinator.currentView == .home && !clipboardOpen && !aiChatOpen }
                            ) { translation, phase in
                                handleDownGesture(translation: translation, phase: phase)
                            }
                    }
                    .conditionalModifier(Defaults[.closeGestureEnabled] && Defaults[.enableGestures]) { view in
                        view
                            .panGesture(
                                direction: .up,
                                isEnabled: { coordinator.currentView == .home && !clipboardOpen && !aiChatOpen }
                            ) { translation, phase in
                                handleUpGesture(translation: translation, phase: phase)
                            }
                    }
                    // Horizontal swipe → skip tracks (left = next, right = previous)
                    .conditionalModifier(Defaults[.enableGestures]) { view in
                        view
                            .panGesture(
                                direction: .left,
                                isEnabled: { coordinator.currentView == .home && musicManager.isPlaying }
                            ) { _, phase in
                                if phase == .ended { MusicManager.shared.nextTrack() }
                            }
                            .panGesture(
                                direction: .right,
                                isEnabled: { coordinator.currentView == .home && musicManager.isPlaying }
                            ) { _, phase in
                                if phase == .ended { MusicManager.shared.previousTrack() }
                            }
                    }
                    .onTapGesture {
                        doOpen()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .sharingDidFinish)) { _ in
                        // When a share session ends, make sure the watchdog is running so
                        // the notch resumes its normal auto-close countdown.
                        if vm.notchState == .open && autoCloseWatchdog == nil {
                            startAutoCloseWatchdog()
                        }
                    }
                    .onChange(of: vm.notchState) { _, newState in
                        if newState == .open {
                            // Resume clipboard polling so any copy while notch was
                            // closed is captured immediately on first open.
                            NSClipboardEngine.shared.resumePolling()
                            startAutoCloseWatchdog()
                            installClickOutsideMonitor()
                        } else {
                            // Pause polling while closed to reduce CPU wakeups.
                            NSClipboardEngine.shared.pausePolling()
                            hoverTask?.cancel()
                            stopAutoCloseWatchdog()
                            removeClickOutsideMonitor()
                            if isHovering { withAnimation { isHovering = false } }
                        }
                    }
                    .sensoryFeedback(.alignment, trigger: haptics)
                    .contextMenu {
                        Button("Settings") {
                            DispatchQueue.main.async {
                                SettingsWindowController.shared.showWindow()
                            }
                        }
                        .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
                        //                    Button("Edit") { // Doesnt work....
                        //                        let dn = DynamicNotch(content: EditPanelView())
                        //                        dn.toggle()
                        //                    }
                        //                    .keyboardShortcut("E", modifiers: .command)
                    }
                if vm.chinHeight > 0 {
                    Rectangle()
                        .fill(Color.black.opacity(0.01))
                        .frame(width: computedChinWidth, height: vm.chinHeight)
                }
            }
            // Expand the VStack to the full window width so SiriGlowBorder's blur
            // can render into the glowHorizontalPadding canvas (30 pts each side).
            .frame(maxWidth: .infinity)

            if #available(macOS 14.0, *), isActivityEnabled() {
                if liveActivityEngine.currentActivity != nil {
                    NSLiveActivityView()
                        .zIndex(50)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.7).combined(with: .opacity),
                            removal: .scale(scale: 0.7).combined(with: .opacity)
                        ))
                }
            }

            if #available(macOS 14.0, *), clipboardOpen, isEnabled(.clipboardShortcut) {
                NSClipboardView()
                    .frame(width: 640, height: 180)
                    .background(Color.black)
                    .clipShape(currentNotchShape)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(NSTokens.animationSpring, value: clipboardOpen)
                    .zIndex(80)
            }

            if #available(macOS 14.0, *), aiChatOpen {
                NSAIChatView()
                    .frame(width: 640, height: 320)
                    .background(Color.black)
                    .clipShape(currentNotchShape)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(NSTokens.animationSpring, value: aiChatOpen)
                    .zIndex(80)
            }

            if #available(macOS 14.0, *), terminalOpen {
                NSTerminalDropView()
                    .frame(width: 640)
                    .background(Color.black)
                    .clipShape(currentNotchShape)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(NSTokens.animationSpring, value: terminalOpen)
                    .zIndex(80)
            }

            if #available(macOS 14.0, *), commandEngine.isVisible {
                NSCommandLauncherView()
                    .frame(width: 640)
                    .background(Color.black)
                    .clipShape(currentNotchShape)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(NSTokens.animationSpring, value: commandEngine.isVisible)
                    .zIndex(90)
            }

            if isEnabled(.volumeHUD) || isEnabled(.brightnessHUD) {
                if notchSuperiorHUDEngine.activeHUD != nil {
                    NSHUDOverlayView(engine: notchSuperiorHUDEngine)
                        .zIndex(100)
                }
            }
        }
        .padding(.bottom, 8)
        .frame(maxWidth: windowSize.width, maxHeight: windowSize.height, alignment: .top)
        .compositingGroup()
        .scaleEffect(
            x: gestureScale,
            y: gestureScale,
            anchor: .top
        )
        .animation(.smooth, value: gestureProgress)
        .background(dragDetector)
        .preferredColorScheme(.dark)
        .environmentObject(vm)
        .onChange(of: vm.anyDropZoneTargeting) { _, isTargeted in
            anyDropDebounceTask?.cancel()

            if isTargeted {
                if vm.notchState == .closed {
                    coordinator.currentView = .shelf
                    doOpen()
                }
                return
            }

            anyDropDebounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                if vm.dropEvent {
                    vm.dropEvent = false
                    return
                }

                vm.dropEvent = false
                if !SharingStateManager.shared.preventNotchClose {
                    vm.close()
                }
            }
        }
    }

    @ViewBuilder
    func NotchLayout() -> some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                if coordinator.helloAnimationRunning {
                    Spacer()
                    HelloAnimation(onFinish: {
                        vm.closeHello()
                    }).frame(
                        width: getClosedNotchSize().width,
                        height: 80
                    )
                    .padding(.top, 40)
                    Spacer()
                } else {
                    if isEnabled(.batteryDetailed) && coordinator.expandingView.type == .battery && coordinator.expandingView.show
                        && vm.notchState == .closed && Defaults[.showPowerStatusNotifications]
                    {
                        HStack(spacing: 0) {
                            HStack {
                                Text(batteryModel.statusText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }

                            Rectangle()
                                .fill(.black)
                                .frame(width: vm.closedNotchSize.width + 10)

                            HStack {
                                BoringBatteryView(
                                    batteryWidth: 30,
                                    isCharging: batteryModel.isCharging,
                                    isInLowPowerMode: batteryModel.isInLowPowerMode,
                                    isPluggedIn: batteryModel.isPluggedIn,
                                    levelBattery: batteryModel.levelBattery,
                                    isForNotification: true
                                )
                            }
                            .frame(width: 76, alignment: .trailing)
                        }
                        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
                      } else if (isEnabled(.volumeHUD) || isEnabled(.brightnessHUD)) && coordinator.sneakPeek.show && Defaults[.inlineHUD] && (coordinator.sneakPeek.type != .music) && (coordinator.sneakPeek.type != .battery) && vm.notchState == .closed {
                          InlineHUD(type: $coordinator.sneakPeek.type, value: $coordinator.sneakPeek.value, icon: $coordinator.sneakPeek.icon, hoverAnimation: $isHovering, gestureProgress: $gestureProgress)
                              .transition(.opacity)
                      } else if isEnabled(.nowPlaying) && (!coordinator.expandingView.show || coordinator.expandingView.type == .music) && vm.notchState == .closed && (musicManager.isPlaying || !musicManager.isPlayerIdle) && coordinator.musicLiveActivityEnabled && !vm.hideOnClosed {
                          MusicLiveActivity()
                              .frame(alignment: .center)
                      } else if #available(macOS 14.0, *), vm.notchState == .closed, (isEnabled(.gitStatus) || isEnabled(.dockerStatus) || isEnabled(.networkLatency)) {
                          NSDevStatusTile()
                              .frame(alignment: .center)
                      } else if !coordinator.expandingView.show && vm.notchState == .closed && (!musicManager.isPlaying && musicManager.isPlayerIdle) && Defaults[.showNotHumanFace] && !vm.hideOnClosed  {
                          BoringFaceAnimation()
                       } else if vm.notchState == .open {
                           BoringHeader()
                               .frame(height: max(24, vm.effectiveClosedNotchHeight))
                               .opacity(gestureProgress != 0 ? 1.0 - min(abs(gestureProgress) * 0.1, 0.3) : 1.0)
                       } else {
                           Rectangle().fill(.clear).frame(width: vm.closedNotchSize.width - 20, height: vm.effectiveClosedNotchHeight)
                       }

                      if coordinator.sneakPeek.show {
                          if (coordinator.sneakPeek.type != .music) && (coordinator.sneakPeek.type != .battery) && !Defaults[.inlineHUD] && vm.notchState == .closed {
                              if isEnabled(.volumeHUD) || isEnabled(.brightnessHUD) {
                                  SystemEventIndicatorModifier(
                                      eventType: $coordinator.sneakPeek.type,
                                      value: $coordinator.sneakPeek.value,
                                      icon: $coordinator.sneakPeek.icon,
                                      sendEventBack: { newVal in
                                          switch coordinator.sneakPeek.type {
                                          case .volume:
                                              VolumeManager.shared.setAbsolute(Float32(newVal))
                                          case .brightness:
                                              BrightnessManager.shared.setAbsolute(value: Float32(newVal))
                                          default:
                                              break
                                          }
                                      }
                                  )
                                  .padding(.bottom, 10)
                                  .padding(.leading, 4)
                                  .padding(.trailing, 8)
                              }
                          }
                          // Old sneak peek music
                          else if coordinator.sneakPeek.type == .music {
                              if isEnabled(.nowPlaying) && vm.notchState == .closed && !vm.hideOnClosed && Defaults[.sneakPeekStyles] == .standard {
                                  HStack(alignment: .center) {
                                      Image(systemName: "music.note")
                                      GeometryReader { geo in
                                          MarqueeText(.constant(musicManager.songTitle + " - " + musicManager.artistName),  textColor: Defaults[.playerColorTinting] ? Color(nsColor: musicManager.avgColor).ensureMinimumBrightness(factor: 0.6) : .gray, minDuration: 1, frameWidth: geo.size.width)
                                      }
                                  }
                                  .foregroundStyle(.gray)
                                  .padding(.bottom, 10)
                              }
                          }
                      }
                  }
              }
              .conditionalModifier((coordinator.sneakPeek.show && (coordinator.sneakPeek.type == .music) && vm.notchState == .closed && !vm.hideOnClosed && Defaults[.sneakPeekStyles] == .standard) || (coordinator.sneakPeek.show && (coordinator.sneakPeek.type != .music) && (vm.notchState == .closed))) { view in
                  view
                      .fixedSize()
              }
              .zIndex(2)
            if vm.notchState == .open {
                VStack {
                    switch coordinator.currentView {
                    case .home:
                        NotchHomeView(albumArtNamespace: albumArtNamespace)
                    case .shelf:
                        if #available(macOS 14.0, *) {
                            NSShelfView()
                        } else {
                            ShelfView()
                        }
                    case .clipboard:
                        NSClipboardView()
                    case .notes:
                        NSNotchNotesView()
                    case .stats:
                        if #available(macOS 14.0, *) {
                            NSSystemStatsView()
                        }
                    case .camera:
                        if #available(macOS 14.0, *) {
                            NSCameraView()
                        }
                    }
                }
                // Hard-cap tab content to the open notch content area.
                // Prevents any tab view from expanding the window beyond openNotchSize.
                .frame(maxWidth: openNotchSize.width, maxHeight: openNotchSize.height)
                .clipped()
                .transition(
                    .scale(scale: 0.8, anchor: .top)
                    .combined(with: .opacity)
                    .animation(.smooth(duration: 0.35))
                )
                .zIndex(1)
                .allowsHitTesting(vm.notchState == .open)
                .opacity(gestureProgress != 0 ? 1.0 - min(abs(gestureProgress) * 0.1, 0.3) : 1.0)
            }
        }
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], delegate: GeneralDropTargetDelegate(isTargeted: $vm.generalDropTargeting))
    }

    @ViewBuilder
    func BoringFaceAnimation() -> some View {
        HStack {
            HStack {
                Rectangle()
                    .fill(.clear)
                    .frame(
                        width: max(0, vm.effectiveClosedNotchHeight - 12),
                        height: max(0, vm.effectiveClosedNotchHeight - 12)
                    )
                Rectangle()
                    .fill(.black)
                    .frame(width: vm.closedNotchSize.width - 20)
                MinimalFaceFeatures()
            }
        }.frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
    }

    @ViewBuilder
    func MusicLiveActivity() -> some View {
        HStack {
            Image(nsImage: musicManager.albumArt)
                .resizable()
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: MusicPlayerImageSizes.cornerRadiusInset.closed)
                )
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .frame(
                    width: max(0, vm.effectiveClosedNotchHeight - 12),
                    height: max(0, vm.effectiveClosedNotchHeight - 12)
                )

            Rectangle()
                .fill(.black)
                .overlay(
                    HStack(alignment: .top) {
                        if coordinator.expandingView.show
                            && coordinator.expandingView.type == .music
                        {
                            MarqueeText(
                                .constant(musicManager.songTitle),
                                textColor: Defaults[.coloredSpectrogram]
                                    ? Color(nsColor: musicManager.avgColor) : Color.gray,
                                minDuration: 0.4,
                                frameWidth: 100
                            )
                            .opacity(
                                (coordinator.expandingView.show
                                    && Defaults[.sneakPeekStyles] == .inline)
                                    ? 1 : 0
                            )
                            Spacer(minLength: vm.closedNotchSize.width)
                            // Song Artist
                            Text(musicManager.artistName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .foregroundStyle(
                                    Defaults[.coloredSpectrogram]
                                        ? Color(nsColor: musicManager.avgColor)
                                        : Color.gray
                                )
                                .opacity(
                                    (coordinator.expandingView.show
                                        && coordinator.expandingView.type == .music
                                        && Defaults[.sneakPeekStyles] == .inline)
                                        ? 1 : 0
                                )
                        }
                    }
                )
                .frame(
                    width: (coordinator.expandingView.show
                        && coordinator.expandingView.type == .music
                        && Defaults[.sneakPeekStyles] == .inline)
                        ? 380
                        : vm.closedNotchSize.width
                            + -cornerRadiusInsets.closed.top
                )

            HStack {
                if useMusicVisualizer {
                    Rectangle()
                        .fill(
                            Defaults[.coloredSpectrogram]
                                ? Color(nsColor: musicManager.avgColor).gradient
                                : Color.gray.gradient
                        )
                        .frame(width: 50, alignment: .center)
                        .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
                        .mask {
                            AudioSpectrumView(isPlaying: $musicManager.isPlaying)
                                .frame(width: 16, height: 12)
                        }
                } else {
                    LottieAnimationContainer()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(
                width: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                        + gestureProgress / 2
                ),
                height: max(
                    0,
                    vm.effectiveClosedNotchHeight - 12
                ),
                alignment: .center
            )
        }
        .frame(
            height: vm.effectiveClosedNotchHeight,
            alignment: .center
        )
    }

    @ViewBuilder
    var dragDetector: some View {
        if Defaults[.boringShelf] && vm.notchState == .closed {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        .onDrop(of: [.fileURL, .url, .utf8PlainText, .plainText, .data], isTargeted: $vm.dragDetectorTargeting) { providers in
            vm.dropEvent = true
            ShelfStateViewModel.shared.load(providers)
            return true
        }
        } else {
            EmptyView()
        }
    }

    private func doOpen() {
        withAnimation(animationSpring) {
            vm.open()
        }
    }

    // MARK: - Hover Management

    private func handleHover(_ hovering: Bool) {
        if coordinator.firstLaunch { return }
        hoverTask?.cancel()

        if hovering {
            withAnimation(animationSpring) { isHovering = true }
            if vm.notchState == .closed && Defaults[.enableHaptics] { haptics.toggle() }
            guard vm.notchState == .closed, !coordinator.sneakPeek.show, Defaults[.openNotchOnHover] else { return }
            hoverTask = Task {
                try? await Task.sleep(for: .seconds(Defaults[.minimumHoverDuration]))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard self.vm.notchState == .closed, self.isHovering, !self.coordinator.sneakPeek.show else { return }
                    self.doOpen()
                }
            }
        } else {
            withAnimation(animationSpring) { self.isHovering = false }
            // Closing is handled entirely by the auto-close watchdog (which polls the
            // real cursor position), so nothing to schedule here.
        }
    }

    // MARK: - Auto-close watchdog

    /// A self-contained loop that closes the notch once the cursor has stayed
    /// outside it for `notchCloseDelay`. It relies solely on the real cursor
    /// position (`vm.isMouseHovering()`), NOT on SwiftUI `onHover` events — those
    /// can be dropped or re-fired, which previously left the notch stuck open.
    private func startAutoCloseWatchdog() {
        stopAutoCloseWatchdog()
        mouseLeftAt = nil
        autoCloseWatchdog = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                guard vm.notchState == .open else { return }

                let blocked = vm.isBatteryPopoverActive
                    || SharingStateManager.shared.preventNotchClose
                    || coordinator.clipboardIsScrolling

                if blocked || vm.isMouseHovering() {
                    // Cursor is over the notch (or close is temporarily blocked) —
                    // reset the "left" timer.
                    mouseLeftAt = nil
                } else {
                    // Cursor is away. Start / continue the countdown.
                    let now = Date()
                    if let left = mouseLeftAt {
                        if now.timeIntervalSince(left) >= Defaults[.notchCloseDelay] {
                            isHovering = false
                            vm.close()
                            return
                        }
                    } else {
                        mouseLeftAt = now
                    }
                }
            }
        }
    }

    private func stopAutoCloseWatchdog() {
        autoCloseWatchdog?.cancel()
        autoCloseWatchdog = nil
        mouseLeftAt = nil
    }

    // MARK: - Click-outside monitor

    private func installClickOutsideMonitor() {
        removeClickOutsideMonitor()
        // Global monitor: fires for mouse-down events delivered to OTHER processes,
        // i.e. any click that lands in another app's window → close immediately.
        mouseClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak vm] _ in
            guard let vm, vm.notchState == .open else { return }
            guard !SharingStateManager.shared.preventNotchClose else { return }
            DispatchQueue.main.async { vm.close() }
        }
        // Local monitor: fires for clicks delivered to OUR OWN window. The window is
        // wider than the visible notch, so clicks in the transparent margins must also
        // dismiss. Clicks on the actual notch content (buttons/tabs) keep it open and
        // are passed through untouched.
        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak vm] event in
            guard let vm, vm.notchState == .open else { return event }
            guard !SharingStateManager.shared.preventNotchClose else { return event }
            if !vm.isMouseHovering() {
                DispatchQueue.main.async { vm.close() }
            }
            return event
        }
    }

    private func removeClickOutsideMonitor() {
        if let monitor = mouseClickMonitor {
            NSEvent.removeMonitor(monitor)
            mouseClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    // MARK: - Gesture Handling

    private func handleDownGesture(translation: CGFloat, phase: NSEvent.Phase) {
        guard vm.notchState == .closed else { return }

        if phase == .ended {
            withAnimation(animationSpring) { gestureProgress = .zero }
            return
        }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * 20
        }

        if translation > Defaults[.gestureSensitivity] {
            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
            doOpen()
        }
    }

    private func handleUpGesture(translation: CGFloat, phase: NSEvent.Phase) {
        guard vm.notchState == .open && !vm.isHoveringCalendar && !coordinator.clipboardIsScrolling && coordinator.currentView != .clipboard && coordinator.currentView != .notes && coordinator.currentView != .stats && coordinator.currentView != .camera && !clipboardOpen && !aiChatOpen else { return }

        withAnimation(animationSpring) {
            gestureProgress = (translation / Defaults[.gestureSensitivity]) * -20
        }

        if phase == .ended {
            withAnimation(animationSpring) {
                gestureProgress = .zero
            }
        }

        if translation > Defaults[.gestureSensitivity] {
            withAnimation(animationSpring) {
                isHovering = false
            }
            if !SharingStateManager.shared.preventNotchClose { 
                gestureProgress = .zero
                vm.close()
            }

            if Defaults[.enableHaptics] {
                haptics.toggle()
            }
        }
    }
}

struct FullScreenDropDelegate: DropDelegate {
    @Binding var isTargeted: Bool
    let onDrop: () -> Void

    func dropEntered(info _: DropInfo) {
        isTargeted = true
    }

    func dropExited(info _: DropInfo) {
        isTargeted = false
    }

    func performDrop(info _: DropInfo) -> Bool {
        isTargeted = false
        onDrop()
        return true
    }

}

struct GeneralDropTargetDelegate: DropDelegate {
    @Binding var isTargeted: Bool

    func dropEntered(info: DropInfo) {
        isTargeted = true
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .cancel)
    }

    func performDrop(info: DropInfo) -> Bool {
        return false
    }
}

struct SiriGlowBorder: View {
    let shape: NotchShape
    @State private var rotationAngle1: Double = 0.0
    @State private var rotationAngle2: Double = 180.0
    @State private var pulseOpacity: Double = 0.8
    @State private var glowPulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Layer 1: Broad Outer Aura
            shape
                .stroke(
                    gradient(angle: rotationAngle1, reverse: false),
                    lineWidth: 12.0
                )
                .blur(radius: 18.0)
                .opacity(pulseOpacity * 0.45)
                .scaleEffect(x: glowPulse, y: glowPulse)
            
            // Layer 2: Mid-range Glow
            shape
                .stroke(
                    gradient(angle: rotationAngle2, reverse: true),
                    lineWidth: 4.5
                )
                .blur(radius: 6.0)
                .opacity(pulseOpacity * 0.75)
                .scaleEffect(x: (glowPulse - 1.0) * 0.5 + 1.0, y: (glowPulse - 1.0) * 0.5 + 1.0)
            
            // Layer 3: Crisp Core Line
            shape
                .stroke(
                    gradient(angle: rotationAngle1, reverse: false),
                    lineWidth: 1.8
                )
                .blur(radius: 0.4)
                .opacity(pulseOpacity)
        }
        .blendMode(.screen)
        .onAppear {
            withAnimation(.linear(duration: 6.5).repeatForever(autoreverses: false)) {
                rotationAngle1 = 360.0
            }
            withAnimation(.linear(duration: 8.5).repeatForever(autoreverses: false)) {
                rotationAngle2 = -180.0
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulseOpacity = 1.0
                glowPulse = 1.03
            }
        }
    }

    private func gradient(angle: Double, reverse: Bool) -> AngularGradient {
        let colors = [
            Color(red: 0.58, green: 0.2, blue: 0.92), // siri violet
            Color(red: 0.12, green: 0.35, blue: 0.98), // siri blue
            Color(red: 0.18, green: 0.82, blue: 0.86), // siri cyan
            Color(red: 0.96, green: 0.23, blue: 0.61), // siri pink
            Color(red: 0.98, green: 0.62, blue: 0.25), // siri orange-yellow
            Color(red: 0.58, green: 0.2, blue: 0.92)  // siri violet wrap
        ]
        return AngularGradient(
            colors: reverse ? colors.reversed() : colors,
            center: .center,
            angle: .degrees(angle)
        )
    }
}

#Preview {
    let vm = BoringViewModel()
    vm.open()
    return ContentView()
        .environmentObject(vm)
        .frame(width: vm.notchSize.width, height: vm.notchSize.height)
}
