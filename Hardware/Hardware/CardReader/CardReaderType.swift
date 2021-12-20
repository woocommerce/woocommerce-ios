/// Card reader type. Indicates if a reader is meant to be used
/// handheld or as a countertop device
public enum CardReaderType {
    /// Chipper
    case chipper
    /// Stripe M2
    case stripeM2
    /// Other
    case other
}

extension CardReaderType {
    var model: String {
        switch self {
        case .chipper:
            return "chipper_2x"
        case .stripeM2:
            return "stripe_m2"
        default:
            return "other"
        }
    }
}
