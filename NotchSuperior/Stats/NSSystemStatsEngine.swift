// ────────────────────────────────────────────────────────
// NotchSuperior — NSSystemStatsEngine.swift
// Part of the boring.notch fork
// Phase: 11 — System Stats (CPU · RAM · Network · Disk)
// Created: 2026-06-15
// NOTCHSUPERIOR ADDITION
// API-key free. Uses only Darwin/IOKit system calls.
// ────────────────────────────────────────────────────────

import Foundation
import Darwin
import IOKit.ps

@MainActor
final class NSSystemStatsEngine: ObservableObject {
    static let shared = NSSystemStatsEngine()

    // MARK: - Published state
    @Published var cpuUsage: Double = 0            // 0–1
    @Published var cpuHistory: [Double] = Array(repeating: 0, count: 30)

    @Published var ramUsedGB: Double = 0
    @Published var ramTotalGB: Double = 1
    @Published var ramHistory: [Double] = Array(repeating: 0, count: 30)

    @Published var downloadSpeedMB: Double = 0     // MB/s
    @Published var uploadSpeedMB: Double = 0       // MB/s
    @Published var netDownHistory: [Double] = Array(repeating: 0, count: 30)
    @Published var netUpHistory: [Double] = Array(repeating: 0, count: 30)

    @Published var diskUsedGB: Double = 0
    @Published var diskTotalGB: Double = 1
    @Published var diskHistory: [Double] = Array(repeating: 0, count: 30)

    @Published var batteryPercent: Int = 0
    @Published var isCharging: Bool = false
    @Published var batteryTimeRemainingMin: Int = -1  // -1 = calculating

    // MARK: - Private state
    private var timer: Timer?
    private var retainCount = 0
    private var prevCPUInfo: processor_info_array_t?
    private var prevCPUInfoCount: mach_msg_type_number_t = 0
    private var prevNumCPUs: natural_t = 0
    private var prevBytesIn: UInt64 = 0
    private var prevBytesOut: UInt64 = 0
    private var prevTimestamp: Date = Date()

    private init() {
        // Pre-warm: take an initial network snapshot so first reading is accurate
        (prevBytesIn, prevBytesOut) = rawNetworkBytes()
        prevTimestamp = Date()
        // Pre-read total RAM once (it never changes)
        ramTotalGB = totalRAMGB()
    }

    // MARK: - Lifecycle

    func startMonitoring() {
        retainCount += 1
        guard timer == nil else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func stopMonitoring() {
        retainCount = max(0, retainCount - 1)
        guard retainCount == 0 else { return }
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Core refresh

    private func refresh() {
        let cpu = readCPUUsage()
        cpuUsage = cpu
        cpuHistory = Array(cpuHistory.dropFirst()) + [cpu]

        let (used, total) = readRAMUsage()
        ramUsedGB = used
        if total > 0 { ramTotalGB = total }
        let ramFraction = ramTotalGB > 0 ? ramUsedGB / ramTotalGB : 0
        ramHistory = Array(ramHistory.dropFirst()) + [ramFraction]

        let (dlMB, ulMB) = readNetworkSpeed()
        downloadSpeedMB = dlMB
        uploadSpeedMB = ulMB
        // Normalize history to a reasonable max (50 MB/s cap for chart scaling)
        netDownHistory = Array(netDownHistory.dropFirst()) + [min(dlMB / 50.0, 1.0)]
        netUpHistory   = Array(netUpHistory.dropFirst())   + [min(ulMB / 50.0, 1.0)]

        let (dUsed, dTotal) = readDiskUsage()
        diskUsedGB = dUsed
        diskTotalGB = dTotal > 0 ? dTotal : diskTotalGB
        let diskFraction = diskTotalGB > 0 ? diskUsedGB / diskTotalGB : 0
        diskHistory = Array(diskHistory.dropFirst()) + [diskFraction]

        let (pct, charging, mins) = readBattery()
        batteryPercent = pct
        isCharging = charging
        batteryTimeRemainingMin = mins
    }

    // MARK: - CPU

    private func readCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO,
            &numCPUs, &cpuInfo, &numCPUInfo
        )
        guard result == KERN_SUCCESS, let info = cpuInfo else { return cpuUsage }

        var totalUsage: Double = 0
        let stateMax = Int(CPU_STATE_MAX)

        for i in 0..<Int(numCPUs) {
            let base = stateMax * i
            let user   = Int32(info[base + Int(CPU_STATE_USER)])
            let system = Int32(info[base + Int(CPU_STATE_SYSTEM)])
            let nice   = Int32(info[base + Int(CPU_STATE_NICE)])
            let idle   = Int32(info[base + Int(CPU_STATE_IDLE)])

            var inUse  = user + system + nice
            var total  = inUse + idle

            if let prev = prevCPUInfo {
                let pb     = stateMax * i
                let pu     = Int32(prev[pb + Int(CPU_STATE_USER)])
                let ps     = Int32(prev[pb + Int(CPU_STATE_SYSTEM)])
                let pn     = Int32(prev[pb + Int(CPU_STATE_NICE)])
                let pi     = Int32(prev[pb + Int(CPU_STATE_IDLE)])
                inUse = (user - pu) + (system - ps) + (nice - pn)
                total = inUse + (idle - pi)
            }

            if total > 0 {
                totalUsage += Double(max(0, inUse)) / Double(total)
            }
        }

        // Release previous buffer
        if let prev = prevCPUInfo {
            let size = vm_size_t(prevCPUInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prev), size)
        }
        prevCPUInfo = cpuInfo
        prevCPUInfoCount = numCPUInfo
        prevNumCPUs = numCPUs

