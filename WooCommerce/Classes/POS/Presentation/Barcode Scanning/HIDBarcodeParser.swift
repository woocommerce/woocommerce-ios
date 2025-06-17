import Foundation

/// Parses HID (Human Interface Device) keyboard input into barcode scans.
/// This class handles the core logic for interpreting keyboard input as barcode data,
/// particularly useful for physical barcode scanners that operate as keyboard input devices.
final class HIDBarcodeParser {
    /// Configuration for the barcode scanner
    let configuration: HIDBarcodeParserConfiguration
    /// Callback that is triggered when a barcode is successfully scanned
    let onScan: (String) -> Void

    private var buffer = ""
    private var lastKeyPressTime: Date?
    private var scanTimer: Timer?

    init(configuration: HIDBarcodeParserConfiguration, onScan: @escaping (String) -> Void) {
        self.configuration = configuration
        self.onScan = onScan
    }

    /// Process a key press event
    /// - Parameter key: The key that was pressed
    func processKeyPress(_ key: String) {
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

        if configuration.terminatingStrings.contains(key) {
            processScan()
        } else {
            buffer.append(key)
        }
    }

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
        scanTimer = Timer.scheduledTimer(withTimeInterval: configuration.maximumScanTime, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            processScan()
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
