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
    /// The search itself failed, for example because Bluetooth is off.
    case discoveryFailed
    /// Connecting to the chosen printer failed.
    case error
}
