//
//  ConfigureSheetController.swift
//  ApertureScienceScreensaver
//
//  Minimal "Screen Saver Options..." sheet: text/background color,
//  padding, speed, and scanline/flicker toggles, all backed by
//  ScreensaverSettings.
//

import AppKit

final class ConfigureSheetController: NSObject {

    let window: NSWindow

    private let textColorWell = NSColorWell(frame: NSRect(x: 160, y: 300, width: 60, height: 24))
    private let backgroundColorWell = NSColorWell(frame: NSRect(x: 160, y: 265, width: 60, height: 24))
    private let paddingSlider = NSSlider(value: 24, minValue: 0, maxValue: 80, target: nil, action: nil)
    private let speedSlider = NSSlider(value: 1.0, minValue: 0.5, maxValue: 2.0, target: nil, action: nil)
    private let scanlinesCheckbox = NSButton(checkboxWithTitle: "Scanlines", target: nil, action: nil)
    private let flickerCheckbox = NSButton(checkboxWithTitle: "Flicker", target: nil, action: nil)

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 380),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        super.init()
        buildUI()
        loadFromSettings()
    }

    private func label(_ text: String, frame: NSRect) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.frame = frame
        field.alignment = .right
        return field
    }

    private func buildUI() {
        window.title = "Aperture Terminal Options"
        let content = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 380))

        let titleLabel = NSTextField(labelWithString: "Substrata Dynamics Terminal")
        titleLabel.frame = NSRect(x: 20, y: 340, width: 320, height: 24)
        titleLabel.font = .boldSystemFont(ofSize: 15)
        content.addSubview(titleLabel)

        content.addSubview(label("Text Color:", frame: NSRect(x: 20, y: 300, width: 130, height: 24)))
        textColorWell.target = self
        textColorWell.action = #selector(textColorChanged(_:))
        content.addSubview(textColorWell)

        content.addSubview(label("Background Color:", frame: NSRect(x: 20, y: 265, width: 130, height: 24)))
        backgroundColorWell.target = self
        backgroundColorWell.action = #selector(backgroundColorChanged(_:))
        content.addSubview(backgroundColorWell)

        content.addSubview(label("Padding:", frame: NSRect(x: 20, y: 225, width: 130, height: 24)))
        paddingSlider.frame = NSRect(x: 160, y: 225, width: 170, height: 24)
        paddingSlider.target = self
        paddingSlider.action = #selector(paddingChanged(_:))
        content.addSubview(paddingSlider)

        content.addSubview(label("Speed:", frame: NSRect(x: 20, y: 185, width: 130, height: 24)))
        speedSlider.frame = NSRect(x: 160, y: 185, width: 170, height: 24)
        speedSlider.target = self
        speedSlider.action = #selector(speedChanged(_:))
        content.addSubview(speedSlider)

        scanlinesCheckbox.frame = NSRect(x: 160, y: 145, width: 170, height: 24)
        scanlinesCheckbox.target = self
        scanlinesCheckbox.action = #selector(scanlinesChanged(_:))
        content.addSubview(scanlinesCheckbox)

        flickerCheckbox.frame = NSRect(x: 160, y: 110, width: 170, height: 24)
        flickerCheckbox.target = self
        flickerCheckbox.action = #selector(flickerChanged(_:))
        content.addSubview(flickerCheckbox)

        let doneButton = NSButton(title: "Done", target: self, action: #selector(done(_:)))
        doneButton.frame = NSRect(x: 260, y: 20, width: 80, height: 32)
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"
        content.addSubview(doneButton)

        window.contentView = content
    }

    private func loadFromSettings() {
        let settings = ScreensaverSettings.shared
        textColorWell.color = settings.textColor
        backgroundColorWell.color = settings.backgroundColor
        paddingSlider.doubleValue = settings.padding
        speedSlider.doubleValue = settings.speed
        scanlinesCheckbox.state = settings.scanlinesEnabled ? .on : .off
        flickerCheckbox.state = settings.flickerEnabled ? .on : .off
    }

    @objc private func textColorChanged(_ sender: NSColorWell) {
        ScreensaverSettings.shared.textColor = sender.color
    }

    @objc private func backgroundColorChanged(_ sender: NSColorWell) {
        ScreensaverSettings.shared.backgroundColor = sender.color
    }

    @objc private func paddingChanged(_ sender: NSSlider) {
        ScreensaverSettings.shared.padding = sender.doubleValue
    }

    @objc private func speedChanged(_ sender: NSSlider) {
        ScreensaverSettings.shared.speed = sender.doubleValue
    }

    @objc private func scanlinesChanged(_ sender: NSButton) {
        ScreensaverSettings.shared.scanlinesEnabled = sender.state == .on
    }

    @objc private func flickerChanged(_ sender: NSButton) {
        ScreensaverSettings.shared.flickerEnabled = sender.state == .on
    }

    @objc private func done(_ sender: NSButton) {
        window.sheetParent?.endSheet(window)
    }
}
