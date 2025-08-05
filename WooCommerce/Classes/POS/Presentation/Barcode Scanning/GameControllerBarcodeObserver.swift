import Foundation
import GameController
import UIKit

/// An observer that uses the `GameController` framework to monitor for connected barcode scanners/keyboards
/// and parse their input into barcode strings.
///
/// This class handles the low-level details of observing keyboard connections, processing raw `GCKeyCode` inputs,
/// and using the `GameControllerBarcodeParser` to produce a final barcode.
///
final class GameControllerBarcodeObserver {
    /// A closure that is called when a barcode scan is completed.
    /// The result will be a `success` with the barcode string or a `failure` with an HIDBarcodeParserError.
    let onScan: (Result<String, HIDBarcodeParserError>) -> Void

    /// Track the coalesced keyboard and its parser
    /// According to Apple's documentation, all connected keyboards are coalesced into one keyboard object
    /// (GCKeyboard.coalesced), so notification about connection/disconnection will only be delivered once
    /// until the last keyboard disconnects.
    private var coalescedKeyboard: GCKeyboard?
    private(set) var barcodeParser: GameControllerBarcodeParser?
    private let configuration: HIDBarcodeParserConfiguration

    /// Tracks current shift state to be applied to the next character key
    private var isShiftPressed: Bool = false

    /// Initializes a new barcode scanner observer.
    /// - Parameters:
    ///   - configuration: The configuration to use for the barcode parser. Defaults to the standard configuration.
    ///   - onScan: The closure to be called when a scan is completed.
    init(configuration: HIDBarcodeParserConfiguration = .default, onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void) {
        self.onScan = onScan
        self.configuration = configuration
        addObservers()
        setupCoalescedKeyboard()
    }

    deinit {
        removeObservers()
        cleanupKeyboard()
    }

