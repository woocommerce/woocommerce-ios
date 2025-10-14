import Foundation
import GameController
import WooFoundation

/// Parses GameController keyboard input into barcode scans.
/// This class handles the core logic for interpreting GameController GCKeyCode input as barcode data,
/// providing language-independent barcode scanning by bypassing iOS keyboard layout processing.
final class GameControllerBarcodeParser {
    /// Configuration for the barcode scanner
    let configuration: HIDBarcodeParserConfiguration
    /// Callback that is triggered when a barcode scan completes (success or failure)
    let onScan: (HIDBarcodeParserResult) -> Void

    private let timeProvider: TimeProvider

    private var buffer = ""
    private var lastKeyPressTime: Date?
    private var scanStartTime: Date?
    private var timeoutTimer: Timer?

    init(configuration: HIDBarcodeParserConfiguration,
         onScan: @escaping (HIDBarcodeParserResult) -> Void,
         timeProvider: TimeProvider = DefaultTimeProvider()) {
        self.configuration = configuration
        self.onScan = onScan
        self.timeProvider = timeProvider
    }

    /// Process a GameController key press event
    /// - Parameters:
    ///   - keyCode: The GameController key code that was pressed
    ///   - isShiftPressed: Whether shift key is currently pressed
    func processKeyPress(_ keyCode: GCKeyCode, isShiftPressed: Bool = false) {
        guard shouldRecogniseAsScanKeystroke(keyCode, isShiftPressed: isShiftPressed) else {
            return
        }

        guard let character = characterForKeyCode(keyCode, isShiftPressed: isShiftPressed) else {
            return
        }

        if configuration.terminatingStrings.contains(character) {
            processScan()
        } else {
            guard !excludedKeyCodes.contains(keyCode) else { return }
            checkForTimeoutBetweenKeystrokes()

            // Start timing on first character
            if buffer.isEmpty {
                scanStartTime = timeProvider.now()
            }

            buffer.append(character)
            scheduleTimeoutTimer()
        }
    }

    private func shouldRecogniseAsScanKeystroke(_ keyCode: GCKeyCode, isShiftPressed: Bool) -> Bool {
        guard let character = characterForKeyCode(keyCode, isShiftPressed: isShiftPressed), character.isNotEmpty else {
            // This prevents a double-trigger-pull on a Star scanner from adding an error row –
            // Star use this as a shortcut to switch to the software keyboard. They send keycode 174 0xAE, which is
            // undefined and reserved in UIKeyboardHIDUsage. The scanner doesn't send a character with the code.
            // There seems to be no reason to handle empty input when considering scans.
            return false
        }

        if buffer.isEmpty && configuration.terminatingStrings.contains(character) {
            // We prefer to show all partial scans, but if we just get an enter with no numbers, ignoring it makes testing easier
            return false
        }

        return true
    }

    private func checkForTimeoutBetweenKeystrokes() {
        // If characters are entered too slowly, it's probably typing and we should ignore the old input.
        // The key we just received is still considered for adding to the buffer – we may simply reset the buffer first.
        let currentTime = timeProvider.now()

        if let lastTime = lastKeyPressTime,
           currentTime.timeIntervalSince(lastTime) > configuration.maximumInterCharacterTime {
            let scanDurationMs = calculateScanDurationMs()
            let result = HIDBarcodeParserResult.failure(error: HIDBarcodeParserError.timedOut(barcode: buffer), scanDurationMs: scanDurationMs)

            onScan(result)
            resetScan()
        }

        lastKeyPressTime = currentTime
    }

