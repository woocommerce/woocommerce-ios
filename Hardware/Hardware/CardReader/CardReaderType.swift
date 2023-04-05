/// Card reader type. Indicates if a reader is meant to be used
/// handheld or as a countertop device
public enum CardReaderType: String, CaseIterable {
    /// Chipper
    case chipper
    /// Stripe M2
    case stripeM2
    /// BBPOS WisePad 3
    case wisepad3
    /// Tap on Mobile: Apple built in reader
    case appleBuiltIn
    /// Other
    case other
}

extension CardReaderType {
    /// A human-readable model name for the reader.
    ///
    public var model: String {
        /// This should match the Android SDK deviceName, to simplify Analytics use
        /// https://stripe.dev/stripe-terminal-android/external/external/com.stripe.stripeterminal.external.models/-device-type/index.html
        /// pbUcTB-r9-p2#comment-2164
        ///
        switch self {
        case .chipper:
            return "CHIPPER_2X"
        case .stripeM2:
            return "STRIPE_M2"
        case .wisepad3:
            return "WISEPAD_3"
        case .appleBuiltIn:
            return "COTS_DEVICE"
        default:
            return "UNKNOWN"
        }
    }
}
