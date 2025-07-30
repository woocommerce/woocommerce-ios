import Foundation
import GameController

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
    private var barcodeParser: GameControllerBarcodeParser?
    private let configuration: HIDBarcodeParserConfiguration
    private let analytics: POSAnalyticsProviding

    /// Tracks current shift state to be applied to the next character key
    private var isShiftPressed: Bool = false

    /// Initializes a new barcode scanner observer.
    /// - Parameters:
    ///   - configuration: The configuration to use for the barcode parser. Defaults to the standard configuration.
    ///   - analytics: The analytics service for tracking events.
    ///   - onScan: The closure to be called when a scan is completed.
    init(configuration: HIDBarcodeParserConfiguration = .default,
         analytics: POSAnalyticsProviding,
         onScan: @escaping (Result<String, HIDBarcodeParserError>) -> Void) {
        self.onScan = onScan
        self.analytics = analytics
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
            analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningSuccess(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: barcode.count
                )
            )
        case .failure(let error, let scanDurationMs):
            analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningFailed(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: error.barcode.count,
                    failReason: error.analyticsReason
                )
            )
        }
    }
}
