//
//  TerminalLog.swift
//  ApertureScienceScreensaver
//
//  Model for a single scrolling terminal line and the fictional
//  "Substrata Dynamics" flavor-text generator that feeds it.
//

import Foundation

/// One line of terminal output, mid-flight through its typewriter reveal
/// and its slide into its settled scroll position.
struct TerminalLine {
    let text: [Character]
    var revealedCount: Int = 0
    /// Row index counted up from the bottom of the view (0 = newest/bottom row).
    var targetRow: Int
    /// Smoothed, animated row position that eases toward `targetRow` every frame.
    var row: Double = -1

    var isFullyRevealed: Bool { revealedCount >= text.count }

    var revealedText: String {
        String(text[0..<revealedCount])
    }
}

/// Generates original, non-trademarked "dry corporate research facility"
/// flavor text in the spirit of a Portal-style terminal, without reusing
/// any actual game dialogue, character names, or brand names.
enum TerminalContent {

    private static let subsystems = [
        "NUTRIENT PASTE EXTRUDER", "GANTRY ARRAY", "OPTICAL TRACKING GRID",
        "THERMAL DISCOURAGEMENT COIL", "STRUCTURAL INTEGRITY MESH",
        "ATMOSPHERIC SCRUBBER", "REDUNDANT MAINFRAME", "CENTRIFUGAL BALLAST",
        "VOICE SYNTHESIS MODULE", "SUBJECT TELEMETRY RELAY",
        "PNEUMATIC DIVERTER", "BACKUP POWER CELL", "CORE COOLANT LOOP",
        "SAFETY INTERLOCK ARRAY", "MOTION DAMPENING FIELD",
        "ELEVATOR CONTROL LOGIC", "SIGNAGE PROJECTION UNIT",
        "WASTE RECLAMATION LINE", "SECONDARY OBSERVATION LENS",
    ]

    private static let statuses = [
        "OK", "NOMINAL", "ONLINE", "STABLE", "WITHIN TOLERANCE",
    ]

    private static let warnStatuses = [
        "DEGRADED", "RECALIBRATING", "PENDING REVIEW", "UNVERIFIED",
    ]

    private static let staticLines = [
        "SUBSTRATA DYNAMICS RESEARCH DIVISION",
        "DEEP TESTING FACILITY 9 -- SUBLEVEL ACCESS TERMINAL",
        "> BOOT SEQUENCE INITIATED",
        "> LOADING FACILITY CONFIGURATION ................ DONE",
        "> MOUNTING SUBJECT RECORD ARCHIVE ................ DONE",
        "> ESTABLISHING UPLINK TO CENTRAL OVERSIGHT ....... DONE",
        "AUTOMATED TESTING PROTOCOL 7 IS NOW IN EFFECT",
        "REMINDER: HARD HATS ARE MANDATORY IN ALL TEST CHAMBERS",
        "REMINDER: HARD HATS ARE COSMETIC AND OFFER NO PROTECTION",
        "EMPLOYEE MORALE SURVEY RESULTS: INCONCLUSIVE",
        "EMPLOYEE MORALE SURVEY RESULTS: WITHHELD PENDING REVIEW",
        "TEST SUBJECT COMPLIANCE RATING: WITHIN EXPECTED PARAMETERS",
        "SECTOR 12 CHAMBER 004 SEALED FOR MAINTENANCE",
        "SECTOR 12 CHAMBER 004 REOPENED -- HAZARDS UNRESOLVED",
        "SCHEDULED INCINERATION OF OBSOLETE RECORDS: DEFERRED AGAIN",
        "NOTICE: THE OBSERVATION DECK IS NOT, IN FACT, SOUNDPROOF",
        "ANNUAL SAFETY AWARD: NO ELIGIBLE RECIPIENTS THIS CYCLE",
        "VISITOR LOG: NO VISITORS ON RECORD SINCE FACILITY SEALING",
        "CAFETERIA NOTICE: PASTE DISPENSERS RESTOCKED, FLAVOR PENDING",
        "INTERNAL MEMO: PLEASE STOP RENAMING THE BACKUP GENERATOR",
        "INTERNAL MEMO: THE GENERATOR'S NAME IS FINAL THIS TIME",
        "LONG-TERM STORAGE: HUMIDITY WITHIN ACCEPTABLE RANGE",
        "PERSONNEL ROSTER LAST UPDATED: UNKNOWN",
        "LEGAL HAS BEEN NOTIFIED. LEGAL HAS NOT RESPONDED.",
        "QUARTERLY REPORT SUBMITTED TO AN AUDIENCE OF NONE",
        "> RUNNING DIAGNOSTIC SWEEP",
        "> NO ANOMALIES DETECTED THAT WEREN'T ALREADY LOGGED",
        "STANDBY FOR ADMINISTRATOR OVERRIDE",
        "OVERRIDE NOT RECEIVED. RESUMING AUTOMATED OPERATION.",
        "WHOEVER IS READING THIS: THE COFFEE MACHINE IS STILL BROKEN",
    ]

    /// Returns the next line of content, mixing static flavor lines with
    /// procedurally generated subsystem status reports for long-run variety.
    static func nextLine() -> String {
        if Bool.random() {
            return staticLines.randomElement()!
        }
        let subsystem = subsystems.randomElement()!
        let percent = Int.random(in: 0...100)
        let useWarn = percent < 15
        let status = useWarn ? warnStatuses.randomElement()! : statuses.randomElement()!
        let dots = String(repeating: ".", count: max(1, 28 - subsystem.count))
        if percent < 100 && Bool.random() {
            return "> \(subsystem) \(dots) \(percent)%"
        }
        return "> \(subsystem) \(dots) [\(status)]"
    }
}
