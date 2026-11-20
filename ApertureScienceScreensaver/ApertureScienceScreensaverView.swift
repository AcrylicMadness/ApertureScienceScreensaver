//
//  ApertureScienceScreensaverView.swift
//  ApertureScienceScreensaver
//
//  A Portal-credits-style layout: a header bar with the computer's name,
//  a large scrolling terminal log, and a side column with an ASCII Apple
//  logo and a neofetch-style system info panel -- all in a configurable
//  color scheme (default: warm Aperture amber) with a CRT-ish overlay.
//

import ScreenSaver
import AppKit

@objc(ApertureScienceScreensaverView)
class ApertureScienceScreensaverView: ScreenSaverView {

    // MARK: Tuning constants

    /// How quickly a line's animated `row` catches up to its `targetRow` each frame.
    private let rowSmoothing = 0.18
    /// Base seconds between revealed characters (scaled by settings.speed).
    private let baseCharInterval = 0.032
    /// Seconds to pause once a line finishes typing before the next one spawns.
    private let baseLinePauseRange = 0.4...1.1
    private let cursorBlinkInterval = 0.5
    private let logInnerPadding: CGFloat = 10

    private let headerTitle = "SUBSTRATA DYNAMICS TERMINAL"

    // MARK: Log state

    private var lines: [TerminalLine] = []
    private var charRevealAccumulator: Double = 0
    private var linePauseRemaining: Double?
    private var cursorVisible = true
    private var cursorBlinkAccumulator: Double = 0
    private var flickerAlpha: CGFloat = 1.0

    private var cachedLocalIP: String = "..."
    private var networkRefreshCounter = 0
    private let networkRefreshFrames = 150 // ~5s at 30fps

    private var font: NSFont = .monospacedSystemFont(ofSize: 15, weight: .medium)
    private var lineHeight: CGFloat = 20
    private var headerFont: NSFont = .monospacedSystemFont(ofSize: 15, weight: .bold)
    private var infoFont: NSFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
    private lazy var scanlinePattern: NSColor = makeScanlinePattern()

    private var configController: ConfigureSheetController?

    // MARK: Layout

    private struct PanelLayout {
        let header: CGRect
        let log: CGRect
        let ascii: CGRect
        let info: CGRect
        let panelSpacing: CGFloat
    }

