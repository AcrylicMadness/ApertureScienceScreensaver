//
//  NetworkInfo.swift
//  ApertureScienceScreensaver
//
//  Looks up the local IPv4 address for the info panel's neofetch-style
//  network line, preferring en0.
//

import Foundation

enum NetworkInfo {

    static func localIPAddress() -> String? {
        var result: String?

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = ptr {
            defer { ptr = current.pointee.ifa_next }
            let interface = current.pointee

            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name.hasPrefix("en") else { continue }

            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let addrLen = socklen_t(interface.ifa_addr.pointee.sa_len)
            getnameinfo(interface.ifa_addr, addrLen, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST)
            let address = String(cString: hostBuffer)

            // Prefer en0 (typically Wi-Fi/primary), but keep the first
            // match as a fallback in case en0 has no IPv4 address.
            if name == "en0" {
                return address
            }
            if result == nil {
                result = address
            }
        }
        return result
    }
}
