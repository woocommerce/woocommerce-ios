#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension CardReaderType {

    /// Factory Method to initialize CardReaderType with StripeTerminal's DeviceType
    /// - Parameter readerType: an instance of DeviceType, declared in StripeTerminal
    static func with(readerType: DeviceType) -> CardReaderType {
        switch readerType {
        case .chipper2X:
            return .chipper
        case .stripeM2:
            return .stripeM2
        default:
            return .other
        }
    }
}
#endif
