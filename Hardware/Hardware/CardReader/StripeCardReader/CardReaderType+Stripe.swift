import StripeTerminal

extension CardReaderType {

    /// Factory Method to initialize CardReaderType with StripeTerminal's DeviceType
    /// - Parameter readerType: an instance of DeviceType, declared in StripeTerminal
    static func with(readerType: DeviceType) -> CardReaderType {
        switch readerType {
        case .chipper2X:
            return .mobile
        case .verifoneP400:
            return .counterTop
        default:
            return .notSupported
        }
    }
}
