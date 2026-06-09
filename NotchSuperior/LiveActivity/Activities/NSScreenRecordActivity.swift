// ────────────────────────────────────────────────────────
// NotchSuperior — NSScreenRecordActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSScreenRecordActivity: NSActivity {
    let id: UUID
    let priority: Int = 8 // Second highest
    let ttl: TimeInterval? = nil // Persists while recording
    
    let startTime: Date
    
    init(id: UUID = UUID(), startTime: Date) {
        self.id = id
        self.startTime = startTime
    }
    
    var compactView: AnyView {
        AnyView(NSScreenRecordCompactView())
    }
    
    var expandedView: AnyView {
        AnyView(NSScreenRecordExpandedView(id: id, startTime: startTime))
    }
}

struct NSScreenRecordCompactView: View {
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(isPulsing ? 0.3 : 1.0)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            Text("Recording")
                .font(.caption2)
                .foregroundColor(.red)
        }
    }
}

struct NSScreenRecordExpandedView: View {
    let id: UUID
    let startTime: Date
    @State private var elapsedSeconds: Int = 0
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                Text("Screen Recording Active")
                    .font(.headline)
            }
            
            Text("Elapsed Time: \(formatTime(elapsedSeconds))")
                .font(.title2.monospacedDigit())
                .foregroundColor(.primary)
                .onReceive(timer) { _ in
                    elapsedSeconds = Int(Date().timeIntervalSince(startTime))
                }
                .onAppear {
                    elapsedSeconds = Int(Date().timeIntervalSince(startTime))
                }
            
            Text("Use menu bar to stop")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                Button("Dismiss") {
                    NSLiveActivityEngine.shared.dismiss(id)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary.opacity(0.1)))
            }
        }
        .padding()
    }
    
    private func formatTime(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

@MainActor
final class NSScreenRecordObserver: ObservableObject {
    static let shared = NSScreenRecordObserver()
    
    private var timer: Timer?
    private var isRecording = false
    private var currentActivityId: UUID?
    private var startTime: Date?
    
    private init() {}
    
    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkScreenRecording()
            }
        }
    }
    
    private func checkScreenRecording() {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.screencaptured")
        let currentlyRecording = !apps.isEmpty
        
        if currentlyRecording && !isRecording {
            isRecording = true
            let id = UUID()
            currentActivityId = id
            let now = Date()
            startTime = now
            let activity = NSScreenRecordActivity(id: id, startTime: now)
            NSLiveActivityEngine.shared.post(activity)
        } else if !currentlyRecording && isRecording {
            isRecording = false
            if let id = currentActivityId {
                NSLiveActivityEngine.shared.dismiss(id)
            }
            currentActivityId = nil
            startTime = nil
        }
    }
}
