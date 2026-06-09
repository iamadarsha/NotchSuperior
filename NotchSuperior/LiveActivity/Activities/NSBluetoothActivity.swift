// ────────────────────────────────────────────────────────
// NotchSuperior — NSBluetoothActivity.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI
import IOBluetooth

enum BTEvent: Equatable, Codable {
    case connected
    case disconnected
    case lowBattery(Int)
}

struct NSBluetoothActivity: NSActivity {
    let id: UUID
    let priority: Int = 5
    let ttl: TimeInterval? = 4.0 // 4.0 seconds (auto-dismiss)
    
    let deviceName: String
    let event: BTEvent
    
    init(id: UUID = UUID(), deviceName: String, event: BTEvent) {
        self.id = id
        self.deviceName = deviceName
        self.event = event
    }
    
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 4) {
                Image(systemName: event == .connected ? "bluetooth.connected" : "bluetooth")
                    .foregroundColor(event == .connected ? .blue : .secondary)
                Text(deviceName)
                    .font(.caption2)
                    .lineLimit(1)
            }
        )
    }
    
    var expandedView: AnyView {
        let eventDescription: String = {
            switch event {
            case .connected:
                return "Connected"
            case .disconnected:
                return "Disconnected"
            case .lowBattery(let percentage):
                return "Low Battery (\(percentage)%)"
            }
        }()
        
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                Text(deviceName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: event == .connected ? "bluetooth.connected" : "bluetooth")
                        .foregroundColor(event == .connected ? .blue : .secondary)
                    
                    Text(eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if case .lowBattery(let percentage) = event {
                    HStack(spacing: 6) {
                        Image(systemName: "battery.25")
                            .foregroundColor(.red)
                        Text("Please charge device (\(percentage)%)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        )
    }
}

@available(macOS 26.0, *)
@MainActor
final class NSBluetoothObserver: NSObject {
    static let shared = NSBluetoothObserver()
    
    private var connectionNotification: IOBluetoothUserNotification?
    
    private override init() {
        super.init()
    }
    
    func start() {
        // Register for connect notifications
        connectionNotification = IOBluetoothDevice.register(forConnectNotifications: self,
                                                            selector: #selector(deviceDidConnect(_:fromDevice:)))
    }
    
    @objc nonisolated private func deviceDidConnect(_ notification: IOBluetoothUserNotification?, fromDevice device: IOBluetoothDevice?) {
        guard let device = device else { return }
        let name = device.name ?? "Bluetooth Device"
        
        Task { @MainActor in
            let activity = NSBluetoothActivity(deviceName: name, event: .connected)
            NSLiveActivityEngine.shared.post(activity)
        }
        
        // Register for disconnect notifications for this specific device
        device.register(forDisconnectNotification: self,
                        selector: #selector(deviceDidDisconnect(_:fromDevice:)))
    }
    
    @objc nonisolated private func deviceDidDisconnect(_ notification: IOBluetoothUserNotification?, fromDevice device: IOBluetoothDevice?) {
        guard let device = device else { return }
        let name = device.name ?? "Bluetooth Device"
        
        Task { @MainActor in
            let activity = NSBluetoothActivity(deviceName: name, event: .disconnected)
            NSLiveActivityEngine.shared.post(activity)
        }
    }
}
