import StripeTerminal

extension CardReader {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.Reader
    init(reader: Reader) {
        print("==== reader")
        print(reader)
        print("//// reader")
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
