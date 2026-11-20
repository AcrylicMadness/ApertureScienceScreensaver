//
//  ScreensaverSettings.swift
//  ApertureScienceScreensaver
//
//  Thin wrapper around ScreenSaverDefaults so the config sheet and the
//  view share one persisted source of truth.
//

import AppKit
import ScreenSaver

enum SettingsKey {
    static let textColorHex = "TextColorHex"
    static let backgroundColorHex = "BackgroundColorHex"
    static let scanlinesEnabled = "ScanlinesEnabled"
    static let flickerEnabled = "FlickerEnabled"
    static let speed = "Speed"
    static let padding = "Padding"
}

final class ScreensaverSettings {

    static let shared = ScreensaverSettings()

    /// Default "Aperture" scheme: warm amber-orange text over a dark, warm background.
    static let defaultTextColorHex = "#FFA53C"
    static let defaultBackgroundColorHex = "#1A0D02"
    static let defaultPadding = 24.0

    private let defaults: ScreenSaverDefaults

    private init() {
        let bundle = Bundle(for: ApertureScienceScreensaverView.self)
        let moduleName = bundle.bundleIdentifier ?? "ApertureScienceScreensaver"
        guard let saverDefaults = ScreenSaverDefaults(forModuleWithName: moduleName) else {
            fatalError("Could not create ScreenSaverDefaults for module \(moduleName)")
        }
        defaults = saverDefaults
        defaults.register(defaults: [
            SettingsKey.textColorHex: Self.defaultTextColorHex,
            SettingsKey.backgroundColorHex: Self.defaultBackgroundColorHex,
            SettingsKey.scanlinesEnabled: true,
            SettingsKey.flickerEnabled: true,
            SettingsKey.speed: 1.0,
            SettingsKey.padding: Self.defaultPadding,
        ])
    }

    var textColor: NSColor {
        get { NSColor(hex: defaults.string(forKey: SettingsKey.textColorHex) ?? Self.defaultTextColorHex) ?? .orange }
        set {
            defaults.set(newValue.hexString, forKey: SettingsKey.textColorHex)
            defaults.synchronize()
        }
    }

    var backgroundColor: NSColor {
        get { NSColor(hex: defaults.string(forKey: SettingsKey.backgroundColorHex) ?? Self.defaultBackgroundColorHex) ?? .black }
        set {
            defaults.set(newValue.hexString, forKey: SettingsKey.backgroundColorHex)
            defaults.synchronize()
        }
    }

    /// Outer screen margin in points, 0...80.
    var padding: Double {
        get {
            defaults.object(forKey: SettingsKey.padding) == nil ? Self.defaultPadding : defaults.double(forKey: SettingsKey.padding)
        }
        set {
            defaults.set(newValue, forKey: SettingsKey.padding)
            defaults.synchronize()
        }
    }

    var scanlinesEnabled: Bool {
        get { defaults.bool(forKey: SettingsKey.scanlinesEnabled) }
        set {
            defaults.set(newValue, forKey: SettingsKey.scanlinesEnabled)
            defaults.synchronize()
        }
    }

    var flickerEnabled: Bool {
        get { defaults.bool(forKey: SettingsKey.flickerEnabled) }
        set {
            defaults.set(newValue, forKey: SettingsKey.flickerEnabled)
            defaults.synchronize()
        }
    }

    /// 0.5 (slow) ... 2.0 (fast), 1.0 = default pace.
    var speed: Double {
        get {
            let value = defaults.double(forKey: SettingsKey.speed)
            return value == 0 ? 1.0 : value
        }
        set {
            defaults.set(newValue, forKey: SettingsKey.speed)
            defaults.synchronize()
        }
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString.removeAll { $0 == "#" }
        guard hexString.count == 6, let value = UInt32(hexString, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }

    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return ScreensaverSettings.defaultTextColorHex }
        let r = Int((rgb.redComponent * 255).rounded())
        let g = Int((rgb.greenComponent * 255).rounded())
        let b = Int((rgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
