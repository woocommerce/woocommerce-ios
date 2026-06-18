import Foundation

/// A receipt printer discovered during Bluetooth discovery.
///
/// Hardware-domain value type that hides the underlying SDK's printer object,
/// so consumers can reference a discovered printer without importing the printer SDK.
public struct ReceiptPrinterDevice: Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