        return numCPUs > 0 ? min(1.0, totalUsage / Double(numCPUs)) : cpuUsage
    }

    // MARK: - RAM

    private func totalRAMGB() -> Double {
        var info = host_basic_info()
        var count = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &count)
            }
        }
        return r == KERN_SUCCESS ? Double(info.max_mem) / 1_073_741_824 : 0
    }

    private func readRAMUsage() -> (Double, Double) {
        var stats = vm_statistics64()
        var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard r == KERN_SUCCESS else { return (ramUsedGB, ramTotalGB) }

        let page = Double(vm_page_size)
        let active      = Double(stats.active_count)      * page
        let speculative = Double(stats.speculative_count) * page
        let inactive    = Double(stats.inactive_count)    * page
        let wired       = Double(stats.wire_count)        * page
        let compressed  = Double(stats.compressor_page_count) * page
        let purgeable   = Double(stats.purgeable_count)   * page
        let external    = Double(stats.external_page_count) * page

        let used = max(0, active + speculative + inactive + wired + compressed - purgeable - external)
        return (used / 1_073_741_824, ramTotalGB)
    }

    // MARK: - Network

    private func rawNetworkBytes() -> (UInt64, UInt64) {
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPtr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddrsPtr) }
        var ptr = ifaddrsPtr
        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }
            guard let addr = current.pointee.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            let name = String(cString: current.pointee.ifa_name)
            // Only real physical interfaces (en0, en1, etc. + any Wi-Fi/Ethernet)
            guard name.hasPrefix("en") else { continue }
            if let data = current.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalIn  += UInt64(data.pointee.ifi_ibytes)
                totalOut += UInt64(data.pointee.ifi_obytes)
            }
        }
        return (totalIn, totalOut)
    }

    private func readNetworkSpeed() -> (Double, Double) {
        let (bytesIn, bytesOut) = rawNetworkBytes()
        let now = Date()
        let elapsed = max(now.timeIntervalSince(prevTimestamp), 0.1)

        let deltaIn  = bytesIn  >= prevBytesIn  ? bytesIn  - prevBytesIn  : 0
        let deltaOut = bytesOut >= prevBytesOut ? bytesOut - prevBytesOut : 0

        prevBytesIn  = bytesIn
        prevBytesOut = bytesOut
        prevTimestamp = now

        return (Double(deltaIn) / elapsed / 1_048_576,
                Double(deltaOut) / elapsed / 1_048_576)
    }

    // MARK: - Disk

    private func readDiskUsage() -> (Double, Double) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/") else {
            return (diskUsedGB, diskTotalGB)
        }
        let total = attrs[.systemSize]  as? Int64 ?? 0
        let free  = attrs[.systemFreeSize] as? Int64 ?? 0
        let gb: Double = 1_073_741_824
        return (Double(total - free) / gb, Double(total) / gb)
    }

    // MARK: - Battery (IOKit.ps — no entitlement needed)

    private func readBattery() -> (Int, Bool, Int) {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources  = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        guard let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)
                  .takeUnretainedValue() as? [String: AnyObject] else {
            return (batteryPercent, isCharging, batteryTimeRemainingMin)
        }
        let pct      = info[kIOPSCurrentCapacityKey] as? Int ?? batteryPercent
        let charging = (info[kIOPSIsChargingKey] as? Bool) == true
        let timeKey  = charging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        let mins     = info[timeKey] as? Int ?? -1
        return (pct, charging, mins)
    }

    // MARK: - Helpers

    static func formatBytes(_ mb: Double) -> String {
        if mb >= 1024 { return String(format: "%.1f GB/s", mb / 1024) }
        if mb >= 1    { return String(format: "%.1f MB/s", mb) }
        return String(format: "%.0f KB/s", mb * 1024)
    }
}
