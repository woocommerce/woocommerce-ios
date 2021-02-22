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

    init(readerSource: CardReaderSource) {
        print("==== reader")
        print(readerSource)
        print("//// reader")
        self.serial = readerSource.serialNumber
        self.vendorIdentifier = readerSource.stripeId
        self.name = readerSource.label

        let connected = readerSource.status == .online
        self.status = CardReaderStatus(connected: connected, remembered: false)

        self.softwareVersion = readerSource.deviceSoftwareVersion
        self.batteryLevel = readerSource.batteryLevel?.floatValue

        self.readerType = CardReaderType.with(readerType: readerSource.deviceType)
    }
}


protocol CardReaderSource {
    var serialNumber: String { get }
    var stripeId: String? { get }
    var label: String? { get }
    var status: ReaderNetworkStatus { get }
    var deviceSoftwareVersion: String? { get }
    var batteryLevel: NSNumber? { get }
    var deviceType: DeviceType { get }
}


extension Reader: CardReaderSource { }
