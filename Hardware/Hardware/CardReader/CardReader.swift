/// Models a Card Reader. This is the public struct that clients of
/// Hardware are expected to consume.
public struct CardReader {
    public let serial: String
    public let vendorIdentifier: String?
    public let name: String?
    public let status: CardReaderStatus
    public let softwareVersion: String?
    public let batteryLevel: Float?
    public let readerType: CardReaderType
}


extension CardReader: Equatable {
    public static func ==(lhs: CardReader, rhs: CardReader) -> Bool {
        lhs.serial == rhs.serial
    }
}
