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
        case .wisePad3:
            return .wisepad3
        case .appleBuiltIn:
            return appleBuiltIn
        default:
            return .other
        }
    }

    func toStripe() -> DeviceType? {
        switch self {
        case .chipper:
            return .chipper2X
        case .stripeM2:
            return .stripeM2
        case .wisepad3:
            return .wisePad3
        case .appleBuiltIn:
            return .appleBuiltIn
        case .other:
            return nil
        }
    }
}
#endif
