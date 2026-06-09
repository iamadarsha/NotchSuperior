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
    
    private init() {}
    
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
}
