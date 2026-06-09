// NOTCHSUPERIOR ADDITION -- HUD Engine

import AppKit
import Combine
import Defaults
import SwiftUI

enum NSHUDEvent: Equatable, Identifiable {
    case volume(Float)
    case brightness(Float)
    case keyboardBacklight(Float)
    case nowPlaying(title: String, artist: String)
    case combined([NSHUDEvent])

    var id: String {
        switch self {
        case .volume(let value):
            return "volume-\(value)"
        case .brightness(let value):
            return "brightness-\(value)"
        case .keyboardBacklight(let value):
            return "keyboard-\(value)"
        case .nowPlaying(let title, let artist):
            return "now-playing-\(title)-\(artist)"
        case .combined(let events):
            return "combined-\(events.map(\.id).joined(separator: "-"))"
        }
    }
}

@MainActor
final class NSHUDEngine: ObservableObject {
    static let shared = NSHUDEngine()

    @Published private(set) var activeHUD: NSHUDEvent?
    @Published var selectedTheme: NSHUDTheme {
        didSet { NSHUDTheme.storedTheme = selectedTheme }
    }

    var dismissDelay: TimeInterval = 2.4

    private var cancellables: Set<AnyCancellable> = []
    private var dismissTask: Task<Void, Never>?
    private var lastNowPlayingSnapshot: (title: String, artist: String)?
    private let dismissDurationKey = "NSHUDDismissDuration"
    private let combinedHUDKey = "NSHUDCombined"

    private init() {
        selectedTheme = NSHUDTheme.storedTheme
        bindManagers()
        attachSystemEventTapIfNeeded()
    }

    func setTheme(_ theme: NSHUDTheme) {
        selectedTheme = theme
    }

    func show(_ event: NSHUDEvent, dismissAfter delay: TimeInterval? = nil) {
        dismissTask?.cancel()
        selectedTheme = .storedTheme

        withAnimation(NSTokens.animationSpring) {
            activeHUD = event
        }

        dismissTask = Task { [weak self] in
            let timeout = delay ?? self?.resolvedDismissDelay ?? 2.4
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.dismiss()
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(NSTokens.dismissAnimation) {
            activeHUD = nil
        }
    }

    private func bindManagers() {
        VolumeManager.shared.$lastChangeAt
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] changeAt in
                guard changeAt > .distantPast else { return }
                self?.emitVolumeHUD()
            }
            .store(in: &cancellables)

        BrightnessManager.shared.$lastChangeAt
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] changeAt in
                guard changeAt > .distantPast else { return }
                self?.show(.brightness(BrightnessManager.shared.rawBrightness))
            }
            .store(in: &cancellables)

        KeyboardBacklightManager.shared.$lastChangeAt
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] changeAt in
                guard changeAt > .distantPast else { return }
                self?.show(.keyboardBacklight(KeyboardBacklightManager.shared.rawBrightness))
            }
            .store(in: &cancellables)

        Publishers.CombineLatest3(
            MusicManager.shared.$songTitle,
            MusicManager.shared.$artistName,
            MusicManager.shared.$isPlaying
        )
        .sink { [weak self] title, artist, isPlaying in
            guard let self else { return }
            if isPlaying || !title.isEmpty || !artist.isEmpty {
                self.lastNowPlayingSnapshot = (title: title, artist: artist)
            }
        }
        .store(in: &cancellables)
    }

    private func emitVolumeHUD() {
        let baseEvent = NSHUDEvent.volume(VolumeManager.shared.rawVolume)
        guard combinedHUDAvailable else {
            show(baseEvent)
            return
        }

        guard let snapshot = lastNowPlayingSnapshot,
              !snapshot.title.isEmpty || !snapshot.artist.isEmpty,
              MusicManager.shared.isPlaying || !MusicManager.shared.isPlayerIdle else {
            show(baseEvent)
            return
        }

        show(
            .combined([
                .nowPlaying(title: snapshot.title, artist: snapshot.artist),
                baseEvent,
            ])
        )
    }

    private func attachSystemEventTapIfNeeded() {
        Task {
            guard Defaults[.hudReplacement] else { return }
            guard await XPCHelperClient.shared.isAccessibilityAuthorized() else { return }
            await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
        }
    }

    private var resolvedDismissDelay: TimeInterval {
        let stored = UserDefaults.standard.object(forKey: dismissDurationKey) as? Double
        return stored ?? dismissDelay
    }

    private var combinedHUDAvailable: Bool {
        UserDefaults.standard.object(forKey: combinedHUDKey) as? Bool ?? true
    }
}
