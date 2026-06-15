// ────────────────────────────────────────────────────────
// NotchSuperior — NSSystemStatsView.swift
// Part of the boring.notch fork
// Phase: 11 — System Stats Tab
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// Fits within openNotchSize (640×190pt).
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSSystemStatsView: View {
    @ObservedObject var engine = NSSystemStatsEngine.shared

    var body: some View {
        HStack(spacing: 8) {
            StatCard(
                title: "CPU",
                valueText: String(format: "%.0f%%", engine.cpuUsage * 100),
                history: engine.cpuHistory,
                color: cpuColor(engine.cpuUsage),
                icon: "cpu"
            )
            StatCard(
                title: "RAM",
                valueText: String(format: "%.1f / %.0f GB", engine.ramUsedGB, engine.ramTotalGB),
                history: engine.ramHistory,
                color: .blue,
                icon: "memorychip"
            )
            NetworkCard(engine: engine)
            StatCard(
                title: "Disk",
                valueText: String(format: "%.0f / %.0f GB", engine.diskUsedGB, engine.diskTotalGB),
                history: [engine.diskTotalGB > 0 ? engine.diskUsedGB / engine.diskTotalGB : 0],
                color: .purple,
                icon: "internaldrive",
                showSparkline: false
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: 640, maxHeight: 190)
        .onAppear { engine.startMonitoring() }
        .onDisappear { engine.stopMonitoring() }
    }

    private func cpuColor(_ usage: Double) -> Color {
        switch usage {
        case ..<0.5: return .green
        case ..<0.8: return .yellow
        default:     return .red
        }
    }
}

// MARK: - Stat Card

@available(macOS 14.0, *)
private struct StatCard: View {
    let title: String
    let valueText: String
    let history: [Double]
    let color: Color
    let icon: String
    var showSparkline: Bool = true

    private var fraction: Double { history.last ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            // Value
            Text(valueText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.18))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(colors: [color.opacity(0.9), color],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * min(1, max(0, fraction)))
                        .animation(.smooth(duration: 0.6), value: fraction)
                }
            }
            .frame(height: 5)

            // Sparkline
            if showSparkline && history.count > 1 {
                SparklineView(data: history, color: color)
                    .frame(height: 40)
            } else if !showSparkline {
                // Show byte labels instead
                Text(String(format: "%.0f GB used", history.first.map { $0 } ?? 0))
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(height: 40, alignment: .top)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Network Card (special — shows up + down)

@available(macOS 14.0, *)
private struct NetworkCard: View {
    @ObservedObject var engine: NSSystemStatsEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("NET")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 9))
                        .foregroundStyle(.cyan)
                    Text(NSSystemStatsEngine.formatBytes(engine.downloadSpeedMB))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                    Text(NSSystemStatsEngine.formatBytes(engine.uploadSpeedMB))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            // Download sparkline
            SparklineView(data: engine.netDownHistory, color: .cyan)
                .frame(height: 40)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Sparkline

private struct SparklineView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let points = normalised(data, in: geo.size)
            Path { path in
                guard points.count > 1 else { return }
                path.move(to: points[0])
                for pt in points.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

            // Fill under the line
            Path { path in
                guard points.count > 1 else { return }
                path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                for pt in points {
                    path.addLine(to: pt)
                }
                path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.35), color.opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                )
            )
        }
    }

    private func normalised(_ data: [Double], in size: CGSize) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let maxVal = max(data.max() ?? 1, 0.01)
        let step = size.width / CGFloat(max(data.count - 1, 1))
        return data.enumerated().map { i, v in
            CGPoint(
                x: CGFloat(i) * step,
                y: size.height - size.height * CGFloat(min(v / maxVal, 1.0))
            )
        }
    }
}
