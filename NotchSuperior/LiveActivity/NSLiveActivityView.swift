// ────────────────────────────────────────────────────────
// NotchSuperior — NSLiveActivityView.swift
// Part of the boring.notch fork
// Phase: 2 — Live Activity View
// Created: 2026-06-09
// NOTCHSUPERIOR ADDITION
// ────────────────────────────────────────────────────────

import SwiftUI

struct GlassEffectContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

@available(macOS 26.0, *)
@MainActor
struct NSLiveActivityView: View {
    @ObservedObject var engine = NSLiveActivityEngine.shared
    @Namespace var ns
    @State private var isExpanded = false

    var body: some View {
        Group {
            if let activity = engine.currentActivity {
                activityContent(activity)
            }
        }
        .animation(NSTokens.animationSpring, value: engine.currentActivity?.id)
        .onChange(of: engine.currentActivity?.id) { _, _ in
            withAnimation(NSTokens.animationSpring) {
                isExpanded = false
            }
        }
    }

    @ViewBuilder
    private func activityContent(_ activity: any NSActivity) -> some View {
        GlassEffectContainer {
            VStack(spacing: 0) {
                if isExpanded {
                    activity.expandedView
                        .matchedGeometryEffect(id: "activity_expanded", in: ns)
                        .transition(.opacity)
                } else {
                    activity.compactView
                        .matchedGeometryEffect(id: "activity_compact", in: ns)
                        .transition(.opacity)
                        .padding(.horizontal, 12)
                        .frame(height: 20)
                }
            }
        }
        .notchGlass()
        .contentShape(RoundedRectangle(cornerRadius: NSTokens.notchExpandedRadius, style: .continuous))
        .onTapGesture {
            withAnimation(NSTokens.animationSpring) {
                isExpanded.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -30 {
                        withAnimation(NSTokens.animationSpring) {
                            engine.dismiss(activity.id)
                        }
                    }
                }
        )
    }
}
