// ────────────────────────────────────────────────────────
// NotchSuperior — NSFocusEngine.swift
// Part of the boring.notch fork
// Phase: 5 — Focus & Pomodoro Timer
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import Cocoa
import Combine

@MainActor
class NSFocusEngine: ObservableObject {
    static let shared = NSFocusEngine()

    enum TimerState { case idle, working, breaking, longBreak }

    @Published var state: TimerState = .idle
    @Published var secondsRemaining: Int = 0
    @Published var session: NSFocusSession = NSFocusEngine.defaultPomodoro
    @Published var isPaused: Bool = false

    private var timer: Timer?
    private var roundsDone = 0

    static var defaultPomodoro: NSFocusSession {
        NSFocusSession(id: UUID(), mode: .pomodoro, workMinutes: 25,
            breakMinutes: 5, longBreakMinutes: 15, completedRounds: 0)
    }

    private init() {}

    func start() {
        guard state == .idle else { return }
        
        let workMin = UserDefaults.standard.integer(forKey: "NSFocusWorkMinutes")
        let breakMin = UserDefaults.standard.integer(forKey: "NSFocusBreakMinutes")
        let longMin = UserDefaults.standard.integer(forKey: "NSFocusLongBreak")
        let modeRaw = UserDefaults.standard.string(forKey: "NSFocusMode") ?? "pomodoro"
        
        let mode = NSFocusMode(rawValue: modeRaw) ?? .pomodoro
        
        let work = workMin > 0 ? workMin : (mode == .flow ? 52 : 25)
        let breakM = breakMin > 0 ? breakMin : (mode == .flow ? 17 : 5)
        let longM = longMin > 0 ? longMin : 15
        
        session = NSFocusSession(
            id: UUID(),
            mode: mode,
            workMinutes: work,
            breakMinutes: breakM,
            longBreakMinutes: longM,
            completedRounds: 0,
            startedAt: Date()
        )
        
        state = .working
        isPaused = false
        secondsRemaining = session.workMinutes * 60
        scheduleTimer()
        
        if #available(macOS 14.0, *) {
            NSLiveActivityEngine.shared.post(NSFocusActivity(engine: self))
        }
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isPaused = true
        if #available(macOS 14.0, *) {
            NSLiveActivityEngine.shared.post(NSFocusActivity(engine: self))
        }
    }

    func resume() {
        isPaused = false
        scheduleTimer()
        if #available(macOS 14.0, *) {
            NSLiveActivityEngine.shared.post(NSFocusActivity(engine: self))
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        secondsRemaining = 0
        roundsDone = 0
        isPaused = false
        if #available(macOS 14.0, *) {
            NSLiveActivityEngine.shared.dismiss(for: NSFocusActivity.self)
        }
    }

    func skip() { advanceState() }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard secondsRemaining > 0 else {
            advanceState()
            return
        }
        secondsRemaining -= 1
    }

    private func advanceState() {
        timer?.invalidate()
        switch state {
        case .working:
            roundsDone += 1
            session.completedRounds += 1
            if roundsDone % 4 == 0 {
                state = .longBreak
                secondsRemaining = session.longBreakMinutes * 60
            } else {
                state = .breaking
                secondsRemaining = session.breakMinutes * 60
            }
        case .breaking, .longBreak:
            state = .working
            secondsRemaining = session.workMinutes * 60
        case .idle:
            break
        }
        scheduleTimer()
        if #available(macOS 14.0, *) {
            NSLiveActivityEngine.shared.post(NSFocusActivity(engine: self))
        }
    }
}
