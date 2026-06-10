// ────────────────────────────────────────────────────────
// NotchSuperior — NSThirdPartyActivity.swift
// Phase: 10 — Third-Party Live Activity support
// Created: 2026-06-10
// ────────────────────────────────────────────────────────

import SwiftUI

struct NSThirdPartyActivity: NSActivity {
    let id: UUID
    let priority: Int
    let ttl: TimeInterval?
    
    let title: String
    let subtitle: String?
    let progress: Double?
    let systemImageName: String?
    let customIconColor: String?
    let actionLabel: String?
    let actionNotificationName: String?
    
    var compactView: AnyView {
        AnyView(
            HStack(spacing: 6) {
                if let systemImageName = systemImageName {
                    Image(systemName: systemImageName)
                        .foregroundColor(iconColor)
                        .imageScale(.small)
                }
                
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 40)
                        .tint(iconColor)
                }
            }
        )
    }
    
    var expandedView: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let systemImageName = systemImageName {
                        Image(systemName: systemImageName)
                            .font(.title3)
                            .foregroundColor(iconColor)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
                
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(iconColor)
                }
                
                HStack {
                    Spacer()
                    if let actionLabel = actionLabel {
                        Button(action: {
                            if let actionNotificationName = actionNotificationName {
                                DistributedNotificationCenter.default().postNotificationName(
                                    Notification.Name(actionNotificationName),
                                    object: nil,
                                    userInfo: nil,
                                    deliverImmediately: true
                                )
                            }
                            NSLiveActivityEngine.shared.dismiss(id)
                        }) {
                            Text(actionLabel)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.primary.opacity(0.1)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        )
    }
    
    private var iconColor: Color {
        guard let colorStr = customIconColor?.lowercased() else {
            return .accentColor
        }
        switch colorStr {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "purple": return .purple
        case "pink": return .pink
        case "mint": return .mint
        case "teal": return .teal
        default:
            if colorStr.hasPrefix("#") {
                let hex = colorStr.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                var rgb: UInt64 = 0
                if Scanner(string: hex).scanHexInt64(&rgb) {
                    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
                    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
                    let b = Double(rgb & 0x0000FF) / 255.0
                    return Color(red: r, green: g, blue: b)
                }
            }
            return .accentColor
        }
    }
}

// Local helper Decodable to match the public payload fields from NSExtensionSDK
struct NSLiveActivityRequestDecodable: Codable {
    let id: UUID
    let priority: Int
    let ttl: TimeInterval?
    let title: String
    let subtitle: String?
    let progress: Double?
    let systemImageName: String?
    let customIconColor: String?
    let actionLabel: String?
    let actionNotificationName: String?
}
