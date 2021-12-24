/// Models the status of a Card Reader
public struct CardReaderStatus {
    /// Indicates if the CardReader is connected
    public let connected: Bool

    // Indicates if the CardReader is remembered by the service
    public let remembered: Bool
}
