// periphery:ignore:all - will be used for booking filters
import Foundation

/// Used to filter bookings by product
///
public struct FilterBookingsByProduct: Codable, Hashable {
    /// ID of the product
    ///
    public let id: Int64

    /// Name of the product
    ///
    public let name: String

    public init(id: Int64,
         name: String) {
        self.id = id
        self.name = name
    }
}
