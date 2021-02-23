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

        self.stripeReader = reader
    }
}


/// The initializers of StripeTerminal.Reader are annotated as NS_UNAVAILABLE
/// So we can not create instances of that class in our tests.
/// A workaround is declaring this protocol, which matches the parts of
/// SCPReader that we are interested in, make Reader implement it,
/// and initialize Harware.CardReader with a type conforming to it.
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


/**
 An alternative solution could be:

 public struct CardReader {
    private let stripeReader: StripeCardReader

     /// The CardReader serial number
     public var serial: String {
        stripeReader.serialNumber
    }

     /// The CardReader vendor identifier
     public var vendorIdentifier: String? {
        stripeReader.stripeId
    }

     /// A readable name. It could be nil
     public var  name: String? { stripeReader.label }

     /// The Hardware status.
     public var status: CardReaderStatus {
        let connected = reader.status == .online
        return CardReaderStatus(connected: connected, remembered: false)
    }

     /// The reader's sofware version, if available
     public var softwareVersion: String? { stripeReader.deviceSoftwareVersion }

     /// The reader's battery level, if available.
     /// For Stripe Card Readers, it would be a number between 0 and 1
     public var  batteryLevel: Float? { you get the point }

     /// The type of card reader
     public var readerType: CardReaderType { I won't repeat this either }
 }

 extension CardReader {

     /// Convenience initializer
     /// - Parameter reader: An instance of a StripeTerminal.Reader
     init(reader: StripeCardReader) {
         self.stripeReader = reader
     }
 }
 */
