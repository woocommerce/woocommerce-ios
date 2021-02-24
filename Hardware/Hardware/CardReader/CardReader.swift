/// Models a Card Reader. This is the public struct that clients of
/// Hardware are expected to consume.
public struct CardReader {

    /// The CardReader serial number
    public let serial: String

    /// The CardReader vendor identifier
    public let vendorIdentifier: String?

    /// A readable name. It could be nil
    public let name: String?

    /// The Hardware status.
    public let status: CardReaderStatus

    /// The reader's sofware version, if available
    public let softwareVersion: String?

    /// The reader's battery level, if available.
    /// For Stripe Card Readers, it would be a number between 0 and 1
    public let batteryLevel: Float?

    /// The type of card reader
    public let readerType: CardReaderType
}


extension CardReader: Identifiable {

    /// Defaults to return the reader serial number.
    /// From a domain point of view, it makes sense to
    /// differentiate serial number from identifier.
    public var id: String {
        serial
    }
}
