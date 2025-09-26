import Foundation

public struct CardPresentPaymentCardReader: Equatable {
    let name: String

    /// The reader's battery level, if available.
    /// This is an unformatted percentage as a float, e.g. 0.0-1.0
    let batteryLevel: Float?

    public init(name: String, batteryLevel: Float?) {
        self.name = name
        self.batteryLevel = batteryLevel
    }
}
