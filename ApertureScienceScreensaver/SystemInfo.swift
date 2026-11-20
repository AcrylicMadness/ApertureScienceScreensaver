//
//  SystemInfo.swift
//  ApertureScienceScreensaver
//
//  Small helpers that feed the header and system-info panel: computer
//  name, OS version, uptime, and the live date/time.
//

import Foundation

enum SystemInfo {

    /// These never change during a run, so compute them once.
    static let computerName: String = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    static let username: String = NSUserName()

    static let modelIdentifier: String = {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }()

    static let memoryString: String = {
        let gib = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824
        return String(format: "%.0f GB", gib)
    }()

    static var osVersionString: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        if v.patchVersion > 0 {
            return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        }
        return "macOS \(v.majorVersion).\(v.minorVersion)"
    }

    static func uptimeString() -> String {
        let totalSeconds = Int(ProcessInfo.processInfo.systemUptime)
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    static func dateString(_ date: Date = Date()) -> String {
        dateFormatter.string(from: date)
    }

    static func timeString(_ date: Date = Date()) -> String {
        timeFormatter.string(from: date)
    }
}