    // MARK: Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1 / 30.0
        configureFonts(isPreview: isPreview)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureFonts(isPreview: isPreview)
    }

    private func configureFonts(isPreview: Bool) {
        let size: CGFloat = isPreview ? 6 : 15
        font = .monospacedSystemFont(ofSize: size, weight: .medium)
        lineHeight = ceil(font.ascender - font.descender + font.leading) + (isPreview ? 2 : 6)
        headerFont = .monospacedSystemFont(ofSize: isPreview ? 5 : 16, weight: .bold)
        infoFont = .monospacedSystemFont(ofSize: isPreview ? 4 : 12, weight: .regular)
    }

    // MARK: Animation lifecycle

    override func startAnimation() {
        super.startAnimation()
        if lines.isEmpty {
            spawnLine()
        }
        cachedLocalIP = NetworkInfo.localIPAddress() ?? "N/A"
    }

    override func stopAnimation() {
        super.stopAnimation()
    }

    override func animateOneFrame() {
        let dt = animationTimeInterval
        let settings = ScreensaverSettings.shared
        let speed = max(0.1, settings.speed)

        advanceRowSmoothing()
        advanceTyping(dt: dt, speed: speed)
        advanceCursorBlink(dt: dt)
        advanceFlicker(settings: settings)
        advanceNetworkRefresh()

        needsDisplay = true
    }

    private func advanceNetworkRefresh() {
        networkRefreshCounter += 1
        guard networkRefreshCounter >= networkRefreshFrames else { return }
        networkRefreshCounter = 0
        cachedLocalIP = NetworkInfo.localIPAddress() ?? "N/A"
    }

    private func advanceRowSmoothing() {
        for i in lines.indices {
            let target = Double(lines[i].targetRow)
            lines[i].row += (target - lines[i].row) * rowSmoothing
        }
        // Lines that have fully scrolled up past the top of the log panel
        // (row measured top-down, so negative means above the visible area).
        lines.removeAll { $0.row < -1.5 }
    }

    private func advanceTyping(dt: Double, speed: Double) {
        guard var current = lines.last else { return }

        if !current.isFullyRevealed {
            charRevealAccumulator += dt * speed
            let interval = baseCharInterval
            while charRevealAccumulator >= interval && !current.isFullyRevealed {
                current.revealedCount += 1
                charRevealAccumulator -= interval
            }
            lines[lines.count - 1] = current
            return
        }

        // Line is fully typed: count down the pause before the next one spawns.
        if linePauseRemaining == nil {
            linePauseRemaining = Double.random(in: baseLinePauseRange) / speed
        }
        linePauseRemaining! -= dt
        if linePauseRemaining! <= 0 {
            linePauseRemaining = nil
            charRevealAccumulator = 0
            spawnLine()
        }
    }

    private func advanceCursorBlink(dt: Double) {
        cursorBlinkAccumulator += dt
        if cursorBlinkAccumulator >= cursorBlinkInterval {
            cursorBlinkAccumulator -= cursorBlinkInterval
            cursorVisible.toggle()
        }
    }

    private func advanceFlicker(settings: ScreensaverSettings) {
        guard settings.flickerEnabled else {
            flickerAlpha = 1.0
            return
        }
        flickerAlpha = CGFloat.random(in: 0.92...1.0)
    }

    /// Lines fill the log panel from the top down, one per slot. Only once
    /// the panel is full does a new line push everything up by one row --
    /// i.e. real terminal scrollback behavior, not scrolling from line one.
    private func spawnLine() {
        let maxRows = maxLogRows(for: computeLayout().log)

        if lines.count >= maxRows {
            for i in lines.indices {
                lines[i].targetRow -= 1
            }
        }
        let targetRow = min(lines.count, maxRows - 1)

        let text = Array(TerminalContent.nextLine())
        // Starts one row below its slot and eases up into place, whether
        // that's the next open slot (fill phase) or the bottom slot after
        // a scroll-up shift (scroll phase).
        lines.append(TerminalLine(text: text, targetRow: targetRow, row: Double(targetRow) + 1))
    }

    private func maxLogRows(for logRect: CGRect) -> Int {
        max(1, Int((logRect.height - logInnerPadding * 2) / lineHeight))
    }

    // MARK: Layout computation

    private func computeLayout() -> PanelLayout {
        let padding = CGFloat(ScreensaverSettings.shared.padding)
        let outerMargin: CGFloat = isPreview ? max(2, padding * 0.3) : padding
        let panelSpacing: CGFloat = isPreview ? 4 : 14
        let headerHeight: CGFloat = isPreview ? 10 : 40

        let content = bounds.insetBy(dx: outerMargin, dy: outerMargin)
        let header = CGRect(x: content.minX, y: content.maxY - headerHeight,
                             width: content.width, height: headerHeight)

        let bodyHeight = content.height - headerHeight - panelSpacing
        let body = CGRect(x: content.minX, y: content.minY, width: content.width, height: bodyHeight)

        let rightWidth = (body.width * 0.26).rounded()
        let log = CGRect(x: body.minX, y: body.minY,
                          width: body.width - rightWidth - panelSpacing, height: body.height)
        let rightColumn = CGRect(x: log.maxX + panelSpacing, y: body.minY,
                                  width: rightWidth, height: body.height)

        let asciiHeight = (rightColumn.height * 0.48).rounded()
        let ascii = CGRect(x: rightColumn.minX, y: rightColumn.maxY - asciiHeight,
                            width: rightColumn.width, height: asciiHeight)
        let info = CGRect(x: rightColumn.minX, y: rightColumn.minY,
                           width: rightColumn.width, height: rightColumn.height - asciiHeight - panelSpacing)

        return PanelLayout(header: header, log: log, ascii: ascii, info: info, panelSpacing: panelSpacing)
    }

    // MARK: Drawing

    override func draw(_ rect: NSRect) {
        let settings = ScreensaverSettings.shared
        let baseColor = settings.textColor

        settings.backgroundColor.setFill()
        rect.fill()

        let layout = computeLayout()
        let color = baseColor.withAlphaComponent(flickerAlpha)

        drawHeader(in: layout.header, color: color)
        drawDividers(layout: layout, color: color)
        drawLog(in: layout.log, color: color)
        drawAsciiApple(in: layout.ascii, color: color)
        drawInfo(in: layout.info, color: color)

        if settings.scanlinesEnabled {
            scanlinePattern.setFill()
            rect.fill(using: .sourceOver)
        }
    }

    private func drawHeader(in rect: CGRect, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: color]

        let titleSize = (headerTitle as NSString).size(withAttributes: attrs)
        let y = rect.midY - titleSize.height / 2
        (headerTitle as NSString).draw(at: NSPoint(x: rect.minX, y: y), withAttributes: attrs)

        let host = SystemInfo.computerName.uppercased()
        let hostSize = (host as NSString).size(withAttributes: attrs)
        (host as NSString).draw(at: NSPoint(x: rect.maxX - hostSize.width, y: y), withAttributes: attrs)
    }

    private func drawDividers(layout: PanelLayout, color: NSColor) {
        let dimColor = color.withAlphaComponent(color.alphaComponent * 0.4)
        let half = layout.panelSpacing / 2

        strokeLine(from: CGPoint(x: layout.header.minX, y: layout.header.minY - half),
                   to: CGPoint(x: layout.header.maxX, y: layout.header.minY - half), color: dimColor)

        let vx = layout.log.maxX + half
        strokeLine(from: CGPoint(x: vx, y: layout.log.minY),
                   to: CGPoint(x: vx, y: layout.log.maxY), color: dimColor)

        let hy = layout.ascii.minY - half
        strokeLine(from: CGPoint(x: layout.ascii.minX, y: hy),
                   to: CGPoint(x: layout.ascii.maxX, y: hy), color: dimColor)
    }

    private func strokeLine(from p1: CGPoint, to p2: CGPoint, color: NSColor) {
        let path = NSBezierPath()
        path.move(to: p1)
        path.line(to: p2)
        path.lineWidth = 1
        color.setStroke()
        path.stroke()
    }

    private func drawLog(in rect: CGRect, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]

        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: rect).addClip()

        let topY = rect.maxY - logInnerPadding
        let leftX = rect.minX + logInnerPadding

        for (index, line) in lines.enumerated() {
            let y = topY - (CGFloat(line.row) + 1) * lineHeight
            if y > rect.maxY || y < rect.minY - lineHeight { continue }

            let string = line.revealedText
            (string as NSString).draw(at: NSPoint(x: leftX, y: y), withAttributes: attributes)

            if index == lines.count - 1 && cursorVisible {
                let width = (string as NSString).size(withAttributes: attributes).width
                let cursorRect = NSRect(x: leftX + width + 2, y: y,
                                         width: font.pointSize * 0.55, height: lineHeight * 0.75)
                color.setFill()
                cursorRect.fill()
            }
        }

        NSGraphicsContext.restoreGraphicsState()
    }

    /// Renders the neofetch-style Apple ASCII art, scaled to fit the panel.
    ///
    /// Every line shares one left margin (monospaced grid column 0) rather
    /// than being centered individually -- each line's leading spaces are
    /// significant and encode its offset from that shared origin. Centering
    /// per line instead of as one block breaks that relative alignment and
    /// visibly skews the shape.
    private func drawAsciiApple(in rect: CGRect, color: NSColor) {
        let art = AsciiArt.appleLogo
        guard !art.isEmpty else { return }
        let longestChars = art.map { $0.count }.max() ?? 1

        func charWidth(_ f: NSFont) -> CGFloat {
            ("M" as NSString).size(withAttributes: [.font: f]).width
        }
        func lineHeightFor(_ f: NSFont) -> CGFloat {
            ceil(f.ascender - f.descender + f.leading)
        }

        var chosenFont = NSFont.monospacedSystemFont(ofSize: 3, weight: .regular)
        var size: CGFloat = 3
        while size < 200 {
            let candidate = NSFont.monospacedSystemFont(ofSize: size + 0.5, weight: .regular)
            let w = charWidth(candidate) * CGFloat(longestChars)
            let h = lineHeightFor(candidate) * CGFloat(art.count)
            if w > rect.width * 0.92 || h > rect.height * 0.92 { break }
            size += 0.5
            chosenFont = candidate
        }

        let attrs: [NSAttributedString.Key: Any] = [.font: chosenFont, .foregroundColor: color]
        let lh = lineHeightFor(chosenFont)
        let blockWidth = charWidth(chosenFont) * CGFloat(longestChars)
        let totalHeight = lh * CGFloat(art.count)

        let blockLeftX = rect.midX - blockWidth / 2
        var y = rect.midY + totalHeight / 2 - lh

        for line in art {
            (line as NSString).draw(at: NSPoint(x: blockLeftX, y: y), withAttributes: attrs)
            y -= lh
        }
    }

    private var resolutionString: String {
        let screen = window?.screen ?? NSScreen.main
        guard let frame = screen?.frame else { return "-" }
        let scale = screen?.backingScaleFactor ?? 1
        return "\(Int(frame.width * scale))x\(Int(frame.height * scale))"
    }

    private func drawInfo(in rect: CGRect, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: infoFont, .foregroundColor: color]
        let entryHeight = ceil(infoFont.ascender - infoFont.descender + infoFont.leading) + 4

        let header = "\(SystemInfo.username)@\(SystemInfo.computerName)"
        let entries = [
            header,
            String(repeating: "-", count: min(32, header.count)),
            "OS: \(SystemInfo.osVersionString)",
            "HOST: \(SystemInfo.modelIdentifier)",
            "UPTIME: \(SystemInfo.uptimeString())",
            "DATE: \(SystemInfo.dateString())",
            "TIME: \(SystemInfo.timeString())",
            "RESOLUTION: \(resolutionString)",
            "MEMORY: \(SystemInfo.memoryString)",
            "LOCAL IP: \(cachedLocalIP)",
        ]

        var y = rect.maxY - entryHeight
        for entry in entries {
            (entry as NSString).draw(at: NSPoint(x: rect.minX, y: y), withAttributes: attrs)
            y -= entryHeight
            if y < rect.minY { break }
        }
    }

    private func makeScanlinePattern() -> NSColor {
        let patternSize = NSSize(width: 1, height: 3)
        let image = NSImage(size: patternSize)
        image.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: patternSize).fill()
        NSColor.black.withAlphaComponent(0.18).setFill()
        NSRect(x: 0, y: 0, width: 1, height: 1).fill()
        image.unlockFocus()
        return NSColor(patternImage: image)
    }

    // MARK: Configure sheet

    override var hasConfigureSheet: Bool {
        true
    }

    override var configureSheet: NSWindow? {
        let controller = ConfigureSheetController()
        configController = controller
        return controller.window
    }
}
