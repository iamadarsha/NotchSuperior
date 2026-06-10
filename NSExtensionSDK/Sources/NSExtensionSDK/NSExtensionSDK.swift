// ────────────────────────────────────────────────────────
// NotchSuperior — NSExtensionSDK.swift
// Phase: 10 — Third-Party Live Activity Push SDK
// Created: 2026-06-10
// ────────────────────────────────────────────────────────

import Foundation

/// Defines a request to display a Live Activity inside NotchSuperior's notch area.
public struct NSLiveActivityRequest: Codable {
    public let id: UUID
    public let priority: Int
    public let ttl: TimeInterval?
    public let title: String
    public let subtitle: String?
    public let progress: Double? // Value between 0.0 and 1.0
    public let systemImageName: String?
    public let customIconColor: String? // Hex or preset name (e.g. "green", "#00FF00")
    public let actionLabel: String?
    public let actionNotificationName: String?

    public init(
        id: UUID = UUID(),
        priority: Int = 5,
        ttl: TimeInterval? = nil,
        title: String,
        subtitle: String? = nil,
        progress: Double? = nil,
        systemImageName: String? = nil,
        customIconColor: String? = nil,
        actionLabel: String? = nil,
        actionNotificationName: String? = nil
    ) {
        self.id = id
        self.priority = priority
        self.ttl = ttl
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.systemImageName = systemImageName
        self.customIconColor = customIconColor
        self.actionLabel = actionLabel
        self.actionNotificationName = actionNotificationName
    }
}

/// Client helper to interact with NotchSuperior from third-party apps.
public final class NSLiveActivityClient {
    public static let shared = NSLiveActivityClient()
    private init() {}

    private let notificationCenter = DistributedNotificationCenter.default()

    /// Posts or updates a Live Activity in NotchSuperior.
    ///
    /// - Parameter request: The live activity payload.
    public func post(request: NSLiveActivityRequest) {
        guard let data = try? JSONEncoder().encode(request),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        notificationCenter.postNotificationName(
            Notification.Name("com.notchsuperior.activity.post"),
            object: jsonString,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    /// Dismisses a Live Activity in NotchSuperior.
    ///
    /// - Parameter id: The UUID of the activity to dismiss.
    public func dismiss(id: UUID) {
        notificationCenter.postNotificationName(
            Notification.Name("com.notchsuperior.activity.dismiss"),
            object: id.uuidString,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    /// Subscribes to notification callbacks triggered by actions on this activity's button.
    ///
    /// - Parameters:
    ///   - notificationName: The unique name passed to request.actionNotificationName.
    ///   - handler: Closure to run when the button is clicked.
    /// - Returns: An observation token to use for unregistering.
    public func observeAction(for notificationName: String, handler: @escaping () -> Void) -> NSObjectProtocol {
        return notificationCenter.addObserver(
            forName: Notification.Name(notificationName),
            object: nil,
            queue: .main
        ) { _ in
            handler()
        }
    }

    /// Unregisters an action listener.
    public func removeObserver(_ observer: NSObjectProtocol) {
        notificationCenter.removeObserver(observer)
    }
}
