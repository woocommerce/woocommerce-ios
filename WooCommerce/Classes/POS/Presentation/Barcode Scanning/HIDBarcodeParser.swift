import Foundation
import UIKit

/// Protocol for creating timers, allowing injection of test timers
protocol TimerFactory {
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer
}

/// Default timer factory that creates real timers
struct DefaultTimerFactory: TimerFactory {
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer {
        Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: { _ in block() })
    }
}

/// Parses HID (Human Interface Device) keyboard input into barcode scans.
/// This class handles the core logic for interpreting keyboard input as barcode data,
/// particularly useful for physical barcode scanners that operate as keyboard input devices.
final class HIDBarcodeParser {
    /// Configuration for the barcode scanner
    let configuration: HIDBarcodeParserConfiguration
    /// Callback that is triggered when a barcode is successfully scanned
    let onScan: (String) -> Void

    private let timerFactory: TimerFactory

    private var buffer = ""
    private var lastKeyPressTime: Date?
    private var scanTimer: Timer?

    init(configuration: HIDBarcodeParserConfiguration,
         onScan: @escaping (String) -> Void,
         timerFactory: TimerFactory = DefaultTimerFactory()) {
        self.configuration = configuration
        self.onScan = onScan
        self.timerFactory = timerFactory
    }

    /// Process a key press event
    /// - Parameter key: The key that was pressed
    func processKeyPress(_ key: UIKey) {
        let currentTime = Date()

        // If characters are entered too slowly, it's probably typing and we should ignore it
        if let lastTime = lastKeyPressTime,
           currentTime.timeIntervalSince(lastTime) > configuration.maximumInterCharacterTime {
            resetScan()
        }

        // Start timing if this is the first key press
        if scanTimer == nil {
            startScanTimer()
        }
        lastKeyPressTime = currentTime

        let character = key.charactersIgnoringModifiers
        if configuration.terminatingStrings.contains(character) {
            processScan()
        } else {
            guard !excludedKeys.contains(key.keyCode) else { return }
            buffer.append(character)
        }
    }

    private let excludedKeys: [UIKeyboardHIDUsage] = [
        .keyboardCapsLock,
        .keyboardF1,
        .keyboardF2,
        .keyboardF3,
        .keyboardF4,
        .keyboardF5,
        .keyboardF6,
        .keyboardF7,
        .keyboardF8,
        .keyboardF9,
        .keyboardF10,
        .keyboardF11,
        .keyboardF12,
        .keyboardPrintScreen,
        .keyboardScrollLock,
        .keyboardPause,
        .keyboardInsert,
        .keyboardHome,
        .keyboardPageUp,
        .keyboardDeleteForward,
        .keyboardEnd,
        .keyboardPageDown,
        .keyboardRightArrow,
        .keyboardLeftArrow,
        .keyboardDownArrow,
        .keyboardUpArrow,
        .keypadNumLock,
        .keyboardApplication,
        .keyboardPower,
        .keypadEqualSign,
        .keyboardF13,
        .keyboardF14,
        .keyboardF15,
        .keyboardF16,
        .keyboardF17,
        .keyboardF18,
        .keyboardF19,
        .keyboardF20,
        .keyboardF21,
        .keyboardF22,
        .keyboardF23,
        .keyboardF24,
        .keyboardExecute,
        .keyboardHelp,
        .keyboardMenu,
        .keyboardSelect,
        .keyboardStop,
        .keyboardAgain,
        .keyboardUndo,
        .keyboardCut,
        .keyboardCopy,
        .keyboardPaste,
        .keyboardFind,
        .keyboardMute,
        .keyboardVolumeUp,
        .keyboardVolumeDown,
        .keyboardLockingCapsLock,
        .keyboardLockingNumLock,
        .keyboardLockingScrollLock,
        .keyboardAlternateErase,
        .keyboardSysReqOrAttention,
        .keyboardCancel,
        .keyboardClear,
        .keyboardPrior,
        .keyboardSeparator,
        .keyboardOut,
        .keyboardOper,
        .keyboardClearOrAgain,
        .keyboardCrSelOrProps,
        .keyboardExSel,
        .keyboardLeftControl,
        .keyboardLeftShift,
        .keyboardLeftAlt,
        .keyboardLeftGUI,
        .keyboardRightControl,
        .keyboardRightShift,
        .keyboardRightAlt,
        .keyboardRightGUI,
        .keyboard_Reserved
    ]

    /// Cancel the current scan and clear the buffer
    func cancel() {
        resetScan()
    }

    private func resetScan() {
        buffer = ""
        lastKeyPressTime = nil
        scanTimer?.invalidate()
        scanTimer = nil
    }

    private func startScanTimer() {
        scanTimer?.invalidate()
        scanTimer = timerFactory.createTimer(interval: configuration.maximumScanTime, repeats: false) { [weak self] in
            guard let self = self else { return }
            self.processScan()
        }
    }

    private func processScan() {
        if buffer.count >= configuration.minimumBarcodeLength {
            onScan(buffer)
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

    /// Maximum time to allow for scanned input.
    /// After this time elapses from the first "keystroke", the scan will be checked
    let maximumScanTime: TimeInterval

    /// Maximum time between scanned keystrokes
    /// After this time elapses, any further keystrokes result in the scan being rejected
    let maximumInterCharacterTime: TimeInterval

    /// Default configuration suitable for most barcode scanners
    static let `default` = HIDBarcodeParserConfiguration(
        terminatingStrings: ["\r", "\n"],
        minimumBarcodeLength: 4,
        maximumScanTime: 1.5,
        maximumInterCharacterTime: 0.1
    )
}
