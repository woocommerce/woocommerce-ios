import Foundation

/// Card reader type. Indicates if a reader is meant to be used
/// handheld or as a countertop device
public enum CardReaderType: String, Codable {
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
