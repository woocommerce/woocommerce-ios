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

    init(configuration: HIDBarcodeParserConfiguration, onScan: @escaping (String) -> Void) {
        self.configuration = configuration
        self.onScan = onScan
    }

    /// Process a key press event
    /// - Parameter key: The key that was pressed
    func processKeyPress(_ key: String) {
        if configuration.terminatingStrings.contains(key) {
            onScan(buffer)
            buffer = ""
        } else {
            buffer.append(key)
        }
    }

    /// Cancel the current scan and clear the buffer
    func cancel() {
        buffer = ""
    }
}

/// Configuration options for the HID barcode parser
struct HIDBarcodeParserConfiguration {
    /// Strings that indicate the end of a barcode scan
    let terminatingStrings: Set<String>

    /// Default configuration suitable for most barcode scanners
    static let `default` = HIDBarcodeParserConfiguration(
        terminatingStrings: ["\r", "\n"]
    )
}
