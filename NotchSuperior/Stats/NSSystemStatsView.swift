// ────────────────────────────────────────────────────────
// NotchSuperior — NSSystemStatsView.swift
// Part of the boring.notch fork
// Phase: 11 — System Stats (CPU · RAM · Network · Disk · Battery)
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// API-key free. Uses only Darwin/IOKit system calls.
// ────────────────────────────────────────────────────────

import SwiftUI

@available(macOS 14.0, *)
struct NSSystemStatsView: View {
    @ObservedObject var engine = NSSystemStatsEngine.shared

    var body: some View {
        HStack(spacing: 6) {
            StatCard(
                title: "CPU",
                valueText: String(format: "%.0f%%", engine.cpuUsage * 100),
                history: engine.cpuHistory,
                color: cpuColor(engine.cpuUsage),
                icon: "cpu"
            )
            StatCard(
                title: "RAM",
                valueText: String(format: "%.1f/%.0fG", engine.ramUsedGB, engine.ramTotalGB),
                history: engine.ramHistory,
                color: .blue,
                icon: "memorychip"
            )
            NetworkCard(engine: engine)
            StatCard(
                title: "DISK",
                valueText: String(format: "%.0f/%.0fG", engine.diskUsedGB, engine.diskTotalGB),
                history: engine.diskHistory,
                color: .purple,
                icon: "internaldrive"
            )
            BatteryCard(engine: engine)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
    private var fraction: Double { history.last ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text(valueText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

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
            .frame(height: 4)

            if history.count > 1 {
                SparklineView(data: history, color: color)
                    .frame(height: 36)
            }
        }
        .padding(9)
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

// MARK: - Network Card

@available(macOS 14.0, *)
private struct NetworkCard: View {
    @ObservedObject var engine: NSSystemStatsEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: "network")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("NET")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.cyan)
                    Text(NSSystemStatsEngine.formatBytes(engine.downloadSpeedMB))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                        .foregroundStyle(.orange)
                    Text(NSSystemStatsEngine.formatBytes(engine.uploadSpeedMB))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }

            SparklineView(data: engine.netDownHistory, color: .cyan)
                .frame(height: 36)
        }
        .padding(9)
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

// MARK: - Battery Card

@available(macOS 14.0, *)
private struct BatteryCard: View {
    @ObservedObject var engine: NSSystemStatsEngine

    private var batteryColor: Color {
        if engine.isCharging { return .green }
        switch engine.batteryPercent {
        case 0..<20: return .red
        case 20..<40: return .orange
        default:     return .green
        }
    }

    private var timeString: String {
        let mins = engine.batteryTimeRemainingMin
        guard mins > 0 else { return engine.isCharging ? "Charging" : "Calculating…" }
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(mins)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: engine.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(batteryColor)
                Text("BATT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text("\(engine.batteryPercent)%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(batteryColor.opacity(0.18))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(colors: [batteryColor.opacity(0.9), batteryColor],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * Double(engine.batteryPercent) / 100.0)
                        .animation(.smooth(duration: 0.6), value: engine.batteryPercent)
                }
            }
            .frame(height: 4)

            Spacer(minLength: 0)

            Text(timeString)
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(9)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(batteryColor.opacity(0.15), lineWidth: 1)
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
