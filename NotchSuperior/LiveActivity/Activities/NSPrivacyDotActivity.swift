// ────────────────────────────────────────────────────────
// NotchSuperior — NSPrivacyDotActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-10
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI
import Cocoa

struct NSPrivacyDotActivity: NSActivity {
    let id = UUID()
    let priority = 9 // Highest priority
    let ttl: TimeInterval? = nil

    var compactView: AnyView {
        AnyView(NSPrivacyDotCompactView())
    }

    var expandedView: AnyView {
        AnyView(NSPrivacyDotExpandedView())
    }
}

struct NSPrivacyDotCompactView: View {
    @State private var micActive = false
    @State private var cameraActive = false
    @ObservedObject var webcamManager = WebcamManager.shared
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            if cameraActive || webcamManager.isSessionRunning {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
            }
            if micActive {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 6)
        .onReceive(timer) { _ in
            checkPrivacyUsage()
        }
        .onAppear {
            checkPrivacyUsage()
        }
    }

    private func checkPrivacyUsage() {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        var foundMic = false
        var foundCamera = false
        for window in list {
            guard let owner = window[kCGWindowOwnerName as String] as? String else { continue }
            if owner == "ControlCenter" || owner == "NotificationCenter" || owner == "Window Server" {
                if let name = window[kCGWindowName as String] as? String {
                    if name.contains("Microphone") || name.contains("Recording Indicator") {
                        foundMic = true
                    }
                    if name.contains("Camera") || name.contains("Video") {
                        foundCamera = true
                    }
                }
            }
        }
        micActive = foundMic
        cameraActive = foundCamera
    }
}

struct NSPrivacyDotExpandedView: View {
    @State private var micActive = false
    @State private var cameraActive = false
    @ObservedObject var webcamManager = WebcamManager.shared
    
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 6) {
            Text("Privacy Indicator")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 12) {
                if cameraActive || webcamManager.isSessionRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Camera Active")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                
                if micActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("Mic Active")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                
                if !micActive && !cameraActive && !webcamManager.isSessionRunning {
                    Text("No active recording")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(width: 200)
        .onReceive(timer) { _ in
            checkPrivacyUsage()
        }
        .onAppear {
            checkPrivacyUsage()
        }
    }

    private func checkPrivacyUsage() {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        var foundMic = false
        var foundCamera = false
        for window in list {
            guard let owner = window[kCGWindowOwnerName as String] as? String else { continue }
            if owner == "ControlCenter" || owner == "NotificationCenter" || owner == "Window Server" {
                if let name = window[kCGWindowName as String] as? String {
                    if name.contains("Microphone") || name.contains("Recording Indicator") {
                        foundMic = true
                    }
                    if name.contains("Camera") || name.contains("Video") {
                        foundCamera = true
                    }
                }
            }
        }
        micActive = foundMic
        cameraActive = foundCamera
    }
}
