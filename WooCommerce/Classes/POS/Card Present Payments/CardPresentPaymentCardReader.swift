import Foundation

struct CardPresentPaymentCardReader {
    let name: String

    /// The reader's battery level, if available.
    /// This is an unformatted percentage as a float, e.g. 0.0-1.0
    let batteryLevel: Float?
}
