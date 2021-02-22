import StripeTerminal

extension CardReader {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.Reader
    init(reader: StripeCardReader) {
        self.serial = reader.serialNumber
        self.vendorIdentifier = reader.stripeId
        self.name = reader.label

        let connected = reader.status == .online
        self.status = CardReaderStatus(connected: connected, remembered: false)

        self.softwareVersion = reader.deviceSoftwareVersion
        self.batteryLevel = reader.batteryLevel?.floatValue

        self.readerType = CardReaderType.with(readerType: reader.deviceType)
    }
}


protocol StripeCardReader {
    var serialNumber: String { get }
    var stripeId: String? { get }
    var label: String? { get }
    var status: ReaderNetworkStatus { get }
    var deviceSoftwareVersion: String? { get }
    var batteryLevel: NSNumber? { get }
    var deviceType: DeviceType { get }
}


extension Reader: StripeCardReader { }
