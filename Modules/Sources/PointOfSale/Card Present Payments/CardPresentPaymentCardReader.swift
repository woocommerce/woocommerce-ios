import Foundation

public struct CardPresentPaymentCardReader: Equatable {
    let name: String

    /// The reader's battery level, if available.
    /// This is an unformatted percentage as a float, e.g. 0.0-1.0
    let batteryLevel: Float?

    /// The reader's software version, if available.
    let softwareVersion: String?

    public init(name: String, batteryLevel: Float?, softwareVersion: String? = "Unknown") {
        self.name = name
        self.batteryLevel = batteryLevel
        self.softwareVersion = softwareVersion
    }
}