    /// Starts observing for keyboard connection and disconnection events.
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidConnect),
            name: .GCKeyboardDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidDisconnect),
            name: .GCKeyboardDidDisconnect,
            object: nil
        )
    }

    /// Stops observing for keyboard events.
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidDisconnect, object: nil)
    }

    /// Sets up the coalesced keyboard if one is available at initialization.
    private func setupCoalescedKeyboard() {
        if let keyboard = GCKeyboard.coalesced {
            setupKeyboard(keyboard)
        }
    }

    /// Handles the connection of a keyboard (coalesced).
    @objc private func handleKeyboardDidConnect(_ notification: Notification) {
        guard let keyboard = notification.object as? GCKeyboard else {
            return
        }
        setupKeyboard(keyboard)
    }

    /// Handles the disconnection of the keyboard (coalesced).
    @objc private func handleKeyboardDidDisconnect(_ notification: Notification) {
        cleanupKeyboard()
    }

    /// Sets up the coalesced keyboard to handle key press events.
    /// - Parameter keyboard: The coalesced `GCKeyboard` to set up.
    private func setupKeyboard(_ keyboard: GCKeyboard) {
        // Clean up any existing setup first
        cleanupKeyboard()

        coalescedKeyboard = keyboard
        barcodeParser = GameControllerBarcodeParser(
            configuration: configuration,
            onScan: { [weak self] result in
                self?.handleScanResult(result)
            }
        )

        keyboard.keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
            guard let self = self else { return }

            if keyCode == .leftShift || keyCode == .rightShift {
                self.isShiftPressed = pressed
                return
            }

            guard pressed else { return }

            self.barcodeParser?.processKeyPress(keyCode, isShiftPressed: isShiftPressed)
        }
    }

    /// Cleans up the coalesced keyboard and its parser.
    private func cleanupKeyboard() {
        coalescedKeyboard?.keyboardInput?.keyChangedHandler = nil
        barcodeParser?.cancel()
        coalescedKeyboard = nil
        barcodeParser = nil
        isShiftPressed = false
    }

    private func handleScanResult(_ result: HIDBarcodeParserResult) {
        trackAnalyticsEvent(for: result)
        onScan(result.asResult)
    }

    private func trackAnalyticsEvent(for result: HIDBarcodeParserResult) {
        switch result {
        case .success(let barcode, let scanDurationMs):
            ServiceLocator.analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningSuccess(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: barcode.count
                )
            )
        case .failure(let error, let scanDurationMs):
            ServiceLocator.analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningFailed(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: error.barcode.count,
                    failReason: error.analyticsReason
                )
            )
        }
    }

    // MARK: - VoiceOver Support

    /// Barcode scanner input is not received through GameController framework keyChangeHandler if VoiceOver is enabled.
    /// Process UIPress events as fallback when VoiceOver is enabled.
    /// Translates UIKey input to GCKeyCode and feeds to existing parser infrastructure.
    /// As a limitation, this won't always work as expected when iOS Software Keyboard is not in US-English.
    ///
    func processUIPress(_ presses: Set<UIPress>) {
        // Lazily initialize parser for VoiceOver fallback if needed
        if barcodeParser == nil {
            barcodeParser = GameControllerBarcodeParser(
                configuration: configuration,
                onScan: { [weak self] result in
                    self?.handleScanResult(result)
                }
            )
        }

        for press in presses {
            guard let key = press.key else { continue }

            // Translate UIKey to GCKeyCode
            guard let keyCode = uiKeyToGCKeyCode(key) else { continue }

            // Determine shift state from modifiers
            let isShiftPressed = key.modifierFlags.contains(.shift)

            // Use existing parser with translated input
            barcodeParser?.processKeyPress(keyCode, isShiftPressed: isShiftPressed)
        }
    }

    /// Translates UIKey to equivalent GCKeyCode for consistent parsing
    func uiKeyToGCKeyCode(_ key: UIKey) -> GCKeyCode? {
        switch key.keyCode {
        // Numbers
        case .keyboard0: return .zero
        case .keyboard1: return .one
        case .keyboard2: return .two
        case .keyboard3: return .three
        case .keyboard4: return .four
        case .keyboard5: return .five
        case .keyboard6: return .six
        case .keyboard7: return .seven
        case .keyboard8: return .eight
        case .keyboard9: return .nine

        // Letters
        case .keyboardA: return .keyA
        case .keyboardB: return .keyB
        case .keyboardC: return .keyC
        case .keyboardD: return .keyD
        case .keyboardE: return .keyE
        case .keyboardF: return .keyF
        case .keyboardG: return .keyG
        case .keyboardH: return .keyH
        case .keyboardI: return .keyI
        case .keyboardJ: return .keyJ
        case .keyboardK: return .keyK
        case .keyboardL: return .keyL
        case .keyboardM: return .keyM
        case .keyboardN: return .keyN
        case .keyboardO: return .keyO
        case .keyboardP: return .keyP
        case .keyboardQ: return .keyQ
        case .keyboardR: return .keyR
        case .keyboardS: return .keyS
        case .keyboardT: return .keyT
        case .keyboardU: return .keyU
        case .keyboardV: return .keyV
        case .keyboardW: return .keyW
        case .keyboardX: return .keyX
        case .keyboardY: return .keyY
        case .keyboardZ: return .keyZ

        // Punctuation and symbols
        case .keyboardSpacebar: return .spacebar
        case .keyboardHyphen: return .hyphen
        case .keyboardEqualSign: return .equalSign
        case .keyboardOpenBracket: return .openBracket
        case .keyboardCloseBracket: return .closeBracket
        case .keyboardBackslash: return .backslash
        case .keyboardSemicolon: return .semicolon
        case .keyboardQuote: return .quote
        case .keyboardComma: return .comma
        case .keyboardPeriod: return .period
        case .keyboardSlash: return .slash
        case .keyboardGraveAccentAndTilde: return .graveAccentAndTilde
        case .keyboardReturnOrEnter: return .returnOrEnter
        case .keyboardTab: return .tab

        default:
            return nil
        }
    }
}
