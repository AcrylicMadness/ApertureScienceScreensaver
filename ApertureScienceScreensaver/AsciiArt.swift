//
//  AsciiArt.swift
//  ApertureScienceScreensaver
//
//  Apple logo ASCII art, in the style of neofetch's classic macOS/Darwin
//  logo, for the side panel's "neofetch" look.
//

enum AsciiArt {
    /// Byte-exact transcription of neofetch's "mac"/"Darwin" ascii_distro
    /// art (MIT licensed), minus its `${cN}` color tokens -- the leading
    /// whitespace on each line is significant (it's what tapers the
    /// silhouette), so don't reformat/re-indent these.
    static let appleLogo: [String] = [
        "                    c.'",
        "                 ,xNMM.",
        "               .OMMMMo",
        "               lMM\"",
        "     .;loddo:.  .olloddol;.",
        "   cKMMMMMMMMMMNWMMMMMMMMMM0:",
        " .KMMMMMMMMMMMMMMMMMMMMMMMWd.",
        " XMMMMMMMMMMMMMMMMMMMMMMMX.",
        ";MMMMMMMMMMMMMMMMMMMMMMMM:",
        ":MMMMMMMMMMMMMMMMMMMMMMMM:",
        ".MMMMMMMMMMMMMMMMMMMMMMMMX.",
        " kMMMMMMMMMMMMMMMMMMMMMMMMWd.",
        " 'XMMMMMMMMMMMMMMMMMMMMMMMMMMk",
        "  'XMMMMMMMMMMMMMMMMMMMMMMMMK.",
        "    kMMMMMMMMMMMMMMMMMMMMMMd",
        "     ;KMMMMMMMWXXWMMMMMMMk.",
        "       \"cooc*\"    \"*coo'\"",
    ]
}
