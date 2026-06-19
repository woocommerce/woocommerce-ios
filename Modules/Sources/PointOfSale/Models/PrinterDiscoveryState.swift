import struct Yosemite.PrinterDevice

/// The state of an in-progress printer discovery, for presentation.
public enum PrinterDiscoveryState: Hashable, Identifiable, Sendable {
    public var id: Self {
        self
    }

    case idle
    case searching
    case found([PrinterDevice])
    case error
}