    /// Convert GCKeyCode to ASCII character
    /// Maps GameController key codes to their corresponding ASCII characters
    /// - Parameters:
    ///   - keyCode: The GameController key code
    ///   - isShiftPressed: Whether shift key is pressed (affects letter case and symbols)
    private func characterForKeyCode(_ keyCode: GCKeyCode, isShiftPressed: Bool) -> String? {
        switch keyCode {
        // Numbers and their shifted symbols
        case .zero: return isShiftPressed ? ")" : "0"
        case .one: return isShiftPressed ? "!" : "1"
        case .two: return isShiftPressed ? "@" : "2"
        case .three: return isShiftPressed ? "#" : "3"
        case .four: return isShiftPressed ? "$" : "4"
        case .five: return isShiftPressed ? "%" : "5"
        case .six: return isShiftPressed ? "^" : "6"
        case .seven: return isShiftPressed ? "&" : "7"
        case .eight: return isShiftPressed ? "*" : "8"
        case .nine: return isShiftPressed ? "(" : "9"

        // Letters - lowercase without shift, uppercase with shift
        case .keyA: return isShiftPressed ? "A" : "a"
        case .keyB: return isShiftPressed ? "B" : "b"
        case .keyC: return isShiftPressed ? "C" : "c"
        case .keyD: return isShiftPressed ? "D" : "d"
        case .keyE: return isShiftPressed ? "E" : "e"
        case .keyF: return isShiftPressed ? "F" : "f"
        case .keyG: return isShiftPressed ? "G" : "g"
        case .keyH: return isShiftPressed ? "H" : "h"
        case .keyI: return isShiftPressed ? "I" : "i"
        case .keyJ: return isShiftPressed ? "J" : "j"
        case .keyK: return isShiftPressed ? "K" : "k"
        case .keyL: return isShiftPressed ? "L" : "l"
        case .keyM: return isShiftPressed ? "M" : "m"
        case .keyN: return isShiftPressed ? "N" : "n"
        case .keyO: return isShiftPressed ? "O" : "o"
        case .keyP: return isShiftPressed ? "P" : "p"
        case .keyQ: return isShiftPressed ? "Q" : "q"
        case .keyR: return isShiftPressed ? "R" : "r"
        case .keyS: return isShiftPressed ? "S" : "s"
        case .keyT: return isShiftPressed ? "T" : "t"
        case .keyU: return isShiftPressed ? "U" : "u"
        case .keyV: return isShiftPressed ? "V" : "v"
        case .keyW: return isShiftPressed ? "W" : "w"
        case .keyX: return isShiftPressed ? "X" : "x"
        case .keyY: return isShiftPressed ? "Y" : "y"
        case .keyZ: return isShiftPressed ? "Z" : "z"

        // Punctuation and symbols with shift variants
        case .spacebar: return " "
        case .hyphen: return isShiftPressed ? "_" : "-"
        case .equalSign: return isShiftPressed ? "+" : "="
        case .openBracket: return isShiftPressed ? "{" : "["
        case .closeBracket: return isShiftPressed ? "}" : "]"
        case .backslash: return isShiftPressed ? "|" : "\\"
        case .semicolon: return isShiftPressed ? ":" : ";"
        case .quote: return isShiftPressed ? "\"" : "'"
        case .comma: return isShiftPressed ? "<" : ","
        case .period: return isShiftPressed ? ">" : "."
        case .slash: return isShiftPressed ? "?" : "/"
        case .graveAccentAndTilde: return isShiftPressed ? "~" : "`"
        case .returnOrEnter: return "\r"
        case .tab: return "\t"
        default:
            return nil
        }
    }

    /// Key codes that should be excluded from barcode processing
    private let excludedKeyCodes: Set<GCKeyCode> = [
        .capsLock,
        .leftShift,
        .rightShift,
        .leftControl,
        .rightControl,
        .upArrow,
        .downArrow,
        .leftArrow,
        .rightArrow,
        .pageUp,
        .pageDown,
        .home,
        .end,
        .insert,
        .deleteForward,
        .deleteOrBackspace,
        .printScreen,
        .scrollLock,
        .pause,
        .escape
    ]

    /// Cancel the current scan and clear the buffer
    func cancel() {
        resetScan()
    }

    private func resetScan() {
        buffer = ""
        lastKeyPressTime = nil
        scanStartTime = nil
        cancelTimeoutTimer()
    }

    private func scheduleTimeoutTimer() {
        cancelTimeoutTimer()
        timeoutTimer = timeProvider.scheduleTimer(
            timeInterval: configuration.maximumInterCharacterTime,
            target: self,
            selector: #selector(handleTimeoutExpiry)
        )
    }

    private func cancelTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }

    @objc private func handleTimeoutExpiry() {
        guard !buffer.isEmpty else { return }

        let scanDurationMs = calculateScanDurationMs()
        let result = HIDBarcodeParserResult.failure(error: HIDBarcodeParserError.timedOut(barcode: buffer), scanDurationMs: scanDurationMs)

        onScan(result)
        resetScan()
    }

    private func calculateScanDurationMs() -> Int {
        guard let startTime = scanStartTime else { return 0 }
        return Int(round(timeProvider.now().timeIntervalSince(startTime) * 1000))
    }

    private func processScan() {
        cancelTimeoutTimer()
        checkForTimeoutBetweenKeystrokes()
        let scanDurationMs = calculateScanDurationMs()

        if buffer.count >= configuration.minimumBarcodeLength {
            let result = HIDBarcodeParserResult.success(barcode: buffer, scanDurationMs: scanDurationMs)
            onScan(result)
        } else {
            let result = HIDBarcodeParserResult.failure(error: HIDBarcodeParserError.scanTooShort(barcode: buffer), scanDurationMs: scanDurationMs)
            onScan(result)
        }
        resetScan()
    }
}

/// Configuration options for the HID barcode parser
struct HIDBarcodeParserConfiguration {
    /// Strings that indicate the end of a barcode scan
    let terminatingStrings: Set<String>

    /// Minimum length to consider scanned input complete
    let minimumBarcodeLength: Int

    /// Maximum time between scanned keystrokes
    /// After this time elapses, any further keystrokes result in the scan being rejected
    let maximumInterCharacterTime: TimeInterval

    /// Default configuration suitable for most barcode scanners
    static let `default` = HIDBarcodeParserConfiguration(
        terminatingStrings: ["\r", "\n"],
        minimumBarcodeLength: 6,
        maximumInterCharacterTime: 0.2
    )
}
