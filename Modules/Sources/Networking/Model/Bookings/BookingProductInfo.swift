import Foundation

public struct BookingProductInfo: Hashable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }
}
