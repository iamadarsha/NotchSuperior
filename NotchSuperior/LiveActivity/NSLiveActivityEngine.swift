// ────────────────────────────────────────────────────────
// NotchSuperior — NSLiveActivityEngine.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity Engine
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI
import Combine

protocol NSActivity: Identifiable {
    var id: UUID { get }
    var priority: Int { get }        // higher = shown first
    var ttl: TimeInterval? { get }   // nil = stays until dismissed
    @MainActor var compactView: AnyView { get }   // fits in 20pt tall notch
    @MainActor var expandedView: AnyView { get }  // shown on tap
}

@MainActor
final class NSLiveActivityEngine: ObservableObject {
    static let shared = NSLiveActivityEngine()
    
    @Published var currentActivity: (any NSActivity)?
    private var queue: [any NSActivity] = []
    private var dismissTask: Task<Void, Never>?
    
    private init() {
        setupExternalObservers()
    }
    
    func post(_ activity: any NSActivity) {
        // Remove existing occurrence if matching by ID
        queue.removeAll { $0.id == activity.id }
        
        // Adds to queue
        queue.append(activity)
        
        // Sorts by priority descending
        queue.sort { $0.priority > $1.priority }
        
        let oldActivity = currentActivity
        currentActivity = queue.first
        
        if currentActivity?.id != oldActivity?.id {
            scheduleDismissalIfNeeded()
        }
    }
    
    func dismiss(_ id: UUID) {
        // Removes from queue
        queue.removeAll { $0.id == id }
        
        // Promotes next in queue to currentActivity
        currentActivity = queue.first
        
        // Cancels existing dismissTask if queue is now empty
        if queue.isEmpty {
            dismissTask?.cancel()
            dismissTask = nil
        } else {
            scheduleDismissalIfNeeded()
        }
    }
    
    func dismiss(for activityType: any NSActivity.Type) {
        queue.removeAll { type(of: $0) == activityType }
        currentActivity = queue.first
        if queue.isEmpty {
            dismissTask?.cancel()
            dismissTask = nil
        } else {
            scheduleDismissalIfNeeded()
        }
    }
    
    func dismissAll() {
        queue.removeAll()
        currentActivity = nil
        dismissTask?.cancel()
        dismissTask = nil
    }
    
    private func scheduleDismissalIfNeeded() {
        dismissTask?.cancel()
        dismissTask = nil
        
        guard let activity = currentActivity, let ttl = activity.ttl else { return }
        
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(ttl * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.dismiss(activity.id)
        }
    }

    private func setupExternalObservers() {
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.notchsuperior.activity.post"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let jsonString = notification.object as? String,
                  let data = jsonString.data(using: .utf8),
                  let request = try? JSONDecoder().decode(NSLiveActivityRequestDecodable.self, from: data) else {
                return
            }
            
            let activity = NSThirdPartyActivity(
                id: request.id,
                priority: request.priority,
                ttl: request.ttl,
                title: request.title,
                subtitle: request.subtitle,
                progress: request.progress,
                systemImageName: request.systemImageName,
                customIconColor: request.customIconColor,
                actionLabel: request.actionLabel,
                actionNotificationName: request.actionNotificationName
            )
            self?.post(activity)
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.notchsuperior.activity.dismiss"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let idString = notification.object as? String,
                  let id = UUID(uuidString: idString) else {
                return
            }
            self?.dismiss(id)
        }
    }
}
