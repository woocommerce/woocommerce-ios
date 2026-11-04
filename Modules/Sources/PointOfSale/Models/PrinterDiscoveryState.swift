import struct Yosemite.PrinterDevice

/// The state of an in-progress printer discovery, for presentation.
///
/// Mirrors the card-reader connection flow: a single discovered printer is confirmed in a modal
/// (`foundOne`), while two or more are chosen from a list (`foundMultiple`).
public enum PrinterDiscoveryState: Hashable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case idle
    case searching
    case noPrintersFound
    case foundOne(PrinterDevice)
    case foundMultiple([PrinterDevice])
    case connecting(PrinterDevice)
    /// The Bluetooth radio is off, so the search waits for the merchant to turn it on.
    case bluetoothOff
    case error
}
